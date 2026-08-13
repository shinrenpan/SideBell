import Foundation
import SwiftData
import Testing

@testable import SideBell

/// 編輯呼叫項目的狀態機。
///
/// 以**記憶體內的真實 `GridItemStore`** 驅動，而不是另寫一個假的：這一頁的
/// 判斷幾乎全部落在資料層的規則上（受保護項目不可刪、排序後仍在第一、
/// 標題驗證），而假的 store 若沒把那些規則抄一遍就測不到它們，抄了又會與
/// 真實實作漂移。金流那邊需要假的 provider 是因為真實購買無法重現「取消」；
/// SwiftData 的記憶體容器沒有這個問題。
///
/// ⚠️ 容器由 suite 持有，不可放在輔助函式的區域變數裡（見 GridItemStoreTests）。
@Suite("格子編輯狀態")
@MainActor
struct GridEditingStateTests {
    let container: ModelContainer
    let store: GridItemStore

    init() throws {
        container = try ModelContainer(
            for: GridItemModel.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        store = GridItemStore(
            context: container.mainContext,
            defaults: UserDefaults(suiteName: "sidebell.tests.\(UUID().uuidString)")!
        )
    }

    /// 種下預設兩項，回傳已載入的 ViewModel。
    private func makeViewModel(
        itemLimit: Int = 6,
        recommendedItemLimit: Int = 6
    ) async throws -> GridEditingViewModel {
        try store.seedDefaultsIfNeeded()
        let viewModel = GridEditingViewModel(
            store: store,
            itemLimit: itemLimit,
            recommendedItemLimit: recommendedItemLimit
        )
        await viewModel.doAction(.onAppear)
        return viewModel
    }
}

// MARK: - 載入

extension GridEditingStateTests {
    /// spec: The protected item stays first
    @Test("載入後依序呈現所有項目，受保護者在第一")
    func listsItemsWithProtectedFirst() async throws {
        let viewModel = try await makeViewModel()

        #expect(viewModel.state.items.count == 2)
        #expect(viewModel.state.items.first?.isProtected == true)
        #expect(viewModel.state.items.last?.isProtected == false)
    }
}

// MARK: - 新增

extension GridEditingStateTests {
    /// spec: Adding an item
    @Test("新增後清單增加一列，排在最後")
    func addAppendsRow() async throws {
        let viewModel = try await makeViewModel()

        await viewModel.doAction(.add("抽痰"))

        #expect(viewModel.state.items.count == 3)
        #expect(viewModel.state.items.last?.title == "抽痰")
        #expect(viewModel.state.failureMessage == nil)
    }

    /// spec: The limit is reached
    ///
    /// 判準不只是「新增被拒」，而是**狀態要能讓畫面事先停用入口**：讓照顧者
    /// 填完名稱才被拒，等於讓他白做一次工。
    @Test("達上限時新增被拒，且狀態可供畫面停用入口")
    func refusesAddAtLimit() async throws {
        let viewModel = try await makeViewModel(itemLimit: 3)

        await viewModel.doAction(.add("抽痰"))
        #expect(viewModel.state.canAdd == false)

        await viewModel.doAction(.add("換尿布"))

        #expect(viewModel.state.items.count == 3)
        #expect(viewModel.state.failureMessage != nil)
    }

    /// 建議值那個數字自承沒有實證來源（`DECISIONS.md` 2026-08-08），
    /// 拿它硬擋等於替照顧者決定他家裡需要幾個項目——而他才是知道患者需要
    /// 什麼的人。該擋的是「患者看不到」，那由硬上限守住。
    @Test("超過建議值只提示，不擋新增")
    func warnsButStillAllowsAddingBeyondRecommendation() async throws {
        let viewModel = try await makeViewModel(itemLimit: 8, recommendedItemLimit: 3)
        #expect(!viewModel.state.isCrowded)

        await viewModel.doAction(.add("抽痰"))

        #expect(viewModel.state.isCrowded)
        // 關鍵：提示出現了，但新增沒有被擋下。
        #expect(viewModel.state.canAdd)
        #expect(viewModel.state.failureMessage == nil)

        await viewModel.doAction(.add("換尿布"))
        #expect(viewModel.state.items.count == 4)
        #expect(viewModel.state.failureMessage == nil)
    }

