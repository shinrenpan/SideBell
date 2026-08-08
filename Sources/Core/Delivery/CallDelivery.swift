import Foundation

/// 呼叫送出後的生命週期：待送、重送、逾時、確認。
///
/// 這套規則刻意住在核心層而不是 ViewModel：它與畫面無關，照顧者端未來
/// 也會消費同一組狀態。綁在 ViewModel 上等於綁在畫面的生命週期上，而
/// 畫面隨時會消失——W1 已經踩過一次（事件消費者一度綁在畫面上，App 於
/// 背景被喚醒時沒有人接）。
///
/// 狀態只存在記憶體，不持久化：App 重啟後復活的舊呼叫是假警報而非遲到的
/// 訊息，而假警報會侵蝕照顧者對警示的信任。
@Observable
final class CallDelivery {
    /// 從患者按下起算的逾時。
    ///
    /// 三分鐘由患者這一側決定，不是由重試成本決定：一分鐘太短——照顧者
    /// 去趟廁所就會被判失敗；超過三分鐘則是讓患者持續等待一條不通的路，
    /// 而他該去尋求別的協助了。
    nonisolated static let timeout: TimeInterval = 180

    private(set) var calls: [UUID: PendingCall] = [:]
    /// 每個格子最近一次呼叫的識別碼。
    private(set) var latestCallByGridItem: [UUID: UUID] = [:]

    @ObservationIgnored private let transport: any CallTransport
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private var consumeTask: Task<Void, Never>?
    @ObservationIgnored private var timeoutTask: Task<Void, Never>?
    /// 下一則呼叫的觸發序號。理由見 `PendingCall.sequence`。
    @ObservationIgnored private var nextSequence = 0

    /// 確認到達或呼叫失敗時通知——供畫面播放震動與音效。
    @ObservationIgnored var onOutcome: ((CallState, UUID) -> Void)?

    /// - Parameter now: 時間來源。可注入讓逾時測試不必真的等三分鐘。
    init(transport: any CallTransport, now: @escaping () -> Date = { Date() }) {
        self.transport = transport
        self.now = now
    }

    deinit {
        consumeTask?.cancel()
        timeoutTask?.cancel()
    }
}

// MARK: - 生命週期

extension CallDelivery {
    func start() {
        guard consumeTask == nil else { return }

        // 取自己專屬的一條序列。與 CallCenter 共用同一條會把事件瓜分掉，
        // 症狀是確認與待送重試時有時無——見 CallTransport.makeEventStream()。
        let events = transport.makeEventStream()
        consumeTask = Task { [weak self] in
            for await event in events {
                guard let self else { return }
                handle(event)
            }
        }
        startTimeoutSweep()
    }

    func stop() {
        consumeTask?.cancel()
        consumeTask = nil
        timeoutTask?.cancel()
        timeoutTask = nil
    }
}

// MARK: - 送出

extension CallDelivery {
    /// 送出一則呼叫，回傳其識別碼。
    ///
    /// 送不出去**不視為失敗**：目標族群的每次操作都有實質成本，讓患者
    /// 反覆重按等於把輪詢外包給最沒有能力做這件事的人。
    @discardableResult
    func send(gridItemID: UUID, title: String, commandCode: String, isUrgent: Bool) async -> UUID {
        let message = CallMessage(
            id: UUID(),
            commandCode: commandCode,
            title: title,
            isUrgent: isUrgent,
            timestamp: now()
        )

        nextSequence += 1
        var call = PendingCall(
            id: message.id,
            gridItemID: gridItemID,
            message: message,
            triggeredAt: now(),
            sequence: nextSequence,
            state: .waiting,
            isTransmitted: false
        )

        do {
            try await transport.send(message)
            call.isTransmitted = true
        } catch TransportError.notConnected, TransportError.notStarted {
            // 留在待送佇列，等連線事件。
        } catch {
            // 編碼失敗或角色錯誤：重試不會好轉，直接判定失敗。
            call.state = .unanswered
            SideBellLog.transport.info("delivery: 呼叫無法送出且不可重試 \(String(describing: error), privacy: .public)")
        }

        calls[call.id] = call
        latestCallByGridItem[gridItemID] = call.id
        if call.state == .unanswered {
            onOutcome?(.unanswered, gridItemID)
        }
        return call.id
    }
}

// MARK: - 查詢

extension CallDelivery {
    func state(of callID: UUID) -> CallState? {
        calls[callID]?.state
    }

    /// 某個格子最近一次呼叫的狀態。未使用過的格子回 nil。
    func state(ofGridItem gridItemID: UUID) -> CallState? {
        guard let callID = latestCallByGridItem[gridItemID] else { return nil }
        return calls[callID]?.state
    }
}

// MARK: - 逾時

extension CallDelivery {
    /// 掃描並標記逾時的呼叫。對外開放供測試以受控時間驅動。
    func checkTimeouts() {
        let deadline = now().addingTimeInterval(-Self.timeout)

        for (id, call) in calls where call.state == .waiting && call.triggeredAt <= deadline {
            calls[id]?.state = .unanswered
            onOutcome?(.unanswered, call.gridItemID)
            SideBellLog.transport.info("delivery: 呼叫逾時未獲回應")
        }
    }
}

// MARK: - 私有

private extension CallDelivery {
    func handle(_ event: TransportEvent) {
        switch event {
        case let .connectionStateChanged(state) where state.isConnected:
            Task { await flushPending() }

        case let .ackReceived(callID):
            acknowledge(callID)

        default:
            break
        }
    }

    /// 依患者觸發的順序送出待送的呼叫。
    ///
    /// 由連線事件驅動而非定時輪詢：輪詢既延遲（照顧者回來後最多要等一個
    /// 完整週期）又耗電，而傳輸層本來就會回報連線變化。
    ///
    /// 排序用觸發序號而非時間戳：時間戳會並列，而並列時的順序是隨機的
    /// ——見 `PendingCall.sequence`。
    func flushPending() async {
        let pending = calls.values
            .filter { $0.state == .waiting && !$0.isTransmitted }
            .sorted { $0.sequence < $1.sequence }

        for call in pending {
            do {
                try await transport.send(call.message)
                calls[call.id]?.isTransmitted = true
            } catch {
                // 仍然送不出去，留在佇列等下一次連線事件。
                return
            }
        }
    }

    /// 逾時後才到達的確認不改變結果——那則呼叫已經走完它的生命週期，
    /// 患者也已經被告知該改用其他方式。
    func acknowledge(_ callID: UUID) {
        guard let call = calls[callID], call.state == .waiting else { return }
        calls[callID]?.state = .acknowledged
        onOutcome?(.acknowledged, call.gridItemID)
    }

    /// 定期掃描逾時。
    ///
    /// 這裡用得著輪詢，因為逾時本來就是時間到才發生的事件，沒有外部來源
    /// 會通知我們。掃描間隔遠小於逾時長度即可。
    func startTimeoutSweep() {
        timeoutTask?.cancel()
        timeoutTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { return }
                self?.checkTimeouts()
            }
        }
    }
}
