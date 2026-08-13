import Foundation

/// 支持開發者。
///
/// **這一頁是全 App 唯一需要網路的畫面**，而它的失敗不得影響任何其他地方——
/// 呼叫、警報、確認都不查詢網路狀態，也不查詢購買狀態。
@Observable
final class SponsorshipViewModel {
    var state: State = .init()

    @ObservationIgnored private let provider: any SponsorshipProviding

    /// 以協定注入而非具體型別：真實金流在單元測試裡無法穩定重現
    /// 「使用者取消」與「商店不可用」，而那兩條正是最需要驗的路徑。
    init(provider: any SponsorshipProviding) {
        self.provider = provider
    }

    func doAction(_ action: Action) async {
        switch action {
        case .onAppear:
            state.hasSupported = provider.hasSupported
            await loadPlans()

        case .retry:
            await loadPlans()

        case let .purchase(product):
            await purchase(product)

        case .dismissFailure:
            state.purchaseFailureMessage = nil
        }
    }
}

// MARK: - 私有

private extension SponsorshipViewModel {
    func loadPlans() async {
        state.isLoading = true
        state.needsNetwork = false

        do {
            state.plans = try await provider.loadPlans()
        } catch {
            // 失敗時**清空清單並標記需要網路**，不留著上一次的價格：那些數字
            // 可能已經過期，而使用者會照著它決定要付多少。
            state.plans = []
            state.needsNetwork = true
        }

        state.isLoading = false
    }

    func purchase(_ product: SponsorshipProduct) async {
        guard state.purchasingProduct == nil else { return }
        state.purchasingProduct = product
        state.purchaseFailureMessage = nil

        do {
            let outcome = try await provider.purchase(product)
            switch outcome {
            case .supported:
                state.hasSupported = true
            case .cancelled:
                // 什麼都不做。取消是使用者的決定，不留下任何痕跡。
                break
            }
        } catch {
            // 原始錯誤不外流：使用者看不懂錯誤碼，而畫面上唯一有用的資訊
            // 是「還能不能重試」。
            state.purchaseFailureMessage = String(
                localized: "The purchase did not go through. Please try again."
            )
        }

        state.purchasingProduct = nil
    }
}
