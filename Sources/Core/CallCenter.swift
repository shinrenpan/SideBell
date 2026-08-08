import Foundation

/// 傳輸事件的消費者，生命週期與 App 相同。
///
/// 存在的理由：App 被 BLE 事件於背景喚醒時，畫面與 ViewModel 都不存在。
/// 若由 ViewModel 消費事件，那則呼叫等於沒有人接。因此消費者必須在
/// `application(_:didFinishLaunchingWithOptions:)` 就建立，並在整個 App
/// 生命週期內持續存在。
///
/// 本 change 只實作最小形式：持有、消費、暴露狀態快照。警報、資料庫寫入、
/// 重送狀態機都是後續里程碑掛在同一個位置上的職責。
///
/// 處理路徑刻意維持「同步、無等待」：BLE 背景喚醒只給約 10 秒處理窗，
/// 後續掛上警報與資料庫寫入後這個預算會迅速吃緊。
@Observable
final class CallCenter {
    private let transport: any CallTransport
    @ObservationIgnored private var consumeTask: Task<Void, Never>?

    private(set) var connectionState: ConnectionState = .idle
    /// 最近收到的呼叫，新的在前。畫面不存在時仍持續累積，
    /// 因此 ViewModel 出現時讀得到背景期間收到的呼叫。
    private(set) var receivedCalls: [ReceivedCall] = []
    /// 已被確認的呼叫識別碼（患者端視角：對方已收到）。
    private(set) var ackedCallIDs: Set<UUID> = []
    /// 本機已送出確認的呼叫（照顧者端視角：我按過「已收到」）。
    ///
    /// 與 `ackedCallIDs` 分開：一個是「我確認了誰」，一個是「誰確認了我」。
    /// 沒有這個區分，照顧者端按下確認後畫面毫無變化，使用者無從分辨
    /// 「按了沒作用」與「送出了但對方沒收到」。
    private(set) var locallyAckedCallIDs: Set<UUID> = []

    /// 目前存在的畫面可設定此回呼以即時反應事件；畫面不存在時為 nil，
    /// 事件仍會更新上方的狀態快照。
    @ObservationIgnored var onEvent: ((TransportEvent) -> Void)?

    /// PoC 階段保留的呼叫筆數上限，避免長時間執行後無上限成長。
    private static let recentCallLimit = 20

    init(transport: any CallTransport) {
        self.transport = transport
    }

    deinit {
        consumeTask?.cancel()
    }
}

// MARK: - 生命週期

extension CallCenter {
    /// 先接上消費者再啟動傳輸層，確保啟動瞬間的事件有人處理。
    func start(as role: TransportRole) {
        startConsumingIfNeeded()
        transport.start(as: role)
    }

    /// 停止傳輸，但**不**停止事件消費。
    ///
    /// 序列只能被迭代一次：一旦取消消費 Task，該序列即永久終止，之後重新
    /// 啟動所接到的會是一條死掉的序列，BLE 事件永遠送不進來——症狀是
    /// 「切換角色後再也連不上，重開 App 才正常」。
    /// 消費者的壽命因此與 CallCenter 相同，只在 deinit 結束。
    func stop() {
        transport.stop()
        connectionState = .idle
    }

    func send(_ message: CallMessage) async throws {
        try await transport.send(message)
    }

    func ack(_ callID: UUID) async throws {
        try await transport.ack(callID)
        // 只有寫入沒有拋錯才記錄。這裡記的是「已送出確認」，
        // 不代表對端已收到——後者要由患者端的 ackedCallIDs 證明。
        locallyAckedCallIDs.insert(callID)
    }
}

// MARK: - 私有

private extension CallCenter {
    func startConsumingIfNeeded() {
        guard consumeTask == nil else { return }

        // 取自己專屬的一條序列。與 CallDelivery 共用同一條會把事件瓜分掉，
        // 症狀是連線狀態與確認時有時無——見 CallTransport.makeEventStream()。
        let events = transport.makeEventStream()
        consumeTask = Task { [weak self] in
            for await event in events {
                guard let self else { return }
                handle(event)
            }
        }
    }

    func handle(_ event: TransportEvent) {
        switch event {
        case let .callReceived(message, peerName):
            // 以識別碼去重：重送與多路徑情境下同一則呼叫可能到達兩次。
            // 完整的重送/去重規則屬後續 change，這裡只擋住最直接的重複顯示。
            if !receivedCalls.contains(where: { $0.id == message.id }) {
                receivedCalls.insert(
                    ReceivedCall(message: message, peerName: peerName, receivedAt: Date()),
                    at: 0
                )
                if receivedCalls.count > Self.recentCallLimit {
                    receivedCalls.removeLast()
                }
            }

        case let .ackReceived(callID):
            ackedCallIDs.insert(callID)

        case let .connectionStateChanged(state):
            connectionState = state
        }

        onEvent?(event)
    }
}

// MARK: - Models

extension CallCenter {
    /// 一則已收到的呼叫，含來源與實際送達時間。
    ///
    /// `receivedAt` 是送達當下的時間，不是開啟 App 的時間——鎖屏背景送達的
    /// 驗證就靠這個欄位分辨。訊息本身的 `timestamp` 則是患者按下的時間。
    nonisolated struct ReceivedCall: Identifiable, Equatable, Sendable {
        let message: CallMessage
        let peerName: String
        let receivedAt: Date

        var id: UUID { message.id }
    }
}
