import Foundation
import SwiftData

/// 患者端的一個呼叫格子。
///
/// 純本地儲存、不做雲端同步——符合離線定位，也讓健康相關內容維持
/// 最小足跡（spec 4）。
/// 本模組預設 MainActor 隔離，但 SwiftData 會在自己的 context 上操作模型
/// 物件——把模型綁在主 actor 上會在執行期崩潰。`@Model` 型別一律脫離隔離。
@Model
nonisolated final class GridItemModel {
    var id: UUID
    /// 給人看的標題，例如「喝水」。上限 100 位元組 UTF-8。
    ///
    /// 格子刻意**沒有圖示**。照顧者將來要能自行編輯格子，而圖示無法被編輯
    /// 出來：從幾千個 SF Symbols 裡挑是不合理的負擔，給小圖庫又必然涵蓋不到
    /// 真實需求（「換尿布」「抽痰」）。結果會是預設格子有圖、自訂格子沒圖的
    /// 不一致。標題本身還多一層——預設項目走翻譯，自訂項目是照顧者打的原文。
    /// 因此格子的識別完全交給文字，字級放大到足以在掃視中辨認。
    var title: String
    /// 機器可讀的指令代碼，上限 8 位元組 ASCII，例如 `WATER`。
    var commandCode: String
    /// 緊急呼叫。照顧者端據此決定是否重複警報直到確認。
    var isUrgent: Bool
    /// 顯示順序。患者會記住每個按鈕的實體位置，順序必須穩定。
    var sortOrder: Int
    /// 受保護：不可刪除，且永遠排在第一。可以改名。
    ///
    /// 保護狀態**只由這個欄位決定**，不得以標題文字或 `sortOrder` 推斷——
    /// 標題是照顧者可以改的（有些家庭說「不適」、有些說「快來」），
    /// 以文字判斷等於改名之後保護就失效；以位置判斷則是把結果當成原因。
    ///
    /// 存在的理由是患者：它是他唯一保證叫得到人的管道，而格子若被刪光，
    /// 他沒有能力自己補救。
    ///
    /// 既有安裝沒有這個欄位，SwiftData 的輕量遷移會填入 `false`。開發期間以
    /// 刪除 App 重裝處理；上架後若已有真實使用者，需要一次性的資料修正。
    /// **預設值寫在屬性上**是輕量遷移能自動完成的條件，缺了它舊資料庫會開不起來。
    var isProtected: Bool = false

    init(
        id: UUID = UUID(),
        title: String,
        commandCode: String,
        isUrgent: Bool,
        sortOrder: Int,
        isProtected: Bool = false
    ) {
        self.id = id
        self.title = title
        self.commandCode = commandCode
        self.isUrgent = isUrgent
        self.sortOrder = sortOrder
        self.isProtected = isProtected
    }
}

/// 格子內容不符 wire format 限制。
///
/// 刻意在**儲存時**拒絕而非送出時：等到患者按下按鈕才發現超長，
/// 失敗會發生在最不能失敗的時刻。
nonisolated enum GridItemError: Error, Equatable, Sendable {
    case titleTooLong(byteCount: Int, limit: Int)
    case commandCodeTooLong(byteCount: Int, limit: Int)
    case commandCodeNotASCII
    /// 標題只有空白或完全沒填。患者無法辨識一個沒有名字的格子。
    case titleEmpty
    /// 試圖刪除受保護的項目。
    ///
    /// **擲出錯誤而非靜默忽略**：靜默忽略會讓呼叫端以為刪成功了，
    /// 而這個 App 最致命的 bug 類型正是「畫面說成功、實際沒發生」。
    case cannotDeleteProtectedItem
    /// 連續產生代碼都撞到既有值。實務上不會發生（8 位 hex 有 43 億種可能，
    /// 而項目數是個位數），但**不靜默回傳可能重複的代碼**——重複的代碼會讓
    /// 照顧者端分不出兩種呼叫。
    case commandCodeUnavailable
}
