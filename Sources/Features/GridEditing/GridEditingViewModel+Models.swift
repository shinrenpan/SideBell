import Foundation

// MARK: - State

extension GridEditingViewModel {
    struct State: Equatable {
        var items: [EditItem] = []
        /// 還能不能再加。**畫面據此事先停用新增入口**，而不是讓照顧者填完
        /// 名稱才被拒——那等於讓他白做一次工。
        var canAdd = true
        /// 這台裝置一屏放得下幾格。用於向照顧者說明為什麼不能再加。
        var itemLimit = 0
        /// 項目數已超過建議值。**這只是提示，不擋新增**——建議值那個數字
        /// 未附實證來源，用它擋等於替照顧者決定他家裡需要幾個項目。
        /// 該擋的是「患者看不到」，那由 `canAdd` 守住。
        var isCrowded = false
        /// 操作被拒的說法。使用者看不懂錯誤碼，畫面上唯一有用的資訊是
        /// 「怎麼改才對」。
        var failureMessage: String?
    }
}

// MARK: - Action

extension GridEditingViewModel {
    enum Action: Sendable {
        case onAppear
        /// 新增。只帶名稱——照顧者要填的是「換尿布」，不是一個八字元的代號，
        /// 也不是「這一項算不算緊急」。
        case add(String)
        case rename(UUID, String)
        /// 刪除。確認對話框在畫面上，這裡收到的已經是確認過的決定。
        case delete(UUID)
        case move(IndexSet, Int)
        case dismissFailure
    }
}

// MARK: - Callback

extension GridEditingViewModel {
    enum Callback: Sendable {
        /// 項目有變動。上層據此重載患者端的格子。
        case itemsDidChange
    }
}

// MARK: - Domain Models

extension GridEditingViewModel {
    /// 編輯清單的一列。與資料庫模型分開——UI 層不該持有資料庫物件。
    nonisolated struct EditItem: Identifiable, Equatable, Sendable {
        let id: UUID
        let title: String
        /// 受保護：沒有刪除入口、不能被拖動、永遠第一列。
        ///
        /// 直接沿用資料層的旗標，**不由標題或位置推斷**：照顧者可以把它
        /// 改名成任何字，而位置是保護的結果，不是原因。
        let isProtected: Bool
    }
}
