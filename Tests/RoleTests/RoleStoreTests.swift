import Foundation
import Testing

@testable import SideBell

@Suite("角色儲存")
struct RoleStoreTests {
    /// 每個測試用獨立 suite，避免污染 standard defaults。
    private func makeStore() -> (RoleStore, UserDefaults) {
        let suiteName = "sidebell.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return (RoleStore(defaults: defaults), defaults)
    }

    /// spec: No role selected yet
    @Test("首次啟動讀出未選擇")
    func defaultsToUnselected() {
        let (store, _) = makeStore()
        #expect(store.role == .unselected)
    }

    /// spec: Role is known at the earliest launch callback
    @Test("寫入後可讀回相同角色", arguments: [AppRole.patient, .caregiver, .unselected])
    func persistsRole(role: AppRole) {
        let (store, defaults) = makeStore()
        store.save(role)

        #expect(store.role == role)
        // 以同一份 defaults 重建 store，模擬下次啟動時的同步讀取。
        #expect(RoleStore(defaults: defaults).role == role)
    }

    @Test("儲存值毀損時退回未選擇而非崩潰")
    func corruptedValueFallsBackToUnselected() {
        let (store, defaults) = makeStore()
        defaults.set("not-a-role", forKey: RoleStore.storageKey)

        #expect(store.role == .unselected)
    }

    /// 未選擇角色時不得啟動傳輸層——傳輸層沒有「未選擇」這個概念。
    @Test("未選擇時沒有對應的傳輸角色")
    func unselectedHasNoTransportRole() {
        #expect(AppRole.unselected.transportRole == nil)
        #expect(AppRole.patient.transportRole == .patient)
        #expect(AppRole.caregiver.transportRole == .caregiver)
    }
}
