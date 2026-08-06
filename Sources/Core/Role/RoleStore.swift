import Foundation

/// 角色設定的持久化。
///
/// 刻意用 UserDefaults 而非 SwiftData：角色必須能在
/// `application(_:didFinishLaunchingWithOptions:)` 中**同步**讀出，
/// 才能決定要重建哪一端的 Bluetooth manager。若放資料庫，開機最早期
/// 得先載入 container 才知道角色，而那正是背景復活最不能拖的地方。
/// 不宣告 `Sendable`：`UserDefaults` 並非 Sendable，而本型別只在啟動回呼
/// 與設定頁使用，不跨 actor 傳遞——硬套 `@unchecked Sendable` 只是掩蓋事實。
nonisolated struct RoleStore {
    static let storageKey = "com.shinrenpan.sidebell.role"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// 目前角色。未曾寫入或值毀損時一律回 `.unselected`——
    /// 猜一個角色比沒有角色更危險：患者端會誤以為自己在廣播。
    var role: AppRole {
        guard let raw = defaults.string(forKey: Self.storageKey) else { return .unselected }
        return AppRole(rawValue: raw) ?? .unselected
    }

    func save(_ role: AppRole) {
        defaults.set(role.rawValue, forKey: Self.storageKey)
    }
}
