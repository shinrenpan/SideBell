## Why

`project.yml` 宣告了 `developmentLanguage: en`，但程式碼裡的字面值全是繁體中文。String Catalog 的規則是「字面值即為 base 語言的內容」，所以 Xcode 認定那些中文**就是英文**——**任何非繁中的使用者都會看到中文**，包括英文使用者。日文、印尼文、越南文的使用者 fallback 到 en，拿到的一樣是中文。

這個矛盾比「base 設錯」更隱蔽：設定檔看起來是對的，只有實際跑起來才會發現。

現在做的理由是成本：字串量目前約 63 個且集中在四個畫面，W5 的 onboarding 與 W6 的 App Store 素材會讓它翻好幾倍。而 base 語言一旦有了翻譯資料，之後要改動會牽動所有既有的歸類。

另有一項與比賽直接相關：`DECISIONS.md` 2026-08-06 記載，英文系統的 iPad 開啟 VoiceOver 時，中文內容會被**韓文語音**朗讀——語言標記不明確時語音引擎會任選一個能處理 CJK 的。無障礙是 Peace Prize 的評分項目，而評審多以英文裝置檢視。

## What Changes

- 所有使用者可見的字面值改寫為**英文**，繁體中文改以翻譯提供。涵蓋畫面文字、`accessibilityLabel`、`accessibilityHint`、以及 `CaregiverCallsViewModel` 產生的四句確認失敗訊息。
- `CaregiverCallsViewModel` 的訊息改用 `String(localized:)` 產生。目前它們是純 `String` 常數，String Catalog **完全擷取不到**。
- `Info.plist` 的 `NSBluetoothAlwaysUsageDescription` 改以 `InfoPlist.strings` 提供翻譯——該字串不走 String Catalog，是最容易漏掉的一處。
- 預設格子的四個標題（喝水／翻身／洗手間／不舒服）**種子時取當下語言寫入資料庫，之後不隨系統語言變動**。它們一旦寫入就是照顧者的資料，而照顧者接下來能編輯它們。
- 建立 String Catalog（`Localizable.xcstrings`）取代目前的 `.strings` 檔，繁中翻譯逐條填入。
- **BREAKING**：現有的 `Sources/Resources/en.lproj/Localizable.strings` 與 `zh-Hant.lproj/Localizable.strings` 移除。它們從 W1 建立至今是空的，實際上沒有任何翻譯經過它們。

## Non-Goals

- **印尼語與越南語**——spec 9.4 標為 `[v1.1]`。本片只確保字串架構支援它們，不實際翻譯。
- **log 訊息與 `assertionFailure` 的內容**。`BLECentralEndpoint` 等傳輸層的 23 處中文字串是給開發者看的診斷輸出，翻譯它們沒有價值，還會讓 log 難以搜尋。
- **`#if DEBUG` 的 Preview mock 資料**。不會出現在使用者面前。
- **App Store 的產品頁描述與螢幕截圖**——屬 W6 的上架素材，不在程式碼裡。
- **語音播報與通知的內容**。它們讀的是格子標題，屬使用者資料而非 UI 字串，隨資料庫走。
- **右至左（RTL）語言的版面適配**。1.0 與 1.1 的目標語言都是左至右。

## Capabilities

### New Capabilities

- `localization`: App 呈現給使用者的語言如何決定、缺少翻譯時的回退行為、以及哪些內容屬於使用者資料而不隨系統語言變動。

### Modified Capabilities

(none)

## Impact

- Affected specs: `localization`（新建）
- Affected code:
  - New:
    - `Sources/Resources/Localizable.xcstrings`
    - `Sources/Resources/en.lproj/InfoPlist.strings`
    - `Sources/Resources/zh-Hant.lproj/InfoPlist.strings`
    - `docs/device-verification/w5-localization.md`
  - Modified:
    - `Sources/Features/RoleSelection/RoleSelectionView.swift`
    - `Sources/Features/RoleSettings/RoleSettingsView.swift`
    - `Sources/Features/PatientGrid/PatientGridView.swift`
    - `Sources/Features/CaregiverCalls/CaregiverCallsView.swift`
    - `Sources/Features/CaregiverCalls/CaregiverCallsViewModel.swift`
    - `Sources/Features/Shared/TwoStepConfirmButton.swift`
    - `Sources/Features/CaregiverHome/CaregiverHomeContainer.swift`
    - `Sources/Features/PatientHome/PatientHomeContainer.swift`
    - `Sources/Core/Persistence/GridItemStore.swift`
    - `Sources/App/Info.plist`
    - `project.yml`
  - Removed:
    - `Sources/Resources/en.lproj/Localizable.strings`
    - `Sources/Resources/zh-Hant.lproj/Localizable.strings`
- Dependencies: 不新增第三方套件。使用 Xcode 內建的 String Catalog。
- Platform: 不新增權限或背景模式。
- **流程限制**：String Catalog 的 key 只有 Xcode IDE 會產生，命令列的 `xcodebuild` 只產出 `.stringsdata`。因此實作順序固定為「先寫英文字面值 → 由開發者在 Xcode 建置一次 → 再填入翻譯」，中間那步無法自動化。
