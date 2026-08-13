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
                    Text(plan.displayPrice)
                        .font(.headline)
                    Text(plan.product.purpose)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                if viewModel.state.purchasingProduct == plan.product {
                    ProgressView()
                }
            }
        }
        // 購買進行中時停用全部方案：連點兩下會送出兩筆交易，而使用者以為
        // 自己只按了一次。這不是在擋重複購買——那是允許的，只是必須是他
        // 刻意再按一次。
        .disabled(viewModel.state.isPurchasing)
        .accessibilityLabel(String(localized: "\(plan.displayPrice), \(plan.product.purpose)"))
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
