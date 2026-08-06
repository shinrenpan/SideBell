import Foundation

/// `CallTransport` 的 BLE 實作，也是 1.0 的唯一實作。
///
/// 對外是單一傳輸層；內部依角色委派給兩個端點之一。兩端的委派協定、
/// 狀態機與失敗模式完全不同，混在一個型別裡會產生大量「這個回呼在哪個
/// 角色下才有意義」的條件判斷。核心邏輯不需要知道這個拆分。
///
/// 整體採主動作者隔離、Bluetooth manager 以主佇列建立：本產品一天的呼叫
/// 數量以個位數計、單則訊息上限 131 位元組，沒有重運算或大量 I/O。在這個
/// 負載下另開佇列只會換來跨隔離邊界的複雜度，而背景喚醒的除錯難度已經夠高。
///
/// 未確認的呼叫只存在於記憶體（端點的 pendingFrames）：App 重啟後復活的
/// 舊呼叫對照顧者是假警報，不是遲到的訊息。
final class BLETransport: CallTransport {
    private let nickname: String?
    private var role: TransportRole?
    private var peripheralEndpoint: BLEPeripheralEndpoint?
    private var centralEndpoint: BLECentralEndpoint?

    private let stream: AsyncStream<TransportEvent>
    private let continuation: AsyncStream<TransportEvent>.Continuation

    private(set) var connectionState: ConnectionState = .idle

    var events: AsyncStream<TransportEvent> { stream }

    /// - Parameter nickname: 患者自訂暱稱，寫入 Device Info 特徵。未設定時傳 nil，
    ///   照顧者端會改用系統的藍牙裝置名稱。
    init(nickname: String?) {
        self.nickname = nickname
        // 無上限緩衝：App 被 BLE 事件於背景喚醒時，事件可能早於消費者出現。
        // 會丟棄元素的緩衝策略會讓那則呼叫永遠消失，症狀是「偶爾收不到」。
        let (stream, continuation) = AsyncStream<TransportEvent>.makeStream(
            bufferingPolicy: .unbounded
        )
        self.stream = stream
        self.continuation = continuation
    }

    deinit {
        continuation.finish()
    }
}

// MARK: - CallTransport

extension BLETransport {
    func start(as role: TransportRole) {
        if let current = self.role, current != role {
            stop()
        }
        guard self.role == nil else { return }
        self.role = role

        // 端點一旦建立就不再釋放：它們持有帶還原識別碼的 Bluetooth manager，
        // 而那種 manager 的狀態由系統保管，釋放物件並不會停止系統層的
        // 廣播或掃描，只會讓我們失去控制權。角色切換靠 start/stop 切換行為。
        switch role {
        case .patient:
            centralEndpoint?.stop()
            if peripheralEndpoint == nil {
                peripheralEndpoint = BLEPeripheralEndpoint(nickname: nickname) { [weak self] event in
                    self?.emit(event)
                }
            }
            peripheralEndpoint?.start()

        case .caregiver:
            peripheralEndpoint?.stop()
            if centralEndpoint == nil {
                centralEndpoint = BLECentralEndpoint { [weak self] event in
                    self?.emit(event)
                }
            }
            centralEndpoint?.start()
        }
    }

    func stop() {
        peripheralEndpoint?.stop()
        centralEndpoint?.stop()
        role = nil
        connectionState = .idle
    }

    func send(_ message: CallMessage) async throws {
        guard let role else { throw TransportError.notStarted }
        guard role == .patient else {
            throw TransportError.roleMismatch(expected: .patient, actual: role)
        }
        guard let peripheralEndpoint else { throw TransportError.notStarted }

        let frame: Data
        do {
            frame = try CallMessageCodec.encode(message)
        } catch let error as WireFormatError {
            throw TransportError.encodingFailed(error)
        }

        try peripheralEndpoint.send(frame)
    }

    func ack(_ callID: UUID) async throws {
        guard let role else { throw TransportError.notStarted }
        guard role == .caregiver else {
            throw TransportError.roleMismatch(expected: .caregiver, actual: role)
        }
        guard let centralEndpoint else { throw TransportError.notStarted }

        try centralEndpoint.ack(callID)
    }
}

// MARK: - 私有

private extension BLETransport {
    func emit(_ event: TransportEvent) {
        if case .connectionStateChanged(let state) = event {
            connectionState = state
        }
        continuation.yield(event)
    }
}
