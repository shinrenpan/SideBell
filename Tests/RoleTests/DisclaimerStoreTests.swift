import Foundation
import Testing

@testable import SideBell

@Suite("免責聲明確認狀態")
struct DisclaimerStoreTests {
    /// 每個測試用獨立 suite，避免污染 standard defaults。
    private func makeStore() -> (DisclaimerStore, UserDefaults) {
        let suiteName = "sidebell.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return (DisclaimerStore(defaults: defaults), defaults)
    }

    /// spec: Roles are locked until acknowledged
    @Test("預設為未確認")
    func defaultsToUnacknowledged() {
        let (store, _) = makeStore()
        #expect(store.isAcknowledged == false)
    }

    /// spec: Acknowledgement is remembered
    @Test("確認後可讀回已確認")
    func persistsAcknowledgement() {
        let (store, defaults) = makeStore()
        store.acknowledge()

        #expect(store.isAcknowledged)
        // 以同一份 defaults 重建，模擬下次啟動時的同步讀取。
        #expect(DisclaimerStore(defaults: defaults).isAcknowledged)
    }

    /// 儲存值型別不符時必須退回未確認——猜「已確認」等於幫使用者
    /// 跳過一份法律聲明，那是絕不能自作主張的方向。
    @Test("儲存值型別不符時退回未確認")
    func wrongTypeFallsBackToUnacknowledged() {
        let (store, defaults) = makeStore()
        defaults.set("yes", forKey: DisclaimerStore.storageKey)

        #expect(store.isAcknowledged == false)
    }
}
