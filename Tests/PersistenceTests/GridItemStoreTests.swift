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
    ///
    /// 兩項而非四項：四個是替照顧者假設的需求（「翻身」對能走動的患者無用），
    /// 兩項是「到手就能用」的最小集合——一個保證叫得到人的管道，加一個示範
    /// 格子長什麼樣的日常需求。
    @Test("首次使用寫入兩個預設格子，受保護的那項在第一")
    func seedsDefaultsOnFirstUse() throws {
        try store.seedDefaultsIfNeeded()

        // 以 `commandCode` 而非標題釘住內容：標題自本地化之後隨系統語言而定，
        // 寫死任何一種語言都會讓這個測試在別的語言下失敗。`commandCode` 是
        // 兩端對照用的識別碼，不翻譯，正是這裡該驗的東西。
        #expect(try store.allItems().map(\.commandCode) == ["PAIN", "WATER"])
        #expect(try store.allItems().map(\.title) == GridItemStore.defaultItems.map(\.title))
        #expect(try store.allItems().map(\.isProtected) == [true, false])
        // 緊急只跟著受保護那一項，不是可設定的屬性。
        #expect(try store.allItems().map(\.isUrgent) == [true, false])
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

        #expect(try store.allItems().count == 2)
    }

    // MARK: - 編輯

    /// spec: Adding an item
    ///
    /// 照顧者只填名稱。`commandCode` 與順序由系統決定——他要填的是「換尿布」，
    /// 不是想一個八字元的英文代號。
    @Test("新增項目排在最後，代碼自動產生且唯一")
    func addsItemAtEndWithGeneratedCode() throws {
        try store.seedDefaultsIfNeeded()

        let added = try store.addItem(title: "抽痰")
        let items = try store.allItems()

        #expect(items.map(\.title).last == "抽痰")
        #expect(added.sortOrder == 2)
        #expect(!added.isProtected)
        // 新增的項目一律非緊急：緊急等級不開放設定。
        #expect(!added.isUrgent)

        let second = try store.addItem(title: "換尿布")
        #expect(second.commandCode != added.commandCode)
        // 代碼須進得了 wire format：8 位元組 ASCII 以內。
        #expect(second.commandCode.utf8.count <= CallMessageCodec.commandCodeSize)
        #expect(second.commandCode.utf8.allSatisfy { $0 < 0x80 })
        #expect(try Set(store.allItems().map(\.commandCode)).count == 4)
    }

    /// spec: Renaming an item
    @Test("改名後標題更新")
    func renamesItem() throws {
        try store.seedDefaultsIfNeeded()
        let item = try #require(try store.allItems().last)

        try store.updateTitle(of: item, to: "喝溫水")

        #expect(try store.allItems().map(\.title).last == "喝溫水")
    }

    /// spec: The protected item can be renamed（Example: a household that says it differently）
    ///
    /// 保護的是「永遠有一個緊急求助鍵」，不是那三個字。
    @Test("受保護項目可以改名，改名後仍受保護")
    func protectedItemStaysProtectedAfterRename() throws {
        try store.seedDefaultsIfNeeded()
        let protected = try #require(try store.allItems().first)

        try store.updateTitle(of: protected, to: "快來")

        let first = try #require(try store.allItems().first)
        #expect(first.title == "快來")
        #expect(first.isProtected)
        #expect(throws: GridItemError.cannotDeleteProtectedItem) {
            try store.delete(first)
        }
    }

    /// spec: Deleting an item
    @Test("刪除非受保護項目")
    func deletesUnprotectedItem() throws {
        try store.seedDefaultsIfNeeded()
        let water = try #require(try store.allItems().last)

        try store.delete(water)

        #expect(try store.allItems().map(\.commandCode) == ["PAIN"])
    }

    /// spec: The grid cannot be emptied
    ///
    /// UI 上沒有刪除入口，這條路徑照理不會被走到。**資料層仍要把關**：
    /// UI 的保護是體驗，資料層的保護才是保證——患者沒有能力自己補救一片空白。
    @Test("刪除受保護項目會失敗，且項目仍在")
    func refusesToDeleteProtectedItem() throws {
        try store.seedDefaultsIfNeeded()
        let protected = try #require(try store.allItems().first)

        #expect(throws: GridItemError.cannotDeleteProtectedItem) {
            try store.delete(protected)
        }
        let remaining = try store.allItems()
        #expect(remaining.contains { $0.isProtected })
    }

    /// spec: The protected item stays first
    ///
    /// 判斷保護狀態只讀旗標，不看標題或位置——否則改名之後保護就失效了。
    @Test("重新排序後受保護項目仍在第一")
    func keepsProtectedItemFirstAfterReorder() throws {
        try store.seedDefaultsIfNeeded()
        try store.addItem(title: "抽痰")

        // 刻意把受保護的那項排到最後，模擬 UI 邊界情況漏擋的後果。
        let items = try store.allItems()
        try store.reorder(Array(items.dropFirst()) + [items[0]])

        let reordered = try store.allItems()
        #expect(reordered.first?.isProtected == true)
        #expect(reordered.map(\.sortOrder) == [0, 1, 2])
        // 受保護的被拉回第一，其餘維持傳入的相對順序。
        #expect(reordered[1].commandCode == "WATER")
        #expect(reordered[2].title == "抽痰")
    }

    /// spec: A name that cannot be carried
    @Test("空白標題被拒", arguments: ["", " ", "\n  "])
    func refusesBlankTitle(title: String) throws {
        #expect(throws: GridItemError.titleEmpty) {
            try store.addItem(title: title)
        }
        #expect(try store.allItems().isEmpty)
    }

    @Test("超過 100 位元組的標題被拒")
    func refusesOverlongTitleOnAdd() throws {
        #expect(throws: GridItemError.self) {
            try store.addItem(title: String(repeating: "A", count: 101))
        }
        #expect(try store.allItems().isEmpty)
    }

    @Test("改名同樣受標題驗證把關")
    func validatesTitleOnRename() throws {
        try store.seedDefaultsIfNeeded()
        let item = try #require(try store.allItems().last)

        #expect(throws: GridItemError.titleEmpty) {
            try store.updateTitle(of: item, to: "  ")
        }
        #expect(throws: GridItemError.self) {
            try store.updateTitle(of: item, to: String(repeating: "A", count: 101))
        }
        // 拒絕之後標題不得只改一半。
        #expect(try store.allItems().map(\.commandCode).last == "WATER")
    }
}
