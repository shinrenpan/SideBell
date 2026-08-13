import Foundation

/// 三個支持方案。
///
/// 識別碼寫死在程式裡，**不從遠端取得**：遠端設定的商品清單需要一個後端，
/// 而本 App 沒有、也不打算有。商品變動時重新送審是可接受的成本，它們不會常變。
///
/// **價格不在這裡**。價格由 App Store 依使用者所在地區提供，寫死會在其他地區
/// 顯示錯誤的金額——那是使用者要付錢的數字，不能猜。
nonisolated enum SponsorshipProduct: String, CaseIterable, Identifiable, Sendable {
    case small = "com.shinrenpan.sidebell.tip.small"
    case medium = "com.shinrenpan.sidebell.tip.medium"
    case large = "com.shinrenpan.sidebell.tip.large"

    /// App Store Connect 上的商品識別碼。與 `rawValue` 相同，另外命名是為了
    /// 讓呼叫端讀起來知道它跨越了系統邊界。
    ///
    /// **必須是含 bundle ID 前綴的完整商品 ID**，因為 `Purchases.products(_:)`
    /// 收的是 App Store 的 product ID，不是 RevenueCat 自己的 lookup key。
    /// 前綴漏掉時 SDK 回傳空陣列，`loadPlans()` 會一路走到「需要網路」——
    /// 錯誤訊息完全指不到真正的原因（設定不符），是最難查的一種失敗。
    var identifier: String { rawValue }

    var id: String { rawValue }
}

// MARK: - 用途

extension SponsorshipProduct {
    /// 這筆錢會變成什麼。
    ///
    /// 刻意寫**具體的用途**而不是抽象的支持程度（「小小支持／大力支持」）：
    /// 後者只是把金額換句話說，使用者無從判斷自己的錢去了哪裡。
    ///
    /// 以 App Store 開發者帳號的年費（US$99）換算，數字是誠實的。
    /// **不承諾捐贈比例**——那是無法驗證的承諾，而本 App 的整個定位建立在
    /// 「畫面宣稱的能力必須等於實際能力」之上，文案不該是例外。
    var purpose: String {
        switch self {
        case .small:
            String(localized: "Keeps SideBell on the App Store for about four days.")
        case .medium:
            String(localized: "Keeps SideBell on the App Store for about ten days.")
        case .large:
            String(localized: "Keeps SideBell on the App Store for about a month.")
        }
    }
}
