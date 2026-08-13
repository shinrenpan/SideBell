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
        // 第一筆照 App Store Connect 上的實際設定，另外兩筆是**長度相近的佔位**
        // ——Preview 要驗的是版面（說明多長會撐擠這一列），不是文案本身。
        // 真正的文案在商店那邊，這裡寫什麼都不會影響正式畫面。
        let entries = [
            ("請開發者喝杯咖啡", "小額隨喜，支持無障礙技術的持續研發。", "NT$30"),
            ("請開發者吃頓飯", "中額隨喜，支持無障礙技術的持續研發。", "NT$90"),
            ("請開發者休息一天", "大額隨喜，支持無障礙技術的持續研發。", "NT$290"),
        ]
        plans = zip(SponsorshipProduct.allCases, entries).map {
            SponsorshipPlan(product: $0, title: $1.0, detail: $1.1, displayPrice: $1.2)
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
