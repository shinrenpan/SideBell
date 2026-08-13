#if DEBUG
import Foundation

/// Preview 用的假 provider。不接觸真實金流。
private final class PreviewProvider: SponsorshipProviding {
    let plans: [SponsorshipPlan]
    let fails: Bool
    let hasSupported: Bool

    init(fails: Bool, hasSupported: Bool) {
        self.fails = fails
        self.hasSupported = hasSupported
        // 價格用台灣的實際定價，好在 Preview 上看出版面。
        let prices = ["NT$30", "NT$90", "NT$290"]
        plans = zip(SponsorshipProduct.allCases, prices).map {
            SponsorshipPlan(product: $0, displayPrice: $1)
        }
    }

    func loadPlans() async throws -> [SponsorshipPlan] {
        if fails { throw SponsorshipError.unavailable }
        return plans
    }

    func purchase(_ product: SponsorshipProduct) async throws -> SponsorshipPurchaseOutcome {
        .supported
    }
}

extension SponsorshipViewModel {
    static var mock: SponsorshipViewModel {
        SponsorshipViewModel(provider: PreviewProvider(fails: false, hasSupported: true))
    }

    static var offlineMock: SponsorshipViewModel {
        SponsorshipViewModel(provider: PreviewProvider(fails: true, hasSupported: false))
    }
}
#endif
