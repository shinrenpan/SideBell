import SwiftUI

/// 首頁。朗讀順序刻意等同視覺順序：免責聲明 → 確認 → 患者端 → 照顧者端。
struct RoleSelectionView: View {
    @Bindable var viewModel: RoleSelectionViewModel

    var body: some View {
        VStack(spacing: 0) {
            // 說明區可捲動：小螢幕 + 放大字級 + 較長的語言（德文、越南文可能
            // 比中文長三到五成）三者疊加時，固定版面會把內容直接切掉，
            // 而被切掉的部分使用者永遠看不到。
            ScrollView {
                VStack(spacing: 24) {
                    header
                    disclaimer

                    // 確認控制項刻意放在聲明**下方的捲動區內**：使用者為了
                    // 啟用角色按鈕必須捲到這裡，因而必然捲過整段聲明。
                    // 這比把全部內容硬塞進一個畫面更能保證他真的看過。
                    if !viewModel.state.isDisclaimerAcknowledged {
                        acknowledgeControl
                    }

                    if let reason = viewModel.state.blockReason {
                        blockNotice(reason)
                    }
                }
                .padding(24)
                .frame(maxWidth: Self.contentMaxWidth)
                .frame(maxWidth: .infinity)
            }

            // 角色按鈕釘在底部：不論說明多長，它們永遠在拇指可及之處。
            roleButtons
                .padding(24)
                .frame(maxWidth: Self.contentMaxWidth)
                .frame(maxWidth: .infinity)
                .background(.bar)
        }
        .task {
            await viewModel.doAction(.onAppear)
        }
    }
}

// MARK: - 區塊

private extension RoleSelectionView {
    var header: some View {
        Text("SideBell 隨身鈴")
            .font(.largeTitle.bold())
            .accessibilityAddTraits(.isHeader)
    }

    /// spec 9.3：免責聲明須於首次啟動明示，且此處選擇常駐呈現——
    /// 照顧者換人、或隔數月再打開，訊息都還在。
    var disclaimer: some View {
        Text(Self.disclaimerText)
            .font(.callout)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(Self.disclaimerSpokenText)
    }

    var acknowledgeControl: some View {
        Button {
            Task { await viewModel.doAction(.acknowledgeDisclaimer) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "square")
                Text("我已了解上述說明")
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("我已了解上述說明")
        .accessibilityHint("確認後才能選擇角色")
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    var roleButtons: some View {
        VStack(spacing: 16) {
            roleButton(
                role: .patient,
                title: "患者端",
                subtitle: "架設在患者身邊，用來發出呼叫",
                systemImage: "bed.double"
            )
            roleButton(
                role: .caregiver,
                title: "照顧者端",
                subtitle: "隨身攜帶，接收患者的呼叫",
                systemImage: "figure.wave"
            )
        }
    }

    func roleButton(
        role: AppRole,
        title: String,
        subtitle: String,
        systemImage: String
    ) -> some View {
        Button {
            Task { await viewModel.doAction(.selectRole(role)) }
        } label: {
            HStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.title)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title2.bold())
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 88)
            .background(.tint.opacity(0.12), in: .rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.state.isRoleSelectionEnabled)
        .accessibilityLabel("\(title)，\(subtitle)")
        .accessibilityHint(accessibilityHint(for: title))
    }

    func blockNotice(_ reason: RoleSelectionViewModel.BlockReason) -> some View {
        Label(Self.message(for: reason), systemImage: "exclamationmark.triangle.fill")
            .font(.callout)
            .foregroundStyle(.orange)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 私有

private extension RoleSelectionView {
    /// iPad 上不讓文字撐滿整個螢幕寬度——一行太長會難以閱讀。
    static let contentMaxWidth: CGFloat = 560

    static let disclaimerText = """
        SideBell 是照護輔助呼叫工具，不能取代緊急醫療警報服務。\
        遇到緊急狀況請撥打 119 或當地緊急電話。\
        本 App 透過藍牙運作，距離有限；App 被關閉或裝置沒電時無法傳送呼叫。
        """

    /// 專供 VoiceOver 朗讀的版本。
    ///
    /// 與顯示文字的差別只有一處：「119」寫成「一一九」。實測發現朗讀
    /// 「119」會被當成數值唸出（英文語音下是 one hundred nineteen），
    /// 而那是緊急電話號碼——唸錯會讓視障使用者撥錯號碼。這不是體驗問題，
    /// 是安全問題。
    static let disclaimerSpokenText = """
        重要說明。SideBell 是照護輔助呼叫工具，不能取代緊急醫療警報服務。\
        遇到緊急狀況請撥打一一九，或當地緊急電話。\
        本 App 透過藍牙運作，距離有限；App 被關閉或裝置沒電時無法傳送呼叫。
        """

    static func message(for reason: RoleSelectionViewModel.BlockReason) -> String {
        switch reason {
        case .disclaimerNotAcknowledged:
            "請先確認上方說明，才能選擇角色。"
        case .bluetooth(.poweredOff):
            "藍牙已關閉。SideBell 需要藍牙才能連線，請開啟後再繼續。"
        case .bluetooth(.unauthorized):
            "尚未允許 SideBell 使用藍牙。請到「設定 > SideBell」開啟藍牙權限。"
        case .bluetooth(.unsupported):
            "此裝置不支援藍牙低功耗，無法使用 SideBell。"
        }
    }

    /// 停用時朗讀原因——只說「已停用」等於要視障使用者自己猜。
    func accessibilityHint(for title: String) -> String {
        guard let reason = viewModel.state.blockReason else {
            return "開啟\(title)畫面"
        }
        return "目前無法選擇。\(Self.message(for: reason))"
    }
}
