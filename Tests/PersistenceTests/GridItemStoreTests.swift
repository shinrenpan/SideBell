import Foundation
import SwiftData
import Testing

@testable import SideBell

/// 明確標注 MainActor：`ModelContainer.mainContext` 只能在主 actor 上使用。
///
/// ⚠️ 容器由 suite 持有，不可放在輔助函式的區域變數裡。`ModelContext`
/// **不持有** `ModelContainer`——函式一返回容器就被回收，留下指向已死容器的
/// context，下次操作直接進 SwiftData 的斷言（EXC_BREAKPOINT，且不帶訊息）。
@Suite("格子儲存")
@MainActor
struct GridItemStoreTests {
    let container: ModelContainer
    let defaults: UserDefaults
    let store: GridItemStore

    init() throws {
        container = try ModelContainer(
            for: GridItemModel.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        defaults = UserDefaults(suiteName: "sidebell.tests.\(UUID().uuidString)")!
        store = GridItemStore(context: container.mainContext, defaults: defaults)
    }

    // MARK: - 儲存與順序

    /// spec: Items survive a restart
    @Test("寫入後可讀回")
    func persistsItems() throws {
        try store.insert(title: "喝水", commandCode: "WATER", isUrgent: false)

        let items = try store.allItems()
        #expect(items.count == 1)
        #expect(items.first?.title == "喝水")
    }

    /// spec: Order is preserved across launches
    ///
    /// 患者會記住每個按鈕的實體位置。順序若在啟動之間變動，
    /// 他建立起來的肌肉記憶與注視目標就失效了。
    @Test("依排序位置回傳，而非建立順序")
    func returnsItemsInSortOrder() throws {
        try store.insert(title: "第三", commandCode: "C", isUrgent: false, sortOrder: 2)
        try store.insert(title: "第一", commandCode: "A", isUrgent: false, sortOrder: 0)
        try store.insert(title: "第二", commandCode: "B", isUrgent: false, sortOrder: 1)

        #expect(try store.allItems().map(\.title) == ["第一", "第二", "第三"])
    }

    @Test("未指定順序時接續在最後")
    func appendsAfterLastPosition() throws {
        try store.insert(title: "第一", commandCode: "A", isUrgent: false, sortOrder: 0)
        try store.insert(title: "第二", commandCode: "B", isUrgent: false)

        #expect(try store.allItems().map(\.sortOrder) == [0, 1])
    }

    // MARK: - 驗證

    /// spec: validation cases —— 逐列對照
    @Test("內容須符合 wire format 限制", arguments: GridItemStoreTests.validationCases)
    func validatesContent(title: String, commandCode: String, shouldSucceed: Bool) throws {
        if shouldSucceed {
            try store.insert(title: title, commandCode: commandCode, isUrgent: false)
            #expect(try store.allItems().count == 1)
        } else {
            #expect(throws: GridItemError.self) {
                try store.insert(title: title, commandCode: commandCode, isUrgent: false)
            }
            // 驗證失敗時不得留下半成品。
            #expect(try store.allItems().isEmpty)
        }
    }

    nonisolated static let validationCases: [(String, String, Bool)] = [
        ("喝水", "WATER", true),
        (String(repeating: "A", count: 100), "HELP", true),
        (String(repeating: "A", count: 101), "HELP", false),
        ("喝水", "TOOLONGCODE", false),
        ("喝水", "喝水", false),
    ]

    // MARK: - 種子

    /// spec: First launch creates the defaults
    @Test("首次使用寫入四個預設格子")
    func seedsDefaultsOnFirstUse() throws {
        try store.seedDefaultsIfNeeded()

        // 以 `commandCode` 而非標題釘住內容：標題自本地化之後隨系統語言而定，
        // 寫死任何一種語言都會讓這個測試在別的語言下失敗。`commandCode` 是
        // 兩端對照用的識別碼，不翻譯，正是這裡該驗的東西。
        #expect(try store.allItems().map(\.commandCode) == ["WATER", "TURN", "TOILET", "PAIN"])
        #expect(try store.allItems().map(\.title) == GridItemStore.defaultItems.map(\.title))
    }

    /// spec: Deliberately emptied grid stays empty
    ///
    /// 以「空即種」為判準會讓「照顧者刻意清空格子」變成不可能。
    @Test("清空後不再重新種子")
    func doesNotReseedAfterDeliberateClear() throws {
        try store.seedDefaultsIfNeeded()
        try store.removeAll()

        // 模擬下次啟動：同一份 defaults，故種子旗標仍在。
        try store.seedDefaultsIfNeeded()

        #expect(try store.allItems().isEmpty)
        #expect(defaults.bool(forKey: GridItemStore.seededKey))
    }

    @Test("重複呼叫種子不會產生重複項目")
    func seedingIsIdempotent() throws {
        try store.seedDefaultsIfNeeded()
        try store.seedDefaultsIfNeeded()

        #expect(try store.allItems().count == 4)
    }
}
