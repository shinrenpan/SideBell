import SwiftUI

/// 支持開發者。只從照顧者端的設定進得來。
struct SponsorshipView: View {
    @Bindable var viewModel: SponsorshipViewModel

    var body: some View {
        List {
            Section {
                intro
            }

            if viewModel.state.needsNetwork {
                Section { networkNotice }
            } else if viewModel.state.isLoading {
                Section { loadingRow }
            } else {
                Section {
                    ForEach(viewModel.state.plans) { plan in
                        planRow(plan)
                    }
                } footer: {
                    Text("These are one-time contributions. You can support again whenever you like.")
                }
            }

            if let message = viewModel.state.purchaseFailureMessage {
                Section { failureNotice(message) }
            }
        }
        .navigationTitle("Support the developer")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.doAction(.onAppear)
        }
    }
}

// MARK: - 區塊

private extension SponsorshipView {
    /// 開宗明義說清楚「買了不會多出任何東西」。
    ///
    /// 這不是謙辭，是這個 App 的結構事實：程式裡沒有任何依購買狀態決定
    /// 功能可用性的判斷。文案必須與結構一致，否則使用者會期待付費解鎖，
    /// 而那個期待永遠不會被滿足。
    var intro: some View {
        VStack(alignment: .leading, spacing: 8) {
            if viewModel.state.hasSupported {
                Label("Thank you for your support", systemImage: "heart.fill")
                    .font(.headline)
                    .foregroundStyle(.pink)
            }
            Text("SideBell is free, and supporting it unlocks nothing. Every feature works the same either way.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    func planRow(_ plan: SponsorshipPlan) -> some View {
        Button {
            Task { await viewModel.doAction(.purchase(plan.product)) }
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    // 說明可能是空的（該商品在 App Store Connect 漏填）。
                    // 空字串會撐出一行看不見的間距，讀起來像版面壞了。
                    if !plan.detail.isEmpty {
                        Text(plan.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer()
                // 藍色**只給價格**。List 裡的 Button 預設會把整個 label 染成
                // 主題色，標題與說明跟著變藍，主次就分不出來了——而深色背景上
                // 的淡藍比灰色更難讀，對年長的照顧者尤其吃虧。因此下面改用
                // `.plain`，顏色全部自己指定，藍色留給唯一的行動點：金額。
                Text(plan.displayPrice)
                    .font(.headline)
                    .foregroundStyle(.tint)
                if viewModel.state.purchasingProduct == plan.product {
                    ProgressView()
                }
            }
            // 整列可點，不只文字。少了它，兩段文字之間的空白按不動。
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        // 購買進行中時停用全部方案：連點兩下會送出兩筆交易，而使用者以為
        // 自己只按了一次。這不是在擋重複購買——那是允許的，只是必須是他
        // 刻意再按一次。
        .disabled(viewModel.state.isPurchasing)
        // 三段全部來自 App Store，本身已經在地化，**不再包一層 String(localized:)**
        // ——那會把商店回傳的文字當成待翻譯的 key。順序照畫面上的閱讀順序。
        .accessibilityLabel(
            [plan.title, plan.detail, plan.displayPrice]
                .filter { !$0.isEmpty }
                .joined(separator: ", ")
        )
    }

    var loadingRow: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text("Loading…")
                .foregroundStyle(.secondary)
        }
    }

    /// 無網路時**說清楚並給重試**，不假裝正在載入、也不顯示空白。
    var networkNotice: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("This screen needs a network connection", systemImage: "wifi.slash")
                .font(.headline)
            Text("Prices come from the App Store, so this is the only screen that needs to go online. Calls and alerts keep working without it.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Try again") {
                Task { await viewModel.doAction(.retry) }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 4)
    }

    func failureNotice(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline)
            Spacer()
            Button {
                Task { await viewModel.doAction(.dismissFailure) }
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Dismiss"))
        }
    }
}

// MARK: - Preview

// Preview 依賴 `#if DEBUG` 裡的 mock，因此自己也必須包起來——
// 否則 Release build（archive／送審）會找不到 mock 而編譯失敗。
#if DEBUG
#Preview("三個方案") {
    NavigationStack {
        SponsorshipView(viewModel: .mock)
    }
}

#Preview("需要網路") {
    NavigationStack {
        SponsorshipView(viewModel: .offlineMock)
    }
}
#endif
