import Foundation
import SwiftData

/// 格子項目的讀寫與預設種子。
///
/// 驗證在寫入時執行，不留到送出時——上限來自 wire format，而 wire format
/// 的限制是硬性的：超長的標題根本編不進單一封包。
struct GridItemStore {
    /// 種子是否已執行過。與角色設定同層儲存：判斷不能依賴「格子是否為空」，
    /// 否則照顧者刻意清空格子後，每次啟動都會被塞回四個預設項目。
    static let seededKey = "com.shinrenpan.sidebell.gridSeeded"

    private let context: ModelContext
    private let defaults: UserDefaults

    init(context: ModelContext, defaults: UserDefaults = .standard) {
        self.context = context
        self.defaults = defaults
    }
}

// MARK: - 讀取

extension GridItemStore {
    /// 依排序位置回傳，而非建立順序——患者記住的是實體位置。
    func allItems() throws -> [GridItemModel] {
        try context.fetch(
            FetchDescriptor<GridItemModel>(sortBy: [SortDescriptor(\.sortOrder)])
        )
    }
}

// MARK: - 寫入

extension GridItemStore {
    @discardableResult
    func insert(
        title: String,
        commandCode: String,
        isUrgent: Bool,
        sortOrder: Int? = nil,
        isProtected: Bool = false
    ) throws -> GridItemModel {
        try validate(title: title, commandCode: commandCode)

        let position = try sortOrder ?? nextSortOrder()
        let item = GridItemModel(
            title: title,
            commandCode: commandCode,
            isUrgent: isUrgent,
            sortOrder: position,
            isProtected: isProtected
        )
        context.insert(item)
        try context.save()
        return item
    }

    /// 全部清除。**這不是照顧者的刪除路徑**——它沒有 UI 入口，受保護項目的
    /// 保證由 `delete(_:)` 把關。這裡保留無條件清除是為了測試與日後的重設功能。
    func removeAll() throws {
        for item in try allItems() {
            context.delete(item)
        }
        try context.save()
    }
}

// MARK: - 編輯

extension GridItemStore {
    /// 新增一個項目。照顧者**只提供名稱**。
    ///
    /// `commandCode` 由系統產生、順序接在最後、一律非緊急——緊急等級不開放
    /// 設定，因為誤設的代價是每天被重複警報疲勞轟炸，而警報一旦被當成噪音，
    /// 真正的緊急就叫不動人了。
    @discardableResult
    func addItem(title: String) throws -> GridItemModel {
        let cleaned = try cleanedTitle(title)
        return try insert(
            title: cleaned,
            commandCode: try makeCommandCode(),
            isUrgent: false
        )
    }

    /// 改名。受保護的項目**也可以改名**——保護的是「永遠有一個緊急求助鍵」，
    /// 不是那三個字：有些家庭說「不適」、有些說「疼痛」、有些直接叫「快來」。
    func updateTitle(of item: GridItemModel, to title: String) throws {
        let cleaned = try cleanedTitle(title)
        item.title = cleaned
        try context.save()
    }

    /// 刪除。受保護的項目擲出錯誤。
    ///
    /// UI 上沒有刪除入口，這條路徑照理不會被走到；**資料層仍然把關**，
    /// 因為 UI 的保護是體驗，資料層的保護才是保證。
    func delete(_ item: GridItemModel) throws {
        guard !item.isProtected else {
            throw GridItemError.cannotDeleteProtectedItem
        }
        context.delete(item)
        try context.save()
    }

    /// 依給定順序重寫排序位置，並確保受保護的項目落在第一。
    ///
    /// 受保護者不在首位時**強制拉回**而不是擲錯：拖拽的邊界情況（例如同時
    /// 放手與捲動）在 UI 上不容易全部擋乾淨，而患者記住的是實體位置——
    /// 最緊急的那一格若被擠開，他會按到別的東西。
    func reorder(_ items: [GridItemModel]) throws {
        let ordered = items.filter(\.isProtected) + items.filter { !$0.isProtected }
        for (index, item) in ordered.enumerated() {
            item.sortOrder = index
        }
        try context.save()
    }
}

// MARK: - 種子

