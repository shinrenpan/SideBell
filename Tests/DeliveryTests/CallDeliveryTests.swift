import Foundation
import Testing

@testable import SideBell

/// 可控制的傳輸替身。只記錄行為，不涉及 BLE。
private final class FakeCallTransport: CallTransport {
    /// 每個消費者一條，與 `BLETransport` 的扇出行為一致。
    private var continuations: [AsyncStream<TransportEvent>.Continuation] = []

    private(set) var sentMessages: [CallMessage] = []
    /// 下一次 `send` 是否應失敗，用來模擬「照顧者不在範圍」。
    var isConnected = false

    var connectionState: ConnectionState = .searching

    func makeEventStream() -> AsyncStream<TransportEvent> {
        let (stream, continuation) = AsyncStream<TransportEvent>.makeStream(
            bufferingPolicy: .unbounded
        )
        continuations.append(continuation)
        return stream
    }

    private func yield(_ event: TransportEvent) {
        for continuation in continuations {
            continuation.yield(event)
        }
    }

    func start(as role: TransportRole) {}
    func stop() {}

    func send(_ message: CallMessage) async throws {
        guard isConnected else { throw TransportError.notConnected }
        sentMessages.append(message)
    }

    func ack(_ callID: UUID) async throws {}

    /// 模擬照顧者出現。
    func simulateConnected() {
        isConnected = true
        connectionState = .connected(peerCount: 1)
        yield(.connectionStateChanged(connectionState))
    }

    func simulateAck(_ callID: UUID) {
        yield(.ackReceived(callID: callID))
    }
}

@Suite("呼叫生命週期")
@MainActor
struct CallDeliveryTests {
    /// 等待非同步事件被處理。
    private func settle(_ condition: () -> Bool, attempts: Int = 200) async -> Bool {
        for _ in 0..<attempts {
            if condition() { return true }
            try? await Task.sleep(for: .milliseconds(1))
        }
        return condition()
    }

    private func makeDelivery(
        transport: FakeCallTransport,
        clock: TestClock
    ) -> CallDelivery {
        let delivery = CallDelivery(transport: transport, now: { clock.now })
        delivery.start()
        return delivery
    }

    // MARK: - 待送與重送

    /// spec: Sending with no caregiver connected
    ///
    /// 送不出去**不是失敗**：讓患者反覆重按，等於把輪詢外包給最沒有能力
    /// 做這件事的人。
    @Test("沒有連線時轉為待送而非失敗")
    func queuesWhenNotConnected() async {
        let transport = FakeCallTransport()
        let clock = TestClock()
        let delivery = makeDelivery(transport: transport, clock: clock)

        let id = await delivery.send(gridItemID: UUID(), title: "喝水", commandCode: "WATER", isUrgent: false)

        #expect(delivery.state(of: id) == .waiting)
        #expect(transport.sentMessages.isEmpty)
    }

    /// spec: Delivery on reconnection
    @Test("連線恢復時自動送出待送的呼叫")
    func sendsPendingOnReconnection() async {
        let transport = FakeCallTransport()
        let clock = TestClock()
        let delivery = makeDelivery(transport: transport, clock: clock)

        let id = await delivery.send(gridItemID: UUID(), title: "喝水", commandCode: "WATER", isUrgent: false)
        transport.simulateConnected()

        #expect(await settle { transport.sentMessages.count == 1 })
        #expect(transport.sentMessages.first?.id == id)
        #expect(delivery.state(of: id) == .waiting)
    }

    /// spec: Multiple pending calls
    ///
    /// 刻意用五則而非兩則：待送佇列存在字典裡，排序若退回依時間戳，
    /// 兩則有一半機率矇混過關，五則則幾乎必然被抓到。時鐘固定不動，
    /// 因此五則的時間戳完全並列——這正是排序必須靠觸發序號的情境。
    @Test("多筆待送依患者觸發的順序送出")
    func sendsPendingInTriggerOrder() async {
        let transport = FakeCallTransport()
        let clock = TestClock()
        let delivery = makeDelivery(transport: transport, clock: clock)

        let titles = ["第一", "第二", "第三", "第四", "第五"]
        for title in titles {
            _ = await delivery.send(
                gridItemID: UUID(),
                title: title,
                commandCode: "C",
                isUrgent: false
            )
        }
        transport.simulateConnected()

        #expect(await settle { transport.sentMessages.count == titles.count })
        #expect(transport.sentMessages.map(\.title) == titles)
    }

    // MARK: - 確認與逾時

    @Test("收到確認後轉為已確認")
    func acknowledgementMarksCall() async {
        let transport = FakeCallTransport()
        transport.isConnected = true
        let clock = TestClock()
        let delivery = makeDelivery(transport: transport, clock: clock)

        let id = await delivery.send(gridItemID: UUID(), title: "喝水", commandCode: "WATER", isUrgent: false)
        transport.simulateAck(id)

        #expect(await settle { delivery.state(of: id) == .acknowledged })
    }

