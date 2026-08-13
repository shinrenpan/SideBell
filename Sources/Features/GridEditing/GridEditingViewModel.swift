import Foundation

/// 編輯患者端的呼叫項目。
///
/// 操作者是照顧者，但**資料在患者的裝置上**——格子存在患者端的資料庫裡，
/// 呼叫也由那裡發起。因此這一頁住在患者端，經由那個已有兩段確認保護的
/// 設定入口進入。
///
/// 每一次變更**立即寫入**，沒有「編輯／完成」的暫存模式：照顧者可能在任何
/// 時候被患者叫走，而暫存模式必須回答「編輯到一半離開怎麼辦」。立即生效
/// 沒有這個問題。
@Observable
@MainActor
final class GridEditingViewModel {
    var state: State = .init()

    @ObservationIgnored private let store: GridItemStore
    /// 一屏放得下的格子數。由 C 層以既有的版面演算法算出後注入——
    /// ViewModel 不讀螢幕尺寸，否則這一頁就只能在真機上測。
    @ObservationIgnored private let itemLimit: Int
    /// 超過這個數量就提示「項目越多越難找」，但**不擋**。
    @ObservationIgnored private let recommendedItemLimit: Int
    /// 項目變動後回報給上層。
    ///
    /// 患者端的格子畫面在**這個 sheet 底下**，從來沒有 disappear 過，因此
    /// 關閉 sheet 之後它的 `onAppear` 不會再跑。少了這條回報，照顧者會看到
    /// 自己新增的項目沒有出現在格子上——而他無從得知那只是畫面沒重載。
    @ObservationIgnored var onCallback: (@MainActor (Callback) async -> Void)?

    init(
        store: GridItemStore,
        itemLimit: Int,
        recommendedItemLimit: Int = PatientGridView.recommendedItemLimit
    ) {
        self.store = store
        self.itemLimit = itemLimit
        self.recommendedItemLimit = recommendedItemLimit
    }

    func doAction(_ action: Action) async {
        switch action {
        case .onAppear:
            state.itemLimit = itemLimit
            reload()

        case let .add(title):
            await add(title)

        case let .rename(id, title):
            await rename(id, to: title)

        case let .delete(id):
            await delete(id)

        case let .move(source, destination):
            await move(from: source, to: destination)

        case .dismissFailure:
            state.failureMessage = nil
        }
    }
}

// MARK: - 讀取

private extension GridEditingViewModel {
    func reload() {
        do {
            let items = try store.allItems()
            state.items = items.map {
                EditItem(id: $0.id, title: $0.title, isProtected: $0.isProtected)
            }
            state.canAdd = items.count < itemLimit
            state.isCrowded = items.count >= recommendedItemLimit
        } catch {
            // 讀不到格子是本機資料庫的問題，重試也不會變好。照顧者唯一能做的
            // 是重開 App，因此說法停在「現在改不了」，不給一個沒有用的重試。
            state.items = []
            state.canAdd = false
            state.failureMessage = String(
                localized: "The call items could not be loaded. Please reopen the app."
            )
        }
    }
}

// MARK: - 編輯

private extension GridEditingViewModel {
    func add(_ title: String) async {
        // 上限在這裡也擋一次：畫面已經停用入口，但停用是體驗，
        // 這一層才是保證——而多出來的格子患者根本看不到。
        guard state.canAdd else {
            state.failureMessage = String(
                localized:
                    "The grid is full at \(state.itemLimit) items. Remove one before adding another."
            )
            return
        }

        await perform {
            try store.addItem(title: title)
        }
    }

    func rename(_ id: UUID, to title: String) async {
        guard let item = try? item(id) else { return }

        await perform {
            try store.updateTitle(of: item, to: title)
        }
    }

    func delete(_ id: UUID) async {
        guard let item = try? item(id) else { return }

        await perform {
            try store.delete(item)
        }
    }

    /// 依畫面上的拖拽結果重排。
    ///
    /// 落點在受保護項目**之前**時往後推一格。資料層也會把受保護的那一項
    /// 拉回第一，但那要等重載才看得到——照顧者會先看到它跳走再跳回來，
    /// 而畫面抖一下會讓人以為自己操作錯了。這裡夾住落點，那一幀就不存在。
    func move(from source: IndexSet, to destination: Int) async {
        await perform {
            var ordered = try store.allItems()
            let target = ordered.first?.isProtected == true ? max(destination, 1) : destination
            ordered.move(fromOffsets: source, toOffset: target)
            try store.reorder(ordered)
        }
    }
}

// MARK: - 私有

private extension GridEditingViewModel {
    /// 執行一次寫入，成功就重載並回報上層、失敗就翻譯錯誤。
    ///
    /// 所有寫入路徑共用：漏掉重載會讓畫面與資料庫說法不同，而那正是
    /// 這個 App 最致命的 bug 類型——畫面說成功、實際沒發生。
    ///
    /// **失敗不回報**：沒有任何東西變了，讓患者端白重載一次只是浪費。
    func perform(_ write: () throws -> Void) async {
        do {
            try write()
            state.failureMessage = nil
            reload()
            await onCallback?(.itemsDidChange)
        } catch {
            state.failureMessage = describe(error)
        }
    }

    func item(_ id: UUID) throws -> GridItemModel? {
        try store.allItems().first { $0.id == id }
    }

    /// 把資料層的錯誤翻成照顧者能照著改的說法。
    ///
    /// **原始錯誤不外流**：`titleTooLong(byteCount: 143, limit: 100)` 對照顧者
    /// 沒有意義，他要知道的是「名稱太長，改短一點」。
    func describe(_ error: any Error) -> String {
        guard let error = error as? GridItemError else {
            return String(localized: "The change could not be saved. Please try again.")
        }

        switch error {
        case .titleEmpty:
            return String(localized: "Enter a name for this item.")

        case .titleTooLong:
            return String(localized: "That name is too long. Please use a shorter one.")

        case .cannotDeleteProtectedItem:
            // 畫面上沒有刪除入口，走到這裡代表某處漏擋。說法仍要對照顧者有意義。
            return String(localized: "This item cannot be removed. It is how the patient calls for help.")

        case .commandCodeTooLong, .commandCodeNotASCII, .commandCodeUnavailable:
            // 代碼由系統產生，照顧者從來沒碰過它。這條路徑代表程式有問題，
            // 不是他做錯了什麼。
            return String(localized: "The change could not be saved. Please try again.")
        }
    }
}
