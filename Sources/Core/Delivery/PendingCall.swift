import Foundation

/// 一則呼叫對患者呈現的狀態。
///
/// 刻意只有三種。「尚未送出」與「已送達但未確認」不予區分——那個區別對
/// 患者沒有行動價值（他無法改變自己與照顧者的距離）。只有終局狀態有價值：
/// 告訴他這條路不通，該改用其他方式求助。
nonisolated enum CallState: Equatable, Sendable {
    case waiting
    case acknowledged
    /// 逾時未獲回應。用詞刻意不是「未送達」——呼叫可能確實送到了照顧者
    /// 手機、警報也響了，只是他在睡覺沒按確認。「無人回應」在兩種情況下
    /// 都為真，而對患者的行動含義相同。
    case unanswered
}

/// 一則進行中的呼叫。
nonisolated struct PendingCall: Identifiable, Equatable, Sendable {
    let id: UUID
    /// 送出這則呼叫的格子。用於在該格顯示狀態。
    let gridItemID: UUID
    let message: CallMessage
    /// 患者按下的時刻。逾時自此起算，而非自送出起算——若從送出起算，
    /// 一則排隊兩分鐘才送出的呼叫會讓患者總共等上五分鐘，而他不知道
    /// 其中兩分鐘是排隊。
    let triggeredAt: Date
    /// 觸發序號，單調遞增。
    ///
    /// 待送佇列的排序不能只靠 `triggeredAt`：呼叫存在字典裡，而字典的迭代
    /// 順序不確定、`sorted` 也不保證穩定，因此兩則時間戳並列的呼叫會以隨機
    /// 順序送出。患者連按兩格後照顧者回到範圍，收到的順序就可能是倒的。
    let sequence: Int
    var state: CallState
    /// 是否已成功交給傳輸層。僅供內部判斷是否需要重送，不對患者呈現。
    var isTransmitted: Bool
}
