import Foundation

/// 免責聲明是否已被使用者主動確認。
///
/// 與 `RoleStore` 同層、同理由：這個值必須能在場景配置時**同步**讀出，
/// 才能決定首頁要不要顯示確認控制項。為此不值得載入資料庫。
///
/// spec 9.3 要求免責聲明於首次啟動明示。這裡記錄的是「使用者曾主動確認」
/// 這件事本身——在延誤緊急求助的情境下，它與「聲明有印在畫面上」是
/// 完全不同重量的兩件事。
nonisolated struct DisclaimerStore {
    static let storageKey = "com.shinrenpan.sidebell.disclaimerAcknowledged"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// 是否已確認。
    ///
    /// 任何非預期的儲存內容一律視為未確認：猜「已確認」等於代替使用者
    /// 跳過一份法律聲明，那是絕不能自作主張的方向。
    var isAcknowledged: Bool {
        defaults.object(forKey: Self.storageKey) as? Bool ?? false
    }

    func acknowledge() {
        defaults.set(true, forKey: Self.storageKey)
    }
}