    /// spec: Making room
    @Test("刪掉一項後又能新增")
    func addBecomesAvailableAfterDelete() async throws {
        let viewModel = try await makeViewModel(itemLimit: 2)
        #expect(viewModel.state.canAdd == false)

        let deletable = try #require(viewModel.state.items.last)
        await viewModel.doAction(.delete(deletable.id))

        #expect(viewModel.state.canAdd)
    }
}

// MARK: - 改名

extension GridEditingStateTests {
    /// spec: Renaming an item
    @Test("改名後該列更新")
    func renameUpdatesRow() async throws {
        let viewModel = try await makeViewModel()
        let target = try #require(viewModel.state.items.last)

        await viewModel.doAction(.rename(target.id, "喝溫水"))

        #expect(viewModel.state.items.last?.title == "喝溫水")
    }

    /// spec: The protected item can be renamed
    @Test("受保護項目改名後仍受保護，仍在第一")
    func renamedProtectedItemStaysProtected() async throws {
        let viewModel = try await makeViewModel()
        let protected = try #require(viewModel.state.items.first)

        await viewModel.doAction(.rename(protected.id, "快來"))

        let first = try #require(viewModel.state.items.first)
        #expect(first.title == "快來")
        #expect(first.isProtected)
    }
}

// MARK: - 刪除

extension GridEditingStateTests {
    /// spec: Deleting an item
    @Test("刪除後該列消失")
    func deleteRemovesRow() async throws {
        let viewModel = try await makeViewModel()
        let target = try #require(viewModel.state.items.last)

        await viewModel.doAction(.delete(target.id))

        #expect(viewModel.state.items.count == 1)
        #expect(viewModel.state.items.first?.isProtected == true)
    }

    /// spec: The protected item cannot be deleted
    ///
    /// 畫面上沒有刪除入口，這條路徑照理走不到；仍要驗，因為**患者沒有能力
    /// 自己補救一片空白的格子**。
    @Test("受保護項目刪不掉，且不留下錯誤訊息以外的痕跡")
    func deleteProtectedItemFails() async throws {
        let viewModel = try await makeViewModel()
        let protected = try #require(viewModel.state.items.first)

        await viewModel.doAction(.delete(protected.id))

        #expect(viewModel.state.items.count == 2)
        #expect(viewModel.state.items.first?.isProtected == true)
    }
}

// MARK: - 排序

extension GridEditingStateTests {
    /// spec: The protected item stays first
    @Test("把項目拖到第一之前，受保護者仍在第一")
    func moveKeepsProtectedFirst() async throws {
        let viewModel = try await makeViewModel()
        await viewModel.doAction(.add("抽痰"))

        // 嘗試把最後一項搬到最前面。
        await viewModel.doAction(.move(IndexSet(integer: 2), 0))

        #expect(viewModel.state.items.first?.isProtected == true)
    }

    @Test("非受保護項目之間可以互換順序")
    func moveReordersUnprotectedItems() async throws {
        let viewModel = try await makeViewModel()
        await viewModel.doAction(.add("抽痰"))
        let titlesBefore = viewModel.state.items.map(\.title)

        // 把第三項搬到第二項之前。
        await viewModel.doAction(.move(IndexSet(integer: 2), 1))

        #expect(viewModel.state.items.map(\.title) != titlesBefore)
        #expect(viewModel.state.items[1].title == "抽痰")
        #expect(viewModel.state.items.first?.isProtected == true)
    }
}

// MARK: - 標題驗證

extension GridEditingStateTests {
    /// spec: A name that cannot be carried
    ///
    /// 拒絕發生在**編輯當下**，不是等患者按下格子才發現。
    @Test("空白與超長標題產生可讀訊息", arguments: ["", "   ", String(repeating: "A", count: 101)])
    func refusesUnusableTitles(title: String) async throws {
        let viewModel = try await makeViewModel()

        await viewModel.doAction(.add(title))

        let message = try #require(viewModel.state.failureMessage)
        #expect(!message.isEmpty)
        // 使用者看不懂錯誤碼，畫面上唯一有用的資訊是「怎麼改才對」。
        #expect(!message.contains("GridItemError"))
        #expect(viewModel.state.items.count == 2)
    }

    @Test("改名同樣擋下不能用的標題")
    func refusesUnusableRename() async throws {
        let viewModel = try await makeViewModel()
        let target = try #require(viewModel.state.items.last)
        let original = target.title

        await viewModel.doAction(.rename(target.id, "  "))

        #expect(viewModel.state.failureMessage != nil)
        #expect(viewModel.state.items.last?.title == original)
    }

    @Test("關閉提示後訊息消失")
    func dismissFailureClearsMessage() async throws {
        let viewModel = try await makeViewModel()
        await viewModel.doAction(.add(""))
        #expect(viewModel.state.failureMessage != nil)

        await viewModel.doAction(.dismissFailure)

        #expect(viewModel.state.failureMessage == nil)
    }
}
