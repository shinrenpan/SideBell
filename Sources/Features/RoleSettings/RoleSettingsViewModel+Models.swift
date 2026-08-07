import Foundation

// MARK: - State

extension RoleSettingsViewModel {
    struct State: Equatable {
        var role: AppRole = .unselected
    }
}

// MARK: - Action

extension RoleSettingsViewModel {
    enum Action: Sendable {
        case onAppear
        case switchRole
    }
}

// MARK: - Router

extension RoleSettingsViewModel {
    enum Router: Sendable {
        /// 離開目前角色，回到首頁。導航與傳輸的停止都由 C 層轉交 AppRouter。
        case leaveRole
    }
}
