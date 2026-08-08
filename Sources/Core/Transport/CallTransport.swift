import Foundation

/// 呼叫傳輸層的契約。
///
/// 核心邏輯（呼叫、警報、紀錄）只認識這個協定，不得直接依賴 Core Bluetooth。
/// 1.0 的唯一實作是 `BLETransport`；這個縫線存在的目的，是讓 1.1 能加入
/// CloudKit 推播通道而不動到呼叫與警報邏輯。
///
/// 契約只有四個概念：以角色啟動、送出呼叫、確認呼叫、觀察事件與連線狀態。
protocol CallTransport: AnyObject {
    /// 目前連線狀態。
    var connectionState: ConnectionState { get }

    /// 建立一條**專屬於呼叫者**的傳輸事件序列。
    ///
    /// 刻意是方法而非屬性：`AsyncStream` 不是多播的，多個消費者迭代同一條
    /// 序列會把事件瓜分掉——每則事件只送到其中一個消費者手上。實測後果是
    /// 「呼叫一則到、一則不到，確認也一則到、一則不到」，而兩邊都沒有錯誤
    /// 可看。傳輸層本來就有兩個與 App 同壽命的消費者（`CallCenter` 與
    /// `CallDelivery`），因此扇出是這裡的常態，不是例外。
    ///
    /// 每條序列採無上限緩衝：App 被 BLE 事件於背景喚醒時，事件可能早於任何
    /// 消費者出現，會丟棄元素的緩衝策略會讓那則呼叫永遠消失。
    func makeEventStream() -> AsyncStream<TransportEvent>

    /// 以指定角色啟動。患者端開始廣播，照顧者端開始掃描。
    func start(as role: TransportRole)

    /// 停止並釋放連線。
    func stop()

    /// 送出一則呼叫。僅患者角色可用。
    func send(_ message: CallMessage) async throws

    /// 確認一則收到的呼叫。僅照顧者角色可用。
    func ack(_ callID: UUID) async throws
}
