import Foundation

/// 照顧者端呼叫清單。
///
/// 清單本身住在 `CallCenter`（與 App 同壽命），這裡只是把那份快照轉成畫面
/// 用的形狀。畫面不存在時 `CallCenter` 仍在累積呼叫，背景期間收到的那些
/// 就是靠 `onAppear` 的快照補回來的。
@Observable
final class CaregiverCallsViewModel {
    var state: State = .init()

    @ObservationIgnored private let callCenter: CallCenter
    @ObservationIgnored private let alertPolicy: AlertPolicy
    @ObservationIgnored private let notifier: CallNotifier
    /// 確認送出後要重新評估警報——確認是三個停止條件之一。
    @ObservationIgnored private let onAlertChanged: @MainActor () -> Void
    @ObservationIgnored private let now: () -> Date
    /// 定期重算逾時狀態。沒有它，一則呼叫會停在「可確認」直到下一個傳輸事件
    /// 到來——而三分鐘之內很可能什麼事件都沒有。
    @ObservationIgnored private var refreshTask: Task<Void, Never>?

    init(
        callCenter: CallCenter,
        alertPolicy: AlertPolicy,
        notifier: CallNotifier,
        onAlertChanged: @escaping @MainActor () -> Void,
        now: @escaping () -> Date = { Date() }
    ) {
        self.callCenter = callCenter
        self.alertPolicy = alertPolicy
        self.notifier = notifier
        self.onAlertChanged = onAlertChanged
        self.now = now
    }

    deinit {
        refreshTask?.cancel()
    }

    func doAction(_ action: Action) async {
        switch action {
        case .onAppear:
            handleOnAppear()

        case .onDisappear:
            callCenter.onEvent = nil
            refreshTask?.cancel()
            refreshTask = nil

        case let .acknowledge(callID):
            await handleAcknowledge(callID)

        case .dismissFailure:
            state.acknowledgeFailure = nil
        }
    }
}

// MARK: - ViewAction

private extension CaregiverCallsViewModel {
    /// 先讀快照，再接即時事件。
    ///
    /// 順序不可顛倒：先接事件的話，接上到讀快照之間到達的呼叫會被讀取覆蓋掉。
    func handleOnAppear() {
        syncFromCallCenter()

        callCenter.onEvent = { [weak self] _ in
            self?.syncFromCallCenter()
        }

        startRefreshing()
    }

    /// 每五秒重算一次逾時狀態。
    ///
    /// 間隔與 `AlertPolicy` 的重複間隔一致，因此警報停止與畫面標示為
    /// 「無人回應」不會差太多——兩者不同步的話，照顧者會看到一則已經
    /// 不再響的呼叫仍顯示著可以確認。
    func startRefreshing() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(AlertPolicy.repeatInterval))
                guard !Task.isCancelled else { return }
                self?.syncFromCallCenter()
            }
        }
    }

    func handleAcknowledge(_ callID: UUID) async {
        do {
            try await callCenter.ack(callID)
        } catch {
            // 警報**不停止**：照顧者以為送出了確認、患者卻還在等，是這個
            // 產品最危險的失敗模式。警報繼續響，是提醒他這件事還沒完成。
            state.acknowledgeFailure = AcknowledgeFailure(
                callID: callID,
                message: Self.describe(error)
            )
            return
        }

        state.acknowledgeFailure = nil
        // 確認是警報三個停止條件之一。
        alertPolicy.acknowledge(callID)
        onAlertChanged()
        // 鎖屏上那則通知已經過期，留著會讓照顧者稍後解鎖時以為還有事沒處理。
        notifier.clear(callID)
        syncFromCallCenter()
    }
}

// MARK: - 私有

private extension CaregiverCallsViewModel {
    func syncFromCallCenter() {
        let deadline = now().addingTimeInterval(-AlertPolicy.timeout)

        state.connectionState = callCenter.connectionState
        state.calls = callCenter.receivedCalls.map { received in
            CallRow(
                id: received.id,
                title: received.message.title,
                peerName: received.peerName,
                pressedAt: received.message.timestamp,
                isUrgent: received.message.isUrgent,
                isAcknowledged: callCenter.locallyAckedCallIDs.contains(received.id),
                // 與患者端同一個基準點：自患者按下起算，不是自送達起算。
                isExpired: received.message.timestamp <= deadline
            )
        }
    }

    /// 轉成對照顧者有意義的說法。
    ///
    /// 技術原因（`roleMismatch`、`encodingFailed`）對他沒有行動價值——他能做的
    /// 只有「靠近患者再試一次」或「檢查藍牙」，因此全部收斂到那幾句。
    nonisolated static func describe(_ error: Error) -> String {
        guard let transportError = error as? TransportError else {
            return "確認未送達，請再試一次"
        }
        switch transportError {
        case .notConnected, .notStarted:
            return "確認未送達——目前連不上患者的裝置，請靠近一點再試一次"
        case .writeRejected:
            return "確認未送達——兩台裝置尚未完成藍牙配對"
        case .roleMismatch, .encodingFailed:
            return "確認未送達，請再試一次"
        }
    }
}
