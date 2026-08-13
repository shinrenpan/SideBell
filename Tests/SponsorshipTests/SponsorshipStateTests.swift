import Foundation
import Testing

@testable import SideBell

/// 贊助畫面的狀態機。
///
/// **完全不接觸真實金流**：以假的 provider 驅動，因此可以在單元測試裡表達
/// 「使用者取消」與「商店不可用」這兩種在沙盒環境下難以穩定重現的路徑。
/// 沙盒測試留給實機驗證清單，那裡驗的是接線；這裡驗的是判斷。
@MainActor
struct SponsorshipStateTests {
    /// 假的方案來源。回傳什麼由每個測試自己決定。
    final class FakeProvider: SponsorshipProviding {
        var plans: [SponsorshipPlan] = SponsorshipProduct.allCases.map {
            SponsorshipPlan(
                product: $0,
                title: "請開發者喝杯咖啡",
                detail: "小額隨喜，支持無障礙技術的持續研發。",
                displayPrice: "NT$30"
            )
        }
        var loadError: (any Error)?
        var purchaseOutcome: SponsorshipPurchaseOutcome = .supported
        var purchaseError: (any Error)?
        private(set) var hasSupported = false

        func loadPlans() async throws -> [SponsorshipPlan] {
            if let loadError { throw loadError }
            return plans
        }

        func purchase(_ product: SponsorshipProduct) async throws -> SponsorshipPurchaseOutcome {
            if let purchaseError { throw purchaseError }
            if purchaseOutcome == .supported { hasSupported = true }
            return purchaseOutcome
        }
    }

    /// 非取消的購買失敗。內容刻意像 SDK 的原始錯誤，用來確認它不會外洩到畫面上。
    struct StoreUnavailable: Error {}

    let provider = FakeProvider()
    var viewModel: SponsorshipViewModel { SponsorshipViewModel(provider: provider) }
}

// MARK: - 載入

extension SponsorshipStateTests {
    /// spec: The support screen lists what the money is for
    @Test("載入成功後三個方案皆呈現")
    func showsAllPlansAfterLoading() async {
        let viewModel = viewModel

        await viewModel.doAction(.onAppear)

        #expect(viewModel.state.plans.count == 3)
        #expect(viewModel.state.plans.map(\.product) == SponsorshipProduct.allCases)
        #expect(viewModel.state.needsNetwork == false)
    }

    /// spec: The support screen states plainly when it needs a network
    ///
    /// 判準是**不能只是空清單**。空清單與「還沒載完」對使用者長得一樣，
    /// 而他會一直等下去。
    @Test("載入失敗時呈現需要網路且可重試，而不是空清單")
    func statesNetworkNeedInsteadOfEmptyList() async {
        provider.loadError = StoreUnavailable()
        let viewModel = viewModel

        await viewModel.doAction(.onAppear)

        #expect(viewModel.state.plans.isEmpty)
        #expect(viewModel.state.needsNetwork)
        #expect(viewModel.state.isLoading == false)
    }

    @Test("重試會重新載入，成功後不再顯示需要網路")
    func retryReloads() async {
        provider.loadError = StoreUnavailable()
        let viewModel = viewModel
        await viewModel.doAction(.onAppear)
        #expect(viewModel.state.needsNetwork)

        provider.loadError = nil
        await viewModel.doAction(.retry)

        #expect(viewModel.state.plans.count == 3)
        #expect(viewModel.state.needsNetwork == false)
    }
}

// MARK: - 購買

extension SponsorshipStateTests {
    /// spec: Cancelling is not an error
    ///
    /// 取消是使用者的決定。跳出錯誤訊息像是在責備他。
    @Test("使用者取消不產生任何錯誤訊息")
    func cancellingLeavesNoError() async {
        provider.purchaseOutcome = .cancelled
        let viewModel = viewModel
        await viewModel.doAction(.onAppear)

        await viewModel.doAction(.purchase(.small))

        #expect(viewModel.state.purchaseFailureMessage == nil)
        #expect(viewModel.state.hasSupported == false)
    }

    @Test("其他失敗產生可讀訊息，且不含原始錯誤內容")
    func otherFailuresProduceReadableMessage() async {
        provider.purchaseError = StoreUnavailable()
        let viewModel = viewModel
        await viewModel.doAction(.onAppear)

        await viewModel.doAction(.purchase(.medium))

        let message = viewModel.state.purchaseFailureMessage
        #expect(message?.isEmpty == false)
        #expect(message?.contains("StoreUnavailable") == false)
    }

    @Test("關閉提示後訊息消失")
    func dismissingClearsMessage() async {
        provider.purchaseError = StoreUnavailable()
        let viewModel = viewModel
        await viewModel.doAction(.onAppear)
        await viewModel.doAction(.purchase(.medium))
        #expect(viewModel.state.purchaseFailureMessage != nil)

        await viewModel.doAction(.dismissFailure)

        #expect(viewModel.state.purchaseFailureMessage == nil)
    }

    /// spec: Thanks is decoration, not a benefit
    @Test("購買成功後標記為已支持")
    func marksSupportedAfterPurchase() async {
        let viewModel = viewModel
        await viewModel.doAction(.onAppear)
        #expect(viewModel.state.hasSupported == false)

        await viewModel.doAction(.purchase(.large))

        #expect(viewModel.state.hasSupported)
        #expect(viewModel.state.purchaseFailureMessage == nil)
    }

    /// spec: Supporting more than once
    ///
    /// 同一方案可重複購買，每次都是獨立的支持——不是「已擁有」的商品。
    @Test("同一方案可重複購買，不被阻擋")
    func allowsRepeatedPurchaseOfSamePlan() async {
        let viewModel = viewModel
        await viewModel.doAction(.onAppear)

        await viewModel.doAction(.purchase(.small))
        await viewModel.doAction(.purchase(.small))

        #expect(viewModel.state.hasSupported)
        #expect(viewModel.state.purchaseFailureMessage == nil)
    }
}
