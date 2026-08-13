## 1. 抽出字串並改寫為英文

> 本階段**只寫英文字面值，不建立任何翻譯**。String Catalog 的 key 由編譯器產生（見階段 2），此處自行造 key 會與編譯器產出的變體不符。
> 字面值必須直接寫在 `Text()` 或 `String(localized:)` 內；不得將 `LocalizedStringKey` 當參數傳遞。

- [x] [P] 1.1 依「字面值改寫成英文，而不是把 base 改成繁中」改寫 `Sources/Features/RoleSelection/RoleSelectionView.swift` 的 14 處中文字面值為英文，含免責聲明全文、兩顆角色按鈕、藍牙不可用時的說明與 accessibility 文字。驗證：以 grep 確認該檔無中文字元；建置通過。
- [x] [P] 1.2 改寫 `Sources/Features/PatientGrid/PatientGridView.swift` 的 10 處，含連線指示的「已連線／未連線」、三種呼叫狀態文字、accessibility label 與 hint。驗證：以 grep 確認該檔無中文字元；`PatientGridLayoutTests` 維持通過。
- [x] [P] 1.3 改寫 `Sources/Features/CaregiverCalls/CaregiverCallsView.swift` 的 17 處，含空狀態、確認按鈕、逾時標示、失敗橫幅與 accessibility 文字。驗證：以 grep 確認該檔無中文字元。
- [x] [P] 1.4 改寫 `Sources/Features/RoleSettings/RoleSettingsView.swift` 的 9 處與 `Sources/Features/Shared/TwoStepConfirmButton.swift` 的 4 處。驗證：以 grep 確認兩檔無中文字元。
- [x] [P] 1.5 改寫 `Sources/Features/CaregiverHome/CaregiverHomeContainer.swift` 與 `Sources/Features/PatientHome/PatientHomeContainer.swift` 的分頁標題與導覽標題共 4 處。驗證：以 grep 確認兩檔無中文字元。
- [x] 1.6 依「ViewModel 的訊息用 `String(localized:)`，不改回傳型別」改寫 `Sources/Features/CaregiverCalls/CaregiverCallsViewModel.swift` 的四句確認失敗訊息，滿足 `Every user sees a language they can read`。驗證：以 grep 確認 `describe(_:)` 內的字面值皆包在 `String(localized:)` 中，且無純 `String` 常數形式的使用者訊息。
- [x] 1.7 依「預設格子標題屬使用者資料」改寫 `Sources/Core/Persistence/GridItemStore.swift` 的 `defaultItems`，四個標題以 `String(localized:)` 在種子時取得，滿足 `Grid item titles are the caregiver's data, not interface text`。驗證：`GridItemStoreTests` 維持通過；以 grep 確認種子路徑不在每次讀取時重新翻譯。

## 2. 產生 key

- [x] 2.1 於 `project.yml` 的 target 設定加入 `SWIFT_EMIT_LOC_STRINGS: "YES"` 並重新產生專案。沒有這個開關就只有舊的來源解析器在跑，它只認得 `Text("字面值")`，`Button`／`Label`／`Section`／`String(localized:)` 一概看不到，活著的字串會被整批標成 stale。驗證：`xcodebuild -showBuildSettings` 中該設定為 `YES`。
- [x] 2.2 建立空的 `Sources/Resources/Localizable.xcstrings`（base 為 `en`），建置後以 `xcrun xcstringstool sync Sources/Resources/Localizable.xcstrings --stringsdata <DerivedData 下每個 .stringsdata>` 把編譯器擷取到的 key 併回 catalog。`.stringsdata` 位於 `<DerivedData>/Build/Intermediates.noindex/…/Objects-normal/<arch>/`。驗證：catalog 內包含階段 1 改寫的英文字串作為 key，且 key 由此流程產生而非人工撰寫。

## 3. 翻譯與資源

- [x] 3.1 於 `Localizable.xcstrings` 逐條填入繁體中文翻譯，並清除 stale 項目，滿足 `A missing translation degrades to English, never to another language`——String Catalog 的 base 為 en，缺少翻譯的字串自動回退英文而非其他語言。stale 逐條分三類處理：動態 key 誤判則改回字面值、翻譯掛在未選用的變體則搬到活的 key、功能已移除則刪除。**不得以 grep 判斷死活**（會誤判註解）。驗證：stale 數為 0、缺翻譯數為 0。
- [x] 3.2 依「`Info.plist` 的權限說明走 `InfoPlist.strings`，不走 String Catalog」建立 `Sources/Resources/en.lproj/InfoPlist.strings` 與 `Sources/Resources/zh-Hant.lproj/InfoPlist.strings`，提供 `NSBluetoothAlwaysUsageDescription` 的兩種語言，並將 `Sources/App/Info.plist` 中的該字串改為英文，滿足 `System-presented text follows the same rule`。驗證：日文系統下觸發藍牙權限，彈窗說明為英文。
- [x] 3.3 移除 `Sources/Resources/en.lproj/Localizable.strings` 與 `Sources/Resources/zh-Hant.lproj/Localizable.strings`，並確認 `project.yml` 的資源設定涵蓋 String Catalog。驗證：建置通過；App bundle 內存在 `Localizable.strings` 的編譯產物（由 String Catalog 產生）而非原本的空檔。

## 4. 驗證

- [x] 4.1 建立 `docs/device-verification/w5-localization.md`，涵蓋日文系統的逐頁檢查（患者端格子、照顧者端呼叫清單與設定、首頁與免責聲明、藍牙權限彈窗）、繁中系統的逐頁檢查、VoiceOver 的朗讀語言、以及英文文字造成的版面溢出檢查，每項含前置條件、步驟、預期結果、實際結果與 OS 版本欄位。驗證：文件涵蓋本 change 全部實機驗收項目，逐項可獨立執行。
- [x] 4.2 依「驗收用第三語言實測，不用翻譯表比對」執行並記錄**日文系統**驗證，滿足 `Every user sees a language they can read`（Scenario: The system language is not supported）與 `System-presented text follows the same rule`：逐頁檢視所有畫面與藍牙權限彈窗，**看到任何一個中文字即為失敗**。驗證：清單中填入實際結果與 OS 版本；失敗項目須指出是哪一個字串未被抽出。
- [x] 4.3 執行並記錄**繁中系統**驗證：逐頁檢視，確認全部呈現繁體中文，沒有任何項目回退成英文。同時檢查英文文字在患者端格子與按鈕上是否造成版面溢出或過度縮字。驗證：清單中填入實際結果。
- [x] 4.4 執行並記錄 VoiceOver 的朗讀語言驗證，滿足 `Spoken output matches the interface language`：在**英文系統**的 iPad 上開啟 VoiceOver，聚焦患者端格子，確認以英文語音朗讀而非 CJK 語音。驗證：清單中填入實際結果與 OS 版本。
- [x] 4.5 依「預設格子標題屬使用者資料，種子時取當下語言寫入」執行並記錄種子語言驗證，滿足 `Grid item titles are the caregiver's data, not interface text`：在英文系統下刪除 App 重裝並進入患者端，確認四個預設格子為英文；接著將系統語言切換為繁體中文，確認格子標題**維持英文不變**。驗證：清單中填入實際結果。
