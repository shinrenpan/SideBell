import Foundation
import Testing

@testable import SideBell

/// 傳輸事件必須送達**每一個**消費者，而不是被瓜分。
///
/// 這組測試守的是一個只在雙機實測才看得見的失敗：`CallCenter` 與
/// `CallDelivery` 兩個與 App 同壽命的消費者曾迭代同一條 `AsyncStream`，
/// 而 `AsyncStream` 不是多播的——每則事件只送到其中一個消費者手上。
/// 實測症狀是呼叫與確認「一則到、一則不到」，兩邊都沒有錯誤可看，
/// 而連線指示會停在錯誤的狀態。
/// 只做扇出，不碰 BLE——`CallCenter.start` 會啟動真的傳輸層，
/// 在單元測試裡建立 `CBPeripheralManager` 會觸發權限請求。
private final class FanOutTestTransport: CallTransport {
    private var continuations: [AsyncStream<TransportEvent>.Continuation] = []

    var connectionState: ConnectionState = .idle

    func makeEventStream() -> AsyncStream<TransportEvent> {
        let (stream, continuation) = AsyncStream<TransportEvent>.makeStream(
            bufferingPolicy: .unbounded
        )
        continuations.append(continuation)
        return stream
    }

    func start(as role: TransportRole) {}
    func stop() {}
    func send(_ message: CallMessage) async throws {}
    func ack(_ callID: UUID) async throws {}

    func emit(_ event: TransportEvent) {
        if case .connectionStateChanged(let state) = event {
            connectionState = state
        }
        for continuation in continuations {
            continuation.yield(event)
        }
    }
}

@Suite("傳輸事件扇出")
@MainActor
struct TransportEventFanOutTests {
    private func waitUntil(_ condition: () -> Bool, attempts: Int = 200) async -> Bool {
        for _ in 0..<attempts {
            if condition() { return true }
            try? await Task.sleep(for: .milliseconds(1))
        }
        return condition()
    }

    @Test("每個消費者都收到同一則事件")
    func everyConsumerReceivesTheSameEvent() async {
        let transport = BLETransport(nickname: nil)
        let first = transport.makeEventStream()
        let second = transport.makeEventStream()

        transport.emit(.connectionStateChanged(.connected(peerCount: 1)))
        transport.emit(.ackReceived(callID: UUID()))

        var firstCount = 0
        for await _ in first.prefix(2) { firstCount += 1 }

        var secondCount = 0
        for await _ in second.prefix(2) { secondCount += 1 }

        #expect(firstCount == 2)
        #expect(secondCount == 2)
    }

    @Test("每次索取都是一條獨立的序列")
    func eachRequestYieldsAnIndependentStream() async {
        let transport = BLETransport(nickname: nil)
        let first = transport.makeEventStream()
        let second = transport.makeEventStream()

        let callID = UUID()
        transport.emit(.ackReceived(callID: callID))

        var firstEvent: TransportEvent?
        for await event in first.prefix(1) { firstEvent = event }
        var secondEvent: TransportEvent?
        for await event in second.prefix(1) { secondEvent = event }

        // 同一則事件在兩條序列上各出現一次——不是其中一條拿到、另一條落空。
        #expect(firstEvent == .ackReceived(callID: callID))
        #expect(secondEvent == .ackReceived(callID: callID))
    }

    /// 這是實機上真正壞掉的組合：兩個消費者同時在聽同一個傳輸層。
    ///
    /// 患者端按下呼叫後，確認必須同時讓 `CallCenter`（畫面的狀態快照）
    /// 與 `CallDelivery`（格子狀態與逾時判定）都看到。少了任何一邊，
    /// 格子就會停在「等待中」直到三分鐘後被判為無人回應。
    @Test("CallCenter 與 CallDelivery 同時消費時都收得到確認")
    func bothLongLivedConsumersReceiveAcks() async {
        let transport = FanOutTestTransport()
        let center = CallCenter(transport: transport)
        let delivery = CallDelivery(transport: transport)

        center.start(as: .patient)
        delivery.start()

        let callID = await delivery.send(
            gridItemID: UUID(),
            title: "喝水",
            commandCode: "drink",
            isUrgent: false
        )
        transport.emit(.ackReceived(callID: callID))

        #expect(await waitUntil { center.ackedCallIDs.contains(callID) })
        #expect(await waitUntil { delivery.state(of: callID) == .acknowledged })
    }

    @Test("兩個消費者同時在聽時連線狀態仍會更新")
    func connectionStateStillUpdatesWithTwoConsumers() async {
        let transport = FanOutTestTransport()
        let center = CallCenter(transport: transport)
        let delivery = CallDelivery(transport: transport)

        center.start(as: .patient)
        delivery.start()

        transport.emit(.connectionStateChanged(.connected(peerCount: 1)))

        #expect(await waitUntil { center.connectionState == .connected(peerCount: 1) })
    }
}
