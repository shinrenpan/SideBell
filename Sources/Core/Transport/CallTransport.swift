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

    /// 傳輸事件序列。
    ///
    /// 同一個實例回傳同一個序列，且採無上限緩衝：App 被 BLE 事件於背景喚醒時，
    /// 事件可能早於任何消費者出現，會丟棄元素的緩衝策略會讓那則呼叫永遠消失。
    var events: AsyncStream<TransportEvent> { get }

    /// 以指定角色啟動。患者端開始廣播，照顧者端開始掃描。
    func start(as role: TransportRole)

    /// 停止並釋放連線。
    func stop()

    /// 送出一則呼叫。僅患者角色可用。
    func send(_ message: CallMessage) async throws

    /// 確認一則收到的呼叫。僅照顧者角色可用。
    func ack(_ callID: UUID) async throws
}
