#if DEBUG
import Foundation

extension CaregiverCallsViewModel {
    /// 有呼叫的畫面：一則緊急未確認、一則一般已確認。
    static var mock: CaregiverCallsViewModel {
        let viewModel = CaregiverCallsViewModel(
            callCenter: CallCenter(transport: PreviewTransport()),
            alertPolicy: AlertPolicy(),
            notifier: CallNotifier(),
            onAlertChanged: {}
        )
        viewModel.state = State(
            calls: [
                CallRow(
                    id: UUID(),
                    title: "不舒服",
                    peerName: "Joe iPad mini 7",
                    pressedAt: Date(timeIntervalSince1970: 1_754_000_000),
                    isUrgent: true,
                    isAcknowledged: false,
                    isExpired: false
                ),
                CallRow(
                    id: UUID(),
                    title: "洗手間",
                    peerName: "Joe iPad mini 7",
                    pressedAt: Date(timeIntervalSince1970: 1_753_999_000),
                    isUrgent: false,
                    isAcknowledged: false,
                    isExpired: true
                ),
                CallRow(
                    id: UUID(),
                    title: "喝水",
                    peerName: "Joe iPad mini 7",
                    pressedAt: Date(timeIntervalSince1970: 1_753_999_400),
                    isUrgent: false,
                    isAcknowledged: true,
                    isExpired: false
                ),
            ],
            connectionState: .connected(peerCount: 1)
        )
        return viewModel
    }

    /// 尚未收到任何呼叫的畫面。
    static var emptyMock: CaregiverCallsViewModel {
        let viewModel = CaregiverCallsViewModel(
            callCenter: CallCenter(transport: PreviewTransport()),
            alertPolicy: AlertPolicy(),
            notifier: CallNotifier(),
            onAlertChanged: {}
        )
        viewModel.state = State(connectionState: .searching)
        return viewModel
    }
}

/// Preview 專用的傳輸替身。不做任何事——Preview 只呈現既定的狀態。
private final class PreviewTransport: CallTransport {
    var connectionState: ConnectionState = .connected(peerCount: 1)

    func makeEventStream() -> AsyncStream<TransportEvent> {
        AsyncStream { _ in }
    }

    func start(as role: TransportRole) {}
    func stop() {}
    func send(_ message: CallMessage) async throws {}
    func ack(_ callID: UUID) async throws {}
}
#endif
