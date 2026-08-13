import Foundation

/// 三個支持方案。
///
/// 識別碼寫死在程式裡，**不從遠端取得**：遠端設定的商品清單需要一個後端，
/// 而本 App 沒有、也不打算有。商品變動時重新送審是可接受的成本，它們不會常變。
///
/// **這裡只有識別碼**。名稱、用途說明與價格全部由 App Store 依使用者所在地區
/// 提供：價格寫死會在其他地區顯示錯誤的金額，而文案寫死會與 App Store 商品頁
/// 和系統購買 sheet 各說各話——那兩個地方我們改不動，只能讓這一頁跟著它們走。
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
