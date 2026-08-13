import Foundation
import RevenueCat

/// 一個可購買的支持方案：方案本身，加上 App Store 依使用者地區給出的價格。
nonisolated struct SponsorshipPlan: Identifiable, Equatable, Sendable {
    let product: SponsorshipProduct
    /// 已在地化的價格字串，直接取自 App Store。**不自行格式化**：貨幣符號、
    /// 小數位、千分位在各地區都不同，自己拼出來的數字遲早會與使用者實際
    /// 被扣的金額不一致。
    let displayPrice: String

    var id: String { product.id }
}

/// 購買結束時的兩種去向。
///
/// 取消**不是錯誤**，因此不以 throw 表達：那會逼呼叫端從錯誤裡挑出「其實
/// 沒事」的那一種，而漏挑的後果是對著使用者的決定跳出錯誤訊息。
nonisolated enum SponsorshipPurchaseOutcome: Sendable {
    case supported
    case cancelled
}

/// 贊助頁需要的三個操作。
///
/// 存在的理由是**測試**：真實金流在單元測試裡無法穩定重現「使用者取消」與
/// 「商店不可用」，而那兩條路徑正是最需要驗的判斷。
protocol SponsorshipProviding {
    func loadPlans() async throws -> [SponsorshipPlan]
    func purchase(_ product: SponsorshipProduct) async throws -> SponsorshipPurchaseOutcome
    /// 是否曾經支持過。只用來決定要不要顯示感謝徽章。
    var hasSupported: Bool { get }
}

/// 方案的載入與購買，以及「曾經支持過」這個本機旗標。
///
/// **RevenueCat 的型別到此為止**，不會出現在 View 或 ViewModel 裡。日後若
/// 更換金流方案，改動範圍就是這個檔案。
final class SponsorshipStore: SponsorshipProviding {
    /// 與角色設定同層儲存。
    static let supportedKey = "com.shinrenpan.sidebell.hasSupported"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
}

// MARK: - 讀取

extension SponsorshipStore {
    /// 感謝徽章**只讀本機旗標，不向 RevenueCat 查詢購買歷史**。
    ///
    /// 理由是離線：照顧者可能長期不連網，而向伺服器查詢會讓徽章在離線時
    /// 消失——付了錢卻看不到感謝，比不顯示徽章更糟。
    ///
    /// 代價是換裝置後徽章不會跟著走。可以接受：它是裝飾，不是資產。
    var hasSupported: Bool {
        defaults.bool(forKey: Self.supportedKey)
    }

    /// 取得三個方案與其在地化價格。
    ///
    /// 依 `allCases` 的順序回傳，不用 App Store 的回傳順序——後者不保證穩定，
    /// 而金額由小到大排列是使用者理解這一頁的方式。
    func loadPlans() async throws -> [SponsorshipPlan] {
        let storeProducts = try await fetchProducts(SponsorshipProduct.allCases)
        let priceByIdentifier = Dictionary(
            storeProducts.map { ($0.productIdentifier, $0.localizedPriceString) },
            uniquingKeysWith: { first, _ in first }
        )

        let plans = SponsorshipProduct.allCases.compactMap { product in
            priceByIdentifier[product.identifier].map {
                SponsorshipPlan(product: product, displayPrice: $0)
            }
        }

        // 全部拿不到才算失敗——那通常是沒網路。少數缺漏則照樣呈現拿得到的
        // 那幾個：那是 App Store Connect 的設定問題，讓使用者看到一片「需要
        // 網路」只會把他導向錯誤的排除方向，而少一個方案不影響他支持。
        guard !plans.isEmpty else { throw SponsorshipError.unavailable }
        if plans.count != SponsorshipProduct.allCases.count {
            SideBellLog.transport.error(
                "支持方案缺漏 取得=\(plans.count) 應有=\(SponsorshipProduct.allCases.count)"
            )
        }
        return plans
    }
}

// MARK: - 購買

extension SponsorshipStore {
    /// 購買某一方案。
    ///
    /// 同一方案**可重複購買**：它們是消耗性商品，每次都是獨立的支持，
    /// 不是「已擁有」的內容。
    func purchase(_ product: SponsorshipProduct) async throws -> SponsorshipPurchaseOutcome {
        let storeProducts = try await fetchProducts([product])
        guard let storeProduct = storeProducts.first else {
            throw SponsorshipError.unavailable
        }

        do {
            let result = try await Purchases.shared.purchase(product: storeProduct)
            guard !result.userCancelled else { return .cancelled }
        } catch let error as RevenueCat.ErrorCode where error == .purchaseCancelledError {
            // 取消在 SDK 裡有兩種表達方式：回傳值的 `userCancelled`，以及丟出
            // 這個錯誤碼。只接其中一種，另一種就會被當成真正的失敗而對著
            // 使用者的決定跳出錯誤訊息。
            return .cancelled
        }

        markSupported()
        return .supported
    }
}

// MARK: - 私有

private extension SponsorshipStore {
    /// 向 App Store 取得商品。
    ///
    /// SDK 未設定時**先擋下來**：`Purchases.shared` 在未設定時會直接中止程式，
    /// 而缺少 API key 是設定問題，不該讓 App 崩潰——尤其這個 App 的核心是
    /// 呼叫與警報，與金流毫無關係。
    func fetchProducts(_ products: [SponsorshipProduct]) async throws -> [StoreProduct] {
        guard SponsorshipConfiguration.isConfigured else {
            throw SponsorshipError.unavailable
        }
        return await Purchases.shared.products(products.map(\.identifier))
    }

    /// 記下「曾經支持過」。
    ///
    /// 寫入失敗不重試也不提示：那筆交易在 App Store 已經成立，而徽章只是
    /// 裝飾。為了裝飾去打擾一個剛剛付過錢的人，是本末倒置。
    func markSupported() {
        defaults.set(true, forKey: Self.supportedKey)
    }
}

// MARK: - 錯誤

/// 贊助頁自己的錯誤型別。
///
/// SDK 的原始錯誤不外流：使用者看不懂錯誤碼，而畫面上唯一有用的資訊是
/// 「還能不能重試」。
nonisolated enum SponsorshipError: Error {
    /// 方案取不到。通常是沒有網路，也可能是商店暫時不可用或尚未設定 API key。
    case unavailable
}
