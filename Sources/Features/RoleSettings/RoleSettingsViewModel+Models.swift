import Foundation

// MARK: - State

extension RoleSettingsViewModel {
    struct State: Equatable {
        var role: AppRole = .unselected
        /// 是否曾經支持過。**只決定感謝徽章要不要出現**，不決定任何功能——
        /// 全 App 沒有第二個地方讀這個值。
        var hasSupported = false

        /// 支持入口只出現在照顧者端。患者端是眼控介面，把金錢決策放在
        /// 一個沒有能力承擔它的使用者面前，比誤觸更嚴重。
        var showsSponsorship: Bool { role == .caregiver }

        /// 編輯呼叫項目的入口只出現在**患者端**。
        ///
        /// 操作者仍然是照顧者——但格子的資料在患者的裝置上，呼叫也由那裡
        /// 發起。這個入口本身已被患者端設定的兩段確認保護著，患者自己
        /// 誤觸不到。
        var showsGridEditing: Bool { role == .patient }
    }
}

// MARK: - Action

extension RoleSettingsViewModel {
    enum Action: Sendable {
        case onAppear
        case switchRole
        case openSponsorship
        case openGridEditing
        /// 編輯畫面回報項目有變動。這一頁自己不用它，只負責往上傳——
        /// 真正要重載的是**這個 sheet 底下**的患者端格子。
        case gridItemsDidChange
    }
}

// MARK: - Router

extension RoleSettingsViewModel {
    enum Router: Sendable {
        /// 離開目前角色，回到首頁。導航與傳輸的停止都由 C 層轉交 AppRouter。
        case leaveRole
        /// 開啟支持開發者。
        case sponsorship
        /// 開啟編輯呼叫項目。
        case gridEditing
    }
}

// MARK: - Callback

extension RoleSettingsViewModel {
    enum Callback: Sendable {
        /// 呼叫項目有變動，底下的患者端格子需要重載。
        case gridItemsDidChange
    }
}
