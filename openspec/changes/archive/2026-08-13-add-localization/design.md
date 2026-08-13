## Context

`project.yml` 自 W2 起就設定 `developmentLanguage: en`，理由記在 `DECISIONS.md` 2026-08-06：Shipaton 評審多用英文裝置，而 Peace Prize 評的是產品使命，他們得先看懂才能評。

但程式碼的字面值一直是繁體中文。String Catalog 以「字面值即 base 語言的內容」運作，因此這個組合等於告訴 Xcode「這些中文就是英文」。實際後果是**所有非繁中使用者都看到中文**——英文使用者沒有 fallback 可去（他們拿到的就是 base），日文與其他語言的使用者 fallback 到 en，得到的同樣是中文。繁中使用者看起來正常，純粹是因為 fallback 過去剛好是中文。

String Catalog 的 key **一律由編譯器產生，不由人撰寫**：同一句話會依引數型別產出 `%@`／`%lld`／`%arg` 等變體，選哪一個無從由原始碼推論。命令列建置只產出 `.stringsdata`，不會寫回 catalog——但 `xcrun xcstringstool sync <catalog> --stringsdata <每個 .stringsdata>` 會把它們併回去，那正是 Xcode 內部走的同步路徑。因此整條迴圈可由命令列走完，不需要開 Xcode。

前提是 `SWIFT_EMIT_LOC_STRINGS` 為 `YES`。沒開就只有舊的來源解析器在跑，而它只認得 `Text("字面值")`——`Button`／`Label`／`Section`／`String(localized:)` 全部看不到，活著的字串會被整批標成 stale。

## Goals / Non-Goals

**Goals:**

- 任何語言的使用者都看得懂介面：支援的語言看到母語，不支援的看到英文。
- 使用者資料（格子標題）與 UI 字串分離，前者不隨系統語言變動。
- 有可執行的驗收方式，而不是靠人工比對翻譯表。
- 字串架構支援 1.1 加入印尼語與越南語，屆時只需新增翻譯。

**Non-Goals:**

- 印尼語與越南語的實際翻譯（`[v1.1]`）。
- log 與 `assertionFailure` 的內容——給開發者看的診斷輸出。
- Preview mock 資料。
- App Store 產品頁素材（W6）。
- RTL 版面適配。

## Decisions

### 字面值改寫成英文，而不是把 base 改成繁中

兩條路都能消除矛盾，但方向相反：

- **字面值改英文**：base = en 成立，未支援的語言 fallback 到英文。
- **base 改繁中**：省下改寫成本，但未支援的語言 fallback 到繁中。

選前者。使用者若看不懂介面語言，英文的可猜測性遠高於繁體中文——按鈕上寫 `Settings` 至少認得出是設定，寫「設定」對非漢字圈的人是無法解析的圖形。這也是 W2 那條決策的原意，只是當時沒發現字面值破壞了它。

### 驗收用第三語言實測，不用翻譯表比對

把裝置語言切到**日文**（我們不支援的語言），逐頁檢視。**看到任何一個中文字即為失敗**——那代表該字串沒被抽出，或 base 設定沒生效。

這比檢查翻譯檔可靠得多：漏抽的字串在翻譯表裡根本不會出現，只有跑起來才會現形。切到英文反而測不出來，因為英文正是 base，漏抽與正確的結果看起來一樣。

### `Info.plist` 的權限說明走 `InfoPlist.strings`，不走 String Catalog

`NSBluetoothAlwaysUsageDescription` 由系統在權限彈窗中呈現，不經過 App 的字串載入路徑。它是最容易漏掉的一處，而漏掉的症狀是**藍牙權限彈窗冒出中文**——那是使用者看到的第一個畫面之一。

第三語言測試會抓到它：日文系統下觸發藍牙權限，彈窗裡的說明必須是英文。

### 預設格子標題屬使用者資料，種子時取當下語言寫入

四個預設標題（喝水／翻身／洗手間／不舒服）以 `String(localized:)` 在種子時取得當下語言，寫入資料庫後**不再變動**。

理由是它們的身分：一旦寫入，它們就是照顧者的資料，而照顧者接下來能編輯它們（格子編輯屬後續里程碑）。讓使用者資料隨系統語言變來變去，比固定在一個語言更違反直覺——照顧者把「喝水」改成「喝溫水」之後，沒有人會期望切換語言時它變回英文。

代價是雙語家庭切換系統語言後，格子仍是舊語言。那正是編輯功能存在的意義。

### ViewModel 的訊息用 `String(localized:)`，不改回傳型別

`CaregiverCallsViewModel.describe(_:)` 目前回傳純 `String` 常數，String Catalog **完全擷取不到**——它只認得直接寫在 `Text()` 或 `String(localized:)` 裡的字面值。

改為在 `describe(_:)` 內以 `String(localized:)` 產生已本地化的字串，回傳型別不變。

