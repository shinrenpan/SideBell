import SwiftUI

/// 照顧者端的呼叫清單。
struct CaregiverCallsView: View {
    @Bindable var viewModel: CaregiverCallsViewModel

    var body: some View {
        VStack(spacing: 0) {
            connectionIndicator
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

            if let failure = viewModel.state.acknowledgeFailure {
                failureBanner(failure)
            }

            if viewModel.state.hasCalls {
                callList
            } else {
                emptyState
            }
        }
        .navigationTitle("Calls")
        .task {
            await viewModel.doAction(.onAppear)
        }
        .onDisappear {
            Task { await viewModel.doAction(.onDisappear) }
        }
    }
}

// MARK: - 清單

private extension CaregiverCallsView {
    var callList: some View {
        List(viewModel.state.calls) { call in
            row(call)
        }
        .listStyle(.plain)
    }

    func row(_ call: CaregiverCallsViewModel.CallRow) -> some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    if call.isUrgent {
                        // 緊急以符號標示而非只靠顏色——照顧者可能在昏暗的
                        // 房間裡瞄一眼就要判斷輕重。
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                    Text(call.title)
                        .font(.title3.bold())
                }
                timestamp(call)
                Text(call.peerName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            acknowledgeControl(call)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }

    /// 時間的呈現方式依這一列還等不等得到回應而不同。
    ///
    /// 還在等的呼叫顯示**相對時間**：照顧者要知道的是「他等了多久」，而不是
    /// 「幾點按的」——後者要他自己心算，而三分鐘的時限正在跑。已經結束的
    /// 呼叫（已確認或已逾時）改回絕對時間，那時緊迫感沒有意義了。
    ///
    /// 刻意不顯示秒：wire format 只保留整秒，次秒精度不保證存活，顯示出來
    /// 會給人一種比實際更精確的錯覺。
    @ViewBuilder
    func timestamp(_ call: CaregiverCallsViewModel.CallRow) -> some View {
        if call.isActionable {
            Text(call.pressedAt, style: .relative)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityLabel(Text("Waiting"))
        } else {
            Text(call.pressedAt, style: .time)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    func acknowledgeControl(_ call: CaregiverCallsViewModel.CallRow) -> some View {
        if call.isAcknowledged {
            Label("Got it", systemImage: "checkmark.circle.fill")
                .labelStyle(.titleAndIcon)
                .font(.subheadline.bold())
                .foregroundStyle(.green)
                .accessibilityLabel(Text("Acknowledgement sent"))
        } else if call.isExpired {
            // 逾時後的確認送得出去，但患者端那格早已走完生命週期、顯示著
            // 「無人回應」，不會有任何變化。留著可按的按鈕，等於讓照顧者
            // 按完之後以為患者知道有人要來了。
            Label("No response", systemImage: "xmark.circle.fill")
                .labelStyle(.titleAndIcon)
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
                .accessibilityLabel(Text("More than three minutes have passed; the patient already sees no response"))
        } else {
            Button("Got it") {
                Task { await viewModel.doAction(.acknowledge(call.id)) }
            }
            .buttonStyle(.borderedProminent)
            .accessibilityHint(Text("Sends an acknowledgement so the patient knows someone responded"))
        }
    }
}

// MARK: - 狀態呈現

private extension CaregiverCallsView {
    /// 確認送不出去時的橫幅。
    ///
    /// 刻意不用 alert：alert 會擋住整個清單，而照顧者此時最需要看到的正是
    /// 「哪一則還沒確認」。橫幅讓錯誤與清單並存。
    func failureBanner(_ failure: CaregiverCallsViewModel.AcknowledgeFailure) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(failure.message)
                .font(.subheadline)
            Spacer()
            Button {
                Task { await viewModel.doAction(.dismissFailure) }
            } label: {
                Image(systemName: "xmark")
            }
            .accessibilityLabel(Text("Dismiss"))
        }
        .padding(12)
        .background(.orange.opacity(0.12), in: .rect(cornerRadius: 12))
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    /// 空狀態。
    ///
    /// 此處一度放著「請勿開啟靜音模式」的警語，依據是 2026-08-11 的結論
    /// 「靜音 ＋ 背景時警報不會出聲」。該結論已於 08-12 被推翻——真正的原因
    /// 是 App 播完音檔就被凍結，與靜音無關；改為循環播放後，靜音、背景、
    /// 其他 App 正在播音樂等組合都能持續發聲。警語因此移除：**它已經是錯誤
    /// 資訊，而錯誤的告知比不告知更糟**。
    var emptyState: some View {
        ContentUnavailableView(
            "No calls yet",
            systemImage: "bell.slash",
            description: Text("Calls appear here after the patient taps a cell.")
        )
        .frame(maxHeight: .infinity)
    }

    /// 常駐連線指示。與患者端同樣不單靠顏色。
    ///
    /// 語意是「呼叫真的送得到」而非「藍牙連著」——照顧者據此判斷自己現在
    /// 是否還守得住，而不是裝置之間有沒有訊號。
    var connectionIndicator: some View {
        HStack(spacing: 6) {
            Image(
                systemName: viewModel.state.isReachable
                    ? "checkmark.circle.fill"
                    : "exclamationmark.circle.fill"
            )
            if viewModel.state.isReachable {
                Text("Connected")
            } else {
                Text("Not connected")
            }
        }
        .font(.headline)
        .foregroundStyle(viewModel.state.isReachable ? Color.green : Color.orange)
        .accessibilityLabel(
            viewModel.state.isReachable
                ? String(localized: "Calls from the patient are coming through")
                : String(localized: "Calls from the patient cannot come through; the patient is out of range")
        )
    }
}

// MARK: - Preview

// Preview 依賴 `#if DEBUG` 裡的 mock，因此自己也必須包起來——
// 否則 Release build（archive／送審）會找不到 mock 而編譯失敗。
#if DEBUG
#Preview("有呼叫") {
    NavigationStack {
        CaregiverCallsView(viewModel: .mock)
    }
}

#Preview("沒有呼叫") {
    NavigationStack {
        CaregiverCallsView(viewModel: .emptyMock)
    }
}
#endif