    /// spec: state by outcome —— 逐列對照
    ///
    /// 逾時以可注入的時間來源驅動，不真的等三分鐘。
    @Test("逾時後轉為無人回應", arguments: [true, false])
    func timesOutWithoutAcknowledgement(wasTransmitted: Bool) async {
        let transport = FakeCallTransport()
        transport.isConnected = wasTransmitted
        let clock = TestClock()
        let delivery = makeDelivery(transport: transport, clock: clock)

        let id = await delivery.send(gridItemID: UUID(), title: "喝水", commandCode: "WATER", isUrgent: false)
        clock.advance(by: CallDelivery.timeout + 1)
        delivery.checkTimeouts()

        #expect(delivery.state(of: id) == .unanswered)
    }

    @Test("逾時後才到達的確認不會改變結果")
    func lateAcknowledgementIsIgnored() async {
        let transport = FakeCallTransport()
        transport.isConnected = true
        let clock = TestClock()
        let delivery = makeDelivery(transport: transport, clock: clock)

        let id = await delivery.send(gridItemID: UUID(), title: "喝水", commandCode: "WATER", isUrgent: false)
        clock.advance(by: CallDelivery.timeout + 1)
        delivery.checkTimeouts()
        transport.simulateAck(id)

        _ = await settle({ false }, attempts: 20)
        #expect(delivery.state(of: id) == .unanswered)
    }

    /// spec: Delivered but never acknowledged
    ///
    /// 逾時的計時起點是**患者按下**，不是送出——若從送出起算，一則排隊
    /// 兩分鐘才送出的呼叫會讓患者總共等上五分鐘。
    @Test("逾時自觸發時刻起算，不從送出起算")
    func timeoutMeasuredFromTrigger() async {
        let transport = FakeCallTransport()
        let clock = TestClock()
        let delivery = makeDelivery(transport: transport, clock: clock)

        let id = await delivery.send(gridItemID: UUID(), title: "喝水", commandCode: "WATER", isUrgent: false)

        // 排隊兩分鐘後才連上並送出。
        clock.advance(by: 120)
        transport.simulateConnected()
        #expect(await settle { transport.sentMessages.count == 1 })

        // 自觸發起算的第三分鐘就該逾時，而非送出後再等三分鐘。
        clock.advance(by: CallDelivery.timeout - 120 + 1)
        delivery.checkTimeouts()

        #expect(delivery.state(of: id) == .unanswered)
    }

    // MARK: - 狀態查詢

    /// spec: Queued and transmitted look the same
    @Test("待送與已送出對外都是等待中")
    func queuedAndTransmittedShareOneState() async {
        let transport = FakeCallTransport()
        let clock = TestClock()
        let delivery = makeDelivery(transport: transport, clock: clock)

        let queued = await delivery.send(gridItemID: UUID(), title: "排隊", commandCode: "A", isUrgent: false)
        transport.isConnected = true
        let transmitted = await delivery.send(gridItemID: UUID(), title: "已送", commandCode: "B", isUrgent: false)

        #expect(delivery.state(of: queued) == .waiting)
        #expect(delivery.state(of: transmitted) == .waiting)
    }

    /// spec: Repeated use replaces the previous state
    @Test("同一格再次觸發會取代先前的狀態")
    func newCallReplacesPreviousStateForSameItem() async {
        let transport = FakeCallTransport()
        transport.isConnected = true
        let clock = TestClock()
        let delivery = makeDelivery(transport: transport, clock: clock)
        let itemID = UUID()

        let first = await delivery.send(gridItemID: itemID, title: "喝水", commandCode: "W", isUrgent: false)
        clock.advance(by: CallDelivery.timeout + 1)
        delivery.checkTimeouts()
        #expect(delivery.state(ofGridItem: itemID) == .unanswered)

        let second = await delivery.send(gridItemID: itemID, title: "喝水", commandCode: "W", isUrgent: false)
        #expect(delivery.state(ofGridItem: itemID) == .waiting)
        #expect(first != second)
    }

    @Test("未使用過的格子沒有狀態")
    func unusedItemHasNoState() {
        let transport = FakeCallTransport()
        let clock = TestClock()
        let delivery = makeDelivery(transport: transport, clock: clock)

        #expect(delivery.state(ofGridItem: UUID()) == nil)
    }
}

// MARK: - 測試用時鐘

/// 可控制的時間來源。逾時測試不能真的等三分鐘。
private final class TestClock {
    private(set) var now = Date(timeIntervalSince1970: 1_754_000_000)

    func advance(by seconds: TimeInterval) {
        now = now.addingTimeInterval(seconds)
    }
}
