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

    init(
        id: UUID = UUID(),
        title: String,
        commandCode: String,
        isUrgent: Bool,
        sortOrder: Int
    ) {
        self.id = id
        self.title = title
        self.commandCode = commandCode
        self.isUrgent = isUrgent
        self.sortOrder = sortOrder
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
}
