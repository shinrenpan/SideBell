## Why

W1 交付的是傳輸層與一個丟棄式的 PoC 畫面：App 打開就是一個角色切換器加幾顆測試按鈕。要開始堆疊患者端與照顧者端的正式畫面，得先有承載它們的骨架——首頁、角色選擇、以及兩端各自的容器。

這一片先做，是因為它是所有後續畫面的容器：患者端格子、照顧者端儀表板、歷史紀錄、設定、贊助頁，全部都掛在這裡。骨架沒立起來，每個畫面都不知道自己該住在哪。

同時它解決一個 spec 9.3 標為必做的項目：免責聲明必須在首次啟動明示。這是 App Review 的醫療類敏感聲明，屬於會被拒的項目而非加分項，越早進入產品越好。

## What Changes

- 建立首頁：免責聲明常駐、首次啟動須主動確認、兩顆角色按鈕（患者端／照顧者端）。
- 藍牙不可用時停用角色按鈕並說明原因；但「尚未判定」的狀態一律放行，避免使用者無法進入 App。
- 選擇角色後以全螢幕方式進入對應容器：患者端為導覽堆疊、照顧者端為分頁容器。
- 已選過角色的啟動直接進入對應容器，不重複要求選擇；首頁仍為根畫面，供「切換角色」返回。
- 患者端不設分頁列，設定入口為長按觸發，避免眼控誤觸離開呼叫畫面。
- 照顧者端建立兩個分頁的骨架，設定分頁提供「切換角色」以返回首頁。
- 建立導航中樞，集中處理進入角色、返回首頁的轉場，各畫面不自行操作導覽控制器。
- 兩個角色容器的主畫面**暫時沿用 W1 的傳輸驗證畫面**，確保已驗證的傳輸行為在改動骨架後不退化。

## Non-Goals

- 患者端格子畫面與格子編輯——下一片。
- 照顧者端的呼叫清單、歷史紀錄、警報與通知——後續里程碑。
- 任何 SwiftData 資料模型；本片僅新增一項輕量的免責確認狀態，與角色設定同層。
- 贊助頁與 RevenueCat 整合。
- 重送／確認狀態機的完整定義——那要等患者端格子畫面才需要。
- 刪除 `Sources/Features/TransportPoC/`：正式畫面完成前仍需保留它來驗證傳輸行為。
- onboarding 教學流程（不要滑掉 App、引導使用模式、配對步驟）——本片只做免責聲明這一項必做要求。

## Capabilities

### New Capabilities

- `role-selection`: 首頁的行為——免責聲明的呈現與首次確認、角色選擇的可用條件、選擇後的去向，以及從任一角色返回首頁的路徑。

### Modified Capabilities

- `app-shell`: 根畫面結構由「導覽堆疊直接託管內容」改為「首頁為根、角色容器以全螢幕呈現」，並新增啟動時依既有角色決定去向的行為。

## Impact

- Affected specs: `role-selection`（新建）、`app-shell`（修改）
- Affected code:
  - New:
    - `Sources/App/AppRouter.swift`
    - `Sources/Core/Role/DisclaimerStore.swift`
    - `Sources/Core/Transport/BluetoothAvailability.swift`
    - `Sources/Features/RoleSelection/RoleSelectionHostController.swift`
    - `Sources/Features/RoleSelection/RoleSelectionView.swift`
    - `Sources/Features/RoleSelection/RoleSelectionViewModel.swift`
    - `Sources/Features/RoleSelection/RoleSelectionViewModel+Models.swift`
    - `Sources/Features/PatientHome/PatientHomeContainer.swift`
    - `Sources/Features/CaregiverHome/CaregiverHomeContainer.swift`
    - `Sources/Features/RoleSettings/RoleSettingsHostController.swift`
    - `Sources/Features/RoleSettings/RoleSettingsView.swift`
    - `Sources/Features/RoleSettings/RoleSettingsViewModel.swift`
    - `Sources/Features/RoleSettings/RoleSettingsViewModel+Models.swift`
    - `Tests/RoleTests/DisclaimerStoreTests.swift`
    - `Tests/TransportTests/BluetoothAvailabilityTests.swift`
    - `docs/device-verification/w2-app-entry.md`
  - Modified:
    - `Sources/App/SceneDelegate.swift`
    - `Sources/App/AppDelegate.swift`
    - `Sources/Features/TransportPoC/TransportPoCHostController.swift`
  - Removed: (none)
- Dependencies: 不新增任何第三方套件。
- Platform: 不新增背景模式或權限；藍牙狀態的呈現沿用 W1 已建立的連線狀態型別。
