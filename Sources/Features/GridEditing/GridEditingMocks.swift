#if DEBUG
import Foundation
import SwiftData

extension GridEditingViewModel {
    /// Preview 用。走**記憶體內的真實 store**，不另寫一個假的——這一頁的行為
    /// 幾乎都是資料層的規則（受保護不可刪、排序後仍在第一），假的 store
    /// 若沒把規則抄一遍，Preview 看到的就不是真的樣子。
    @MainActor
    static var mock: GridEditingViewModel {
        make(itemLimit: 6)
    }

    /// 已達上限的樣子：新增入口該是停用的。
    @MainActor
    static var atLimitMock: GridEditingViewModel {
        make(itemLimit: 2)
    }

    @MainActor
    private static func make(itemLimit: Int) -> GridEditingViewModel {
        let container = try! ModelContainer(
            for: GridItemModel.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let store = GridItemStore(
            context: container.mainContext,
            defaults: UserDefaults(suiteName: "sidebell.preview.\(UUID().uuidString)")!
        )
        try? store.seedDefaultsIfNeeded()

        return GridEditingViewModel(store: store, itemLimit: itemLimit)
    }
}
#endif