extension GridItemStore {
    /// 首次使用時寫入兩個預設格子。
    ///
    /// 沒有預設格子的話，裝置在照顧者完成設定之前是不能用的——而設定的
    /// 畫面在那個時間點還不存在。
    func seedDefaultsIfNeeded() throws {
        guard !defaults.bool(forKey: Self.seededKey) else { return }

        for (index, item) in Self.defaultItems.enumerated() {
            try insert(
                title: item.title,
                commandCode: item.commandCode,
                isUrgent: item.isUrgent,
                sortOrder: index,
                isProtected: item.isProtected
            )
        }
        defaults.set(true, forKey: Self.seededKey)
    }

    /// 到手就能用的最小集合：**兩項**。
    ///
    /// 標題在**種子當下**取得當時的系統語言，寫入資料庫後就不再變動——
    /// 它們自此是照顧者的資料，不是介面文字。讓使用者資料隨系統語言變來
    /// 變去比固定在一個語言更違反直覺：照顧者把「喝水」改成「喝溫水」之後，
    /// 沒有人會期望切換語言時它變回英文。雙語家庭切換語言後格子仍是舊語言，
    /// 那正是編輯功能存在的意義。
    ///
    /// 因此是計算屬性而非 `static let`：後者只在首次存取時求值一次並永久
    /// 快取，與「取種子當下的語言」的語意不符。這個屬性只在種子路徑上被
    /// 讀取，`allItems()` 走的是資料庫，不會重新翻譯。
    ///
    /// `commandCode` 不翻譯：它是給機器對照用的識別碼，兩端必須一致。
    ///
    /// **原本是四項（喝水／翻身／洗手間／不舒服），改為兩項**：那四個是替
    /// 照顧者假設的需求——「翻身」對能走動的患者無用，「洗手間」對包尿布的
    /// 患者無用，而真正要緊的（換尿布、抽痰）一個都沒猜到。留下的兩項是
    /// 「保證叫得到人」加「示範格子長什麼樣」，其餘交給照顧者自己加。
    ///
    /// 受保護的那一項排在**第一**，種子順序即畫面順序。
    nonisolated static var defaultItems: [
        (title: String, commandCode: String, isUrgent: Bool, isProtected: Bool)
    ] {
        [
            (String(localized: "Discomfort"), "PAIN", true, true),
            (String(localized: "Water"), "WATER", false, false),
        ]
    }
}

// MARK: - 私有

private extension GridItemStore {
    /// 去除前後空白後檢查標題。
    ///
    /// 在**編輯當下**拒絕，不留到患者按下才發現：那是最不能失敗的時刻。
    func cleanedTitle(_ title: String) throws -> String {
        let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { throw GridItemError.titleEmpty }
        try validate(title: cleaned, commandCode: "")
        return cleaned
    }

    /// 產生一個未被使用的短碼。
    ///
    /// 取 UUID 的前 8 個十六進位字元：必然是 ASCII、剛好用滿 wire format 的
    /// 8 位元組上限，且**不重用已刪除項目的代碼**——重用會讓日後的統計把
    /// 兩種不同的呼叫算在一起。
    func makeCommandCode() throws -> String {
        let existing = Set(try allItems().map(\.commandCode))
        for _ in 0..<16 {
            let candidate = String(
                UUID().uuidString.replacingOccurrences(of: "-", with: "")
                    .prefix(CallMessageCodec.commandCodeSize)
            )
            if !existing.contains(candidate) { return candidate }
        }
        throw GridItemError.commandCodeUnavailable
    }

    func validate(title: String, commandCode: String) throws {
        let titleBytes = title.utf8.count
        guard titleBytes <= CallMessageCodec.maxTitleByteCount else {
            throw GridItemError.titleTooLong(
                byteCount: titleBytes,
                limit: CallMessageCodec.maxTitleByteCount
            )
        }

        let codeBytes = Array(commandCode.utf8)
        guard codeBytes.count <= CallMessageCodec.commandCodeSize else {
            throw GridItemError.commandCodeTooLong(
                byteCount: codeBytes.count,
                limit: CallMessageCodec.commandCodeSize
            )
        }
        guard codeBytes.allSatisfy({ $0 < 0x80 }) else {
            throw GridItemError.commandCodeNotASCII
        }
    }

    func nextSortOrder() throws -> Int {
        (try allItems().map(\.sortOrder).max() ?? -1) + 1
    }
}
