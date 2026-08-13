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
        sortOrder: Int? = nil
    ) throws -> GridItemModel {
        try validate(title: title, commandCode: commandCode)

        let position = try sortOrder ?? nextSortOrder()
        let item = GridItemModel(
            title: title,
            commandCode: commandCode,
            isUrgent: isUrgent,
            sortOrder: position
        )
        context.insert(item)
        try context.save()
        return item
    }

    func removeAll() throws {
        for item in try allItems() {
            context.delete(item)
        }
        try context.save()
    }
}

// MARK: - 種子

extension GridItemStore {
    /// 首次使用時寫入四個預設格子。
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
                sortOrder: index
            )
        }
        defaults.set(true, forKey: Self.seededKey)
    }

    /// spec 2.1 的四個核心格子。
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
    nonisolated static var defaultItems: [(title: String, commandCode: String, isUrgent: Bool)] {
        [
            (String(localized: "Water"), "WATER", false),
            (String(localized: "Turn over"), "TURN", false),
            (String(localized: "Bathroom"), "TOILET", false),
            (String(localized: "Discomfort"), "PAIN", true),
        ]
    }
}

// MARK: - 私有

private extension GridItemStore {
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
