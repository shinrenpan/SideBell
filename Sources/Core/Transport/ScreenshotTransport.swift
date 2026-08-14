#if DEBUG
import Foundation

/// 商店截圖用的假傳輸層。
///
/// **存在的理由是模擬器沒有 CoreBluetooth**：連線狀態永遠停在 `searching`，
/// 患者端會一直顯示「未連線」、照顧者端的清單永遠是空的。那是模擬器的限制，
/// 不是產品的樣子，但商店截圖若照實拍下來，看的人只會認為這個 App 壞了。
///
/// 而 App Store 要求的截圖尺寸（iPhone 6.9"、iPad 13"）正好是模擬器的原生
/// 解析度——實機截圖反而要縮放，iPad 尤其對不上長寬比。所以路徑是反過來的：
/// 讓模擬器演出真實的狀態，而不是把實機截圖硬塞進規格。
///
/// **以啟動參數 `-SideBellScreenshotMode` 開啟**，且整個型別包在 `#if DEBUG`
/// 裡——Release build 連編譯都不會編到它，不可能出現在出貨的產品中。
final class ScreenshotTransport: CallTransport {
    /// 啟動參數。沒帶它就完全不會走到這個型別。
    static let launchArgument = "-SideBellScreenshotMode"

    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }

    /// 演出「已連線到一位患者」。這是產品正常運作時的狀態。
    private(set) var connectionState: ConnectionState = .connected(peerCount: 1)

    private var continuations: [UUID: AsyncStream<TransportEvent>.Continuation] = [:]

    func makeEventStream() -> AsyncStream<TransportEvent> {
        AsyncStream(bufferingPolicy: .unbounded) { continuation in
            let id = UUID()
            continuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in self?.continuations[id] = nil }
            }
            continuation.yield(.connectionStateChanged(connectionState))
        }
    }

    func start(as role: TransportRole) {
        guard role == .caregiver else { return }
        // 照顧者端的清單要有東西才看得出這個畫面在做什麼。延遲送出，
        // 讓畫面先完成第一次繪製再插入，避免搶在 onAppear 之前。
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            for (message, peer) in Self.sampleCalls {
                emit(.callReceived(message, peerName: peer))
            }
        }
    }

    func stop() {
        for continuation in continuations.values { continuation.finish() }
        continuations.removeAll()
    }

    func send(_ message: CallMessage) async throws {
        // 患者端截圖時按下格子：立刻回一個確認，讓畫面呈現「已確認」。
        try? await Task.sleep(for: .milliseconds(300))
        emit(.ackReceived(callID: message.id))
    }

    func ack(_ callID: UUID) async throws {
        emit(.ackReceived(callID: callID))
    }
}

// MARK: - 私有

private extension ScreenshotTransport {
    /// 照顧者端清單的示範內容。
    ///
    /// 時間刻意錯開，讓截圖看得出「多久前按的」這件事；`Discomfort` 放最後
    /// 送出，因此排在最上面——那是唯一會重複警報的緊急呼叫，也是這個畫面
    /// 最該被看見的一列。
    static var sampleCalls: [(CallMessage, String)] {
        let now = Date()
        return [
            (
                CallMessage(
                    id: UUID(),
                    commandCode: "WATER",
                    title: String(localized: "Water"),
                    isUrgent: false,
                    timestamp: now.addingTimeInterval(-360)
                ),
                "Patient iPad"
            ),
            (
                CallMessage(
                    id: UUID(),
                    commandCode: "WATER",
                    title: String(localized: "Water"),
                    isUrgent: false,
                    timestamp: now.addingTimeInterval(-120)
                ),
                "Patient iPad"
            ),
            (
                CallMessage(
                    id: UUID(),
                    commandCode: "PAIN",
                    title: String(localized: "Discomfort"),
                    isUrgent: true,
                    timestamp: now.addingTimeInterval(-20)
                ),
                "Patient iPad"
            ),
        ]
    }

    func emit(_ event: TransportEvent) {
        for continuation in continuations.values { continuation.yield(event) }
    }
}
#endif
