import SwiftUI

/// 傳輸層 PoC 畫面。
///
/// ⚠️ 丟棄式：只為驅動 W1 實機驗證而存在，正式畫面完成後整個目錄刪除。
/// 因此這裡不做無障礙打磨與眼控尺寸——那些屬於正式的患者端畫面。
struct TransportPoCView: View {
    @Bindable var viewModel: TransportPoCViewModel

    var body: some View {
        List {
            statusSection
            actionSection
            receivedSection
            if let failure = viewModel.state.failureText {
                failureSection(failure)
            }
        }
        .navigationTitle("SideBell PoC")
        .toolbar {
            // 只有患者端需要這個入口：照顧者端的設定在分頁列上，
            // 而且照顧者沒有誤觸的顧慮。
            if viewModel.state.role == .patient {
                ToolbarItem(placement: .topBarTrailing) {
                    TwoStepConfirmButton(idleTitle: "設定", confirmTitle: "再按一次") {
                        Task { await viewModel.doAction(.openSettings) }
                    }
                }
            }
        }
        .task {
            await viewModel.doAction(.onAppear)
        }
    }
}

// MARK: - Sections

private extension TransportPoCView {
    var statusSection: some View {
        Section("連線狀態") {
            LabeledContent("狀態", value: connectionText)
        }
    }

    @ViewBuilder
    var actionSection: some View {
        Section("動作") {
            Button("送出呼叫（喝水）") {
                Task { await viewModel.doAction(.sendCall) }
            }
            .disabled(viewModel.state.role != .patient)
        }

        if viewModel.state.role == .patient {
            Section("我送出的呼叫") {
                if viewModel.state.sentCalls.isEmpty {
                    Text("尚未送出任何呼叫")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.state.sentCalls) { call in
                        sentRow(call)
                    }
                }
            }
        }
    }

    /// 每一則各自顯示確認狀態。只給總計數字無法分辨
    /// 「第二則沒被確認」與「重複確認了第一則」。
    func sentRow(_ call: TransportPoCViewModel.SentCall) -> some View {
        let isAcked = viewModel.state.ackedCallIDs.contains(call.id)
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(call.id.shortLabel)
                    .font(.system(.body, design: .monospaced))
                Text(call.sentAt.formatted(date: .omitted, time: .standard))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(isAcked ? "✓ 已確認" : "等待中")
                .font(.caption)
                .foregroundStyle(isAcked ? .green : .secondary)
        }
    }

    @ViewBuilder
    var receivedSection: some View {
        Section("收到的呼叫") {
            if viewModel.state.receivedCalls.isEmpty {
                Text("尚未收到任何呼叫")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.state.receivedCalls) { call in
                    receivedRow(call)
                }
            }
        }
    }

    func receivedRow(_ call: CallCenter.ReceivedCall) -> some View {
        let isAcked = viewModel.state.locallyAckedCallIDs.contains(call.id)
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(call.message.title)
                    .font(.headline)
                Spacer()
                if isAcked {
                    Text("✓ 已送出確認")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            Text("識別碼：\(call.id.shortLabel)")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
            Text("來源：\(call.peerName)")
                .font(.caption)
                .foregroundStyle(.secondary)
            // 同時顯示患者按下的時間與實際送達時間。
            // 兩者的差就是喚醒延遲——背景測試唯一有意義的指標。
            Text("按下：\(call.message.timestamp.formatted(date: .omitted, time: .standard))")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("送達：\(call.receivedAt.formatted(date: .omitted, time: .standard))"
                 + "（延遲 \(Int(call.receivedAt.timeIntervalSince(call.message.timestamp))) 秒）")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button(isAcked ? "再次確認" : "已收到") {
                Task { await viewModel.doAction(.ack(call.id)) }
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.state.role != .caregiver)
        }
    }

    func failureSection(_ text: String) -> some View {
        Section("失敗") {
            Text(text)
                .foregroundStyle(.red)
            Button("清除") {
                Task { await viewModel.doAction(.dismissFailure) }
            }
        }
    }
}

// MARK: - 私有

private extension TransportPoCView {
    var connectionText: String {
        switch viewModel.state.connectionState {
        case .idle: "未啟動"
        case .searching: viewModel.state.role == .patient ? "廣播中" : "掃描中"
        case let .connected(peerCount): "已連線（\(peerCount) 台）"
        case .unavailable(.poweredOff): "⚠️ 藍牙已關閉"
        case .unavailable(.unauthorized): "⚠️ 未授權使用藍牙"
        case .unavailable(.unsupported): "⚠️ 此裝置不支援藍牙"
        }
    }
}
