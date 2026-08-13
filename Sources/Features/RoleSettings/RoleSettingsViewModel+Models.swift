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
    }
}

// MARK: - Action

extension RoleSettingsViewModel {
    enum Action: Sendable {
        case onAppear
        case switchRole
        case openSponsorship
    }
}

// MARK: - Router

extension RoleSettingsViewModel {
    enum Router: Sendable {
        /// 離開目前角色，回到首頁。導航與傳輸的停止都由 C 層轉交 AppRouter。
        case leaveRole
        /// 開啟支持開發者。
        case sponsorship
    }
}
