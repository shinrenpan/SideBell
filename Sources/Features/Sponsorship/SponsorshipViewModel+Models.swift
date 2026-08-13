import Foundation

// MARK: - State

extension SponsorshipViewModel {
    struct State: Equatable {
        var plans: [SponsorshipPlan] = []
        var isLoading = false
        /// 方案載不進來。**這與「還沒載完」必須分得開**：兩者都是空清單，
        /// 但前者要說明原因並給重試，後者只要等。分不開的後果是使用者
        /// 盯著一個永遠不會變的畫面。
        var needsNetwork = false
        /// 購買失敗的說法。使用者取消時**必須是 nil**——那是他的決定，
        /// 跳出錯誤訊息像是在責備他。
        var purchaseFailureMessage: String?
        /// 是否曾經支持過。只決定感謝徽章要不要出現，不決定任何功能。
        var hasSupported = false
        /// 購買進行中的方案。用來停用重複點擊，不是用來擋重複購買——
        /// 同一方案本來就可以買很多次。
        var purchasingProduct: SponsorshipProduct?

        var isPurchasing: Bool { purchasingProduct != nil }
    }
}

// MARK: - Action

extension SponsorshipViewModel {
    enum Action: Sendable {
        case onAppear
        case purchase(SponsorshipProduct)
        case retry
        case dismissFailure
    }
}
