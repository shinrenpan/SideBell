## Why

W2 立起了容器，但患者端裡面裝的還是 W1 的傳輸驗證畫面——一顆「送出呼叫（喝水）」的測試按鈕。這是整個產品最核心的畫面：**患者唯一能主動使用的介面**，也是他在無法言語、無法移動時唯一的求助管道。

這一片要把它做出來：超大格子、點一下送出呼叫、清楚知道有沒有人收到。同時把「呼叫送不出去時該怎麼辦」這件事實作完成——那是 spec 第 8 節議程第 2 項剛拍板的內容。

格子的編輯（新增、刪除、改文字、排序）刻意不在這一片：那是照顧者操作的另一個畫面、另一套互動，混在一起會讓兩邊都做不好。

## What Changes

- 建立患者端主畫面：超大格子網格，單擊即送出呼叫，不需要任何手勢。
- 每個格子顯示自己最近一次呼叫的狀態：等待中、已確認、無人回應。
- 導覽列左側常駐連線狀態指示，讓患者隨時知道呼叫送不送得出去。
- 送不出去的呼叫進入待送佇列，於連線恢復時自動送出；三分鐘內未獲回應則標記為無人回應。
- 建立格子的本地儲存，首次啟動時寫入四個預設格子（喝水、翻身、洗手間、不舒服）。
- 患者端容器啟用防休眠，離開角色時關閉。
- 點擊格子時本機語音播報該格子的內容，讓視障或視線不便的患者確認自己按到了什麼。
- 確認到達時以震動或聲音通知患者——那個回饋是他唯一的安心來源，只存在於畫面上的打勾對看不見的患者等於不存在。

## Non-Goals

- 格子編輯——新增、刪除、改文字、排序、設定緊急等級，全部留給下一片。
- 照顧者端的呼叫清單、歷史紀錄、警報與通知。
- 緊急呼叫的差異化行為（重複警報、最高音量）——那屬於照顧者端的警報策略，是議程第 4 項。
- onboarding 教學（不要滑掉 App、引導使用模式、調低亮度）。
- 贊助頁與 RevenueCat。
- 刪除 `Sources/Features/TransportPoC/`：照顧者端仍需靠它驗證傳輸，等照顧者端畫面完成再一併移除。

## Capabilities

### New Capabilities

- `patient-grid`: 患者端主畫面的行為——格子的呈現與觸發、每格的呼叫狀態、連線狀態的常駐呈現、語音回饋、防休眠。
- `call-delivery`: 呼叫送出後的生命週期——送不出去時的待送與自動重送、逾時判定、狀態轉換。此規則不屬於任何單一畫面，且照顧者端未來也會消費它。
- `grid-storage`: 格子項目的本地儲存與預設內容。

### Modified Capabilities

(none)

## Impact

- Affected specs: `patient-grid`、`call-delivery`、`grid-storage`（皆為新建）
- Affected code:
  - New:
    - `Sources/Core/Delivery/CallDelivery.swift`
    - `Sources/Core/Delivery/PendingCall.swift`
    - `Sources/Core/Persistence/GridItemModel.swift`
    - `Sources/Core/Persistence/GridItemStore.swift`
    - `Sources/Core/Persistence/SideBellModelContainer.swift`
    - `Sources/Core/Speech/CallAnnouncer.swift`
    - `Sources/Core/Feedback/CallFeedback.swift`
    - `Sources/Features/PatientGrid/PatientGridHostController.swift`
    - `Sources/Features/PatientGrid/PatientGridView.swift`
    - `Sources/Features/PatientGrid/PatientGridViewModel.swift`
    - `Sources/Features/PatientGrid/PatientGridViewModel+Models.swift`
    - `Sources/Features/PatientGrid/PatientGridMocks.swift`
    - `Tests/DeliveryTests/CallDeliveryTests.swift`
    - `Tests/PersistenceTests/GridItemStoreTests.swift`
    - `docs/device-verification/w3-patient-grid.md`
  - Modified:
    - `Sources/Features/PatientHome/PatientHomeContainer.swift`
    - `Sources/Core/CallCenter.swift`
    - `Sources/App/AppDelegate.swift`
  - Removed: (none)
- Dependencies: 首次引入 SwiftData 與 AVFoundation 的語音合成，兩者皆為系統框架，不新增第三方套件。
- Platform: 不新增背景模式或權限。