考慮過的替代方案是「ViewModel 回傳 enum，由 View 轉成 `Text`」——那樣字面值會落在 View 裡，符合擷取條件。但它把「錯誤如何措辭」這件事從 ViewModel 搬到 View，而措辭是產品決策不是排版決策，放在 View 會讓兩個畫面對同一個錯誤長出不同說法。

## Implementation Contract

**Behavior**

- 系統語言為繁體中文時，介面全部呈現繁體中文。
- 系統語言為英文，或為任何未支援的語言（日文、印尼文、越南文等）時，介面全部呈現英文，且**不含任何中文字元**。
- 藍牙權限彈窗的說明文字跟隨系統語言，規則同上。
- 首次啟動種下的四個預設格子，其標題為**種子當下**的系統語言；此後切換系統語言不改變它們。
- VoiceOver 朗讀的語言與介面語言一致——英文介面不得以 CJK 語音朗讀。

**Interface / data shape**

- 字串資源集中於 `Sources/Resources/Localizable.xcstrings`（String Catalog），base 語言為 `en`，另含 `zh-Hant` 翻譯。
- `Info.plist` 的權限說明另由 `en.lproj/InfoPlist.strings` 與 `zh-Hant.lproj/InfoPlist.strings` 提供。
- 程式碼中**只出現英文字面值**，且必須直接寫在 `Text()` 或 `String(localized:)` 內。不得將 `LocalizedStringKey` 當參數傳遞——那會讓字串進入 `__PotentialKeys` 而被標為 stale，後續清理時會刪掉活著的翻譯。

**Failure modes**

- 某字串缺少 `zh-Hant` 翻譯：繁中使用者看到英文。可接受但視為未完成，由 String Catalog 的缺翻譯計數把關。
- 某字串未被抽出（仍是中文字面值）：**所有非繁中使用者看到中文**。這是本片要消滅的失敗，由第三語言測試把關。
- `InfoPlist.strings` 缺漏：權限彈窗顯示 base 語言的內容。

**Acceptance criteria**

- String Catalog 的 **stale 數為 0、缺翻譯數為 0**（`CLAUDE.md` 的完成判準）。
- 日文系統下逐頁檢視，**畫面上不出現任何中文字元**，含藍牙權限彈窗。
- 繁中系統下逐頁檢視，介面全部為繁體中文。
- 以 grep 確認 `Sources/Features/` 下不存在中文字面值（log、`#if DEBUG` 區塊、`#Preview` 的名稱除外；註解不受限，它們是給開發者看的）。
- 既有的 72 項單元測試維持通過。

**Scope boundaries**

- 在範圍內：四個 View 與共用元件的介面文字、accessibility 文字、`CaregiverCallsViewModel` 的四句訊息、兩個容器的分頁標題、`Info.plist` 權限說明、預設格子種子、String Catalog 的建立與繁中翻譯。
- 不在範圍內：傳輸層與警報層的 log 訊息、`assertionFailure` 內容、Preview mock、印尼語與越南語的翻譯、App Store 素材、RTL 版面。

## Risks / Trade-offs

- **key 歸編譯器，value 歸實作者** → 實作順序固定為「寫英文字面值 → 建置 → `xcstringstool sync` → 填翻譯」。中間兩步必須是獨立且明確的任務；自行造 key 會與編譯器產出的變體不符。
- **英文措辭由開發者而非母語者撰寫** → 目標是可理解而非文采。介面用詞取最常見的形式（`Settings`、`Got it`、`Waiting`），避免自創說法。
- **翻譯後版面可能溢出** → 英文普遍比中文長，患者端的格子標題與按鈕尤其敏感（格子已有 `minimumScaleFactor(0.5)` 與兩行上限）。第三語言測試須同時檢視版面，不只檢查語言。
- **既有驗證清單以中文描述畫面內容** → W3 與 W4 的清單寫著「顯示『未連線』」等字樣。本片完成後，那些描述在英文系統下不再字面吻合。清單維持中文（它們是給開發者看的），但需註明驗證時的系統語言。

## Migration Plan

1. 先抽字串、改寫為英文字面值，不動翻譯。
2. 開啟 `SWIFT_EMIT_LOC_STRINGS`，建置後以 `xcstringstool sync` 把 `.stringsdata` 併回 String Catalog，產生 key。
3. 填入繁中翻譯，清除 stale。
4. 第三語言（日文）實機驗證，逐頁檢查。
5. 繁中實機驗證，確認沒有回退成英文的項目。

回退策略：本片不改動任何行為邏輯，只改字串的來源。若翻譯出現問題，可單獨還原 String Catalog 而不影響功能。

## Open Questions

- 英文措辭是否需要母語者複核？以比賽時程判斷，1.0 先求準確可理解，若有餘裕再請人潤稿。
- `en.lproj` 與 `zh-Hant.lproj` 目錄在移除 `Localizable.strings` 後僅剩 `InfoPlist.strings`，是否維持該結構由實作時的 Xcode 慣例決定，不影響行為。
