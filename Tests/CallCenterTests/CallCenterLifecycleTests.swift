import Foundation
import Testing

@testable import SideBell

/// 可觀察呼叫次數的假傳輸層。BLE 行為不在此測試範圍，
/// 這裡驗的是 CallCenter 的生命週期不變式。
private final class FakeCallTransport: CallTransport {
    /// 每個消費者一條，與 `BLETransport` 的扇出行為一致。
    private var continuations: [AsyncStream<TransportEvent>.Continuation] = []

    private(set) var startedRoles: [TransportRole] = []
    private(set) var stopCount = 0

    var connectionState: ConnectionState = .idle

    func makeEventStream() -> AsyncStream<TransportEvent> {
        let (stream, continuation) = AsyncStream<TransportEvent>.makeStream(
            bufferingPolicy: .unbounded
        )
        continuations.append(continuation)
        return stream
    }

    func start(as role: TransportRole) {
        startedRoles.append(role)
    }

    func stop() {
        stopCount += 1
    }

    func send(_ message: CallMessage) async throws {}

    func ack(_ callID: UUID) async throws {}

    /// 模擬底層推事件上來。
    func emit(_ event: TransportEvent) {
        for continuation in continuations {
            continuation.yield(event)
        }
    }
}

@Suite("CallCenter 生命週期")
struct CallCenterLifecycleTests {
    /// 等待非同步事件被消費。consumeTask 需要實際排程才會跑。
    private func waitUntil(
        _ condition: () -> Bool,
        attempts: Int = 200
    ) async -> Bool {
        for _ in 0..<attempts {
            if condition() { return true }
            try? await Task.sleep(for: .milliseconds(1))
        }
        return condition()
    }

    @Test("啟動後會消費傳輸事件")
    func consumesEventsAfterStart() async {
        let transport = FakeCallTransport()
        let center = CallCenter(transport: transport)

        center.start(as: .caregiver)
        transport.emit(.connectionStateChanged(.connected(peerCount: 1)))

        #expect(await waitUntil { center.connectionState == .connected(peerCount: 1) })
    }

    /// 使用者切到「未選擇」再切回角色時的路徑。
    /// AsyncStream 只能迭代一次——若 stop 取消了消費 Task，
    /// 重新 start 接到的會是已終止的序列，事件永遠到不了。
    @Test("停止後重新啟動仍能收到事件")
    func restartKeepsConsumingEvents() async {
        let transport = FakeCallTransport()
        let center = CallCenter(transport: transport)

        center.start(as: .patient)
        // 先讓消費 Task 真正進入迭代——這正是真實情境：
        // 使用者是在連線一段時間後才切換角色的。若不等待，Task 還沒排程
        // 就被取消，序列不會終止，bug 也就不會重現。
        transport.emit(.connectionStateChanged(.searching))
        #expect(await waitUntil { center.connectionState == .searching })

        center.stop()
        center.start(as: .caregiver)

        transport.emit(.connectionStateChanged(.connected(peerCount: 1)))

        #expect(await waitUntil { center.connectionState == .connected(peerCount: 1) })
    }

    /// 重新啟動必須真的把角色傳達到傳輸層，
    /// 不能因為「消費者已存在」就整個跳過。
    @Test("重新啟動會把新角色傳給傳輸層")
    func restartForwardsRoleToTransport() {
        let transport = FakeCallTransport()
        let center = CallCenter(transport: transport)

        center.start(as: .patient)
        center.stop()
        center.start(as: .caregiver)

        #expect(transport.startedRoles == [.patient, .caregiver])
        #expect(transport.stopCount == 1)
    }

    @Test("停止後連線狀態回到未啟動")
    func stopResetsConnectionState() async {
        let transport = FakeCallTransport()
        let center = CallCenter(transport: transport)

        center.start(as: .caregiver)
        transport.emit(.connectionStateChanged(.connected(peerCount: 1)))
        _ = await waitUntil { center.connectionState.isConnected }

        center.stop()

        #expect(center.connectionState == .idle)
    }
}
