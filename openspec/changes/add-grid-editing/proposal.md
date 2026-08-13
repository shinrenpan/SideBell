## Why

患者端目前的四個格子是我們替照顧者假設的需求。「喝水／翻身／洗手間」哪些用得到因人而異——臥床患者需要翻身，能走動的可能只需要洗手間；而真實的需求（「換尿布」「抽痰」「調整枕頭」）我們一個都沒有預設。

沒有編輯功能的後果不是「少了自訂」，而是**患者只能用我們猜的那幾個詞求助**。一個需要抽痰的患者，得按「不舒服」然後等照顧者過來猜。

同時這是 spec 2.1 的原始需求，從 W3 起就被記為「下一片」，`DECISIONS.md` 已累積三條專為它保留的約束（格子數量上限、捲動的降級路徑、重複觸發的去重規則）。

## What Changes

- 患者端設定頁新增「編輯呼叫項目」入口，開啟編輯畫面。
- 編輯畫面是**清單**而非格子：一維的列表適合排序與刪除，用格子編輯格子會把兩種操作混在同一個介面裡。
- 照顧者可**新增、改名、刪除、拖拽排序**呼叫項目。新增時**只需填名稱**一個欄位。
- **BREAKING**：首次安裝的預設項目由四個減為**兩個**——`不舒服` 與 `喝水`。四個是替照顧者假設的需求；兩個是真正的最小集合，其餘由他自己加。
- `不舒服` 成為**受保護的項目**：可以改名，但**不可刪除**，且**永遠位於第一格**。它是患者唯一的緊急求助管道，位置固定讓肌肉記憶絕對穩定。
- 項目數量達上限時，新增動作被擋下並說明原因，而不是讓照顧者加完之後患者默默看不到。
- 緊急等級**不開放設定**。只有受保護的 `不舒服` 是緊急呼叫，照顧者因此不需要理解「緊急」這個概念，也不會誤把日常需求設成會重複警報的項目。
- 機器可讀的 `commandCode` 由系統產生，不出現在編輯畫面上。

## Non-Goals

- **圖示**。`DECISIONS.md` 2026-08-08 已定：圖示無法被照顧者編輯出來，會造成預設項目有圖、自訂項目沒圖的不一致。
- **同一格重複觸發的狀態去重**。那是患者端觸發路徑的行為，`DECISIONS.md` 已記錄規則，但屬患者端格子的改動，與編輯功能無關。
- **捲動的降級路徑**（超過一屏時的上下箭頭、緊急格子釘在第一屏）。本片以數量上限確保不需要捲動；降級路徑等到真有家庭需要超過上限時再做。
- **多位患者的項目管理**。傳輸層以集合管理連線，但 1.0 只呈現一位患者。
- **項目的匯入匯出或範本**。照顧者自己輸入即可，範本庫要維護一份「常見照護需求」清單，那是內容工作不是程式工作。
- **編輯歷史與復原**。刪除即刪除，以確認對話框防止誤刪。

## Capabilities

### New Capabilities

- `grid-editing`: 照顧者如何增減與調整患者的呼叫項目——編輯的入口與形式、受保護項目的規則、數量上限的把關、以及編輯結果何時反映到患者的畫面上。

### Modified Capabilities

- `grid-storage`: 種子項目由四個減為兩個；「刻意清空後不再種子」的情境不再可能發生，因為受保護的項目不可刪除。

## Impact

- Affected specs: `grid-editing`（新建）、`grid-storage`（修改）
- Affected code:
  - New:
    - `Sources/Features/GridEditing/GridEditingHostController.swift`
    - `Sources/Features/GridEditing/GridEditingView.swift`
    - `Sources/Features/GridEditing/GridEditingViewModel.swift`
    - `Sources/Features/GridEditing/GridEditingViewModel+Models.swift`
    - `Sources/Features/GridEditing/GridEditingMocks.swift`
    - `Tests/GridEditingTests/GridEditingStateTests.swift`
    - `docs/device-verification/w7-grid-editing.md`
  - Modified:
    - `Sources/Core/Persistence/GridItemModel.swift`
    - `Sources/Core/Persistence/GridItemStore.swift`
    - `Sources/Features/RoleSettings/RoleSettingsView.swift`
    - `Sources/Features/RoleSettings/RoleSettingsViewModel.swift`
    - `Sources/Features/RoleSettings/RoleSettingsHostController.swift`
    - `Sources/App/AppRouter.swift`
    - `Tests/PersistenceTests/GridItemStoreTests.swift`
    - `docs/device-verification/w3-patient-grid.md`
  - Removed: (none)
- Dependencies: 不新增第三方套件。
- Platform: 不新增權限或背景模式。
- **既有驗證清單受影響**：`docs/device-verification/w3-patient-grid.md` 多處以「四格」描述畫面（G1 首次啟動、G2 版面），本片完成後需更新為兩格。
