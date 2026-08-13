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
        Text("SideBell")
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
                Text("I understand the notice above")
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("I understand the notice above"))
        .accessibilityHint(Text("You must confirm before choosing a role"))
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    var roleButtons: some View {
        VStack(spacing: 16) {
            // 字面值包在 `String(localized:)` 內，不直接當參數傳：編譯器只從
            // `Text()` 與 `String(localized:)` 擷取字串，寫成 `title: "Patient"`
            // 的話這兩句永遠不會進入 String Catalog。
            roleButton(
                role: .patient,
                title: String(localized: "Patient"),
                subtitle: String(localized: "Set up beside the patient to send calls"),
                systemImage: "bed.double"
            )
            roleButton(
                role: .caregiver,
                title: String(localized: "Caregiver"),
                subtitle: String(localized: "Carry with you to receive calls"),
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
        .accessibilityLabel(String(localized: "\(title), \(subtitle)"))
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

    /// 以計算屬性而非 `static let` 取得：後者只在首次存取時求值一次，
    /// 之後即使語言改變也不會重算。
    ///
    /// 英文版刻意不寫出特定號碼。「119」是台灣的緊急電話，對其他國家的
    /// 使用者是錯的資訊，而這段文字的用途正是在緊急時導引他求助。
    /// 繁中翻譯保留 119。
    static var disclaimerText: String {
        String(localized: """
            SideBell is a care assistance calling tool. It cannot replace emergency \
            medical alert services. In an emergency, call your local emergency number. \
            It works over Bluetooth, so its range is limited; it cannot send calls when \
            the app is closed or the device runs out of battery.
            """)
    }

    /// 專供 VoiceOver 朗讀的版本。
    ///
    /// 繁中版與顯示文字的差別只有一處：「119」寫成「一一九」。實測發現朗讀
    /// 「119」會被當成數值唸出（英文語音下是 one hundred nineteen），
    /// 而那是緊急電話號碼——唸錯會讓視障使用者撥錯號碼。這不是體驗問題，
    /// 是安全問題。
    ///
    /// 英文版沒有數字，因此與顯示文字只差開頭的提示語；這一條仍獨立存在，
    /// 是為了讓繁中翻譯有地方安放那個差異。
    static var disclaimerSpokenText: String {
        String(localized: """
            Important notice. SideBell is a care assistance calling tool. It cannot \
            replace emergency medical alert services. In an emergency, call your local \
            emergency number. It works over Bluetooth, so its range is limited; it \
            cannot send calls when the app is closed or the device runs out of battery.
            """)
    }

    static func message(for reason: RoleSelectionViewModel.BlockReason) -> String {
        switch reason {
        case .disclaimerNotAcknowledged:
            String(localized: "Please confirm the notice above before choosing a role.")
        case .bluetooth(.poweredOff):
            String(localized: "Bluetooth is off. SideBell needs Bluetooth to connect. Please turn it on to continue.")
        case .bluetooth(.unauthorized):
            String(localized: "SideBell is not allowed to use Bluetooth. Open Settings > SideBell to grant permission.")
        case .bluetooth(.unsupported):
            String(localized: "This device does not support Bluetooth Low Energy, so SideBell cannot be used.")
        }
    }

    /// 停用時朗讀原因——只說「已停用」等於要視障使用者自己猜。
    func accessibilityHint(for title: String) -> String {
        guard let reason = viewModel.state.blockReason else {
            return String(localized: "Opens the \(title) screen")
        }
        return String(localized: "Not available right now. \(Self.message(for: reason))")
    }
}
