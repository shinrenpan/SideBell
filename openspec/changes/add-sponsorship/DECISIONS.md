# add-sponsorship 決策紀錄

## 2026-08-13：以 RevenueCat API 驗證商店設定，發現三處落差

W6 的程式碼在 3:28 PM 已 commit 並 push，當時尚未做過任何真機或 Test Store 驗證。
設定 RevenueCat MCP 後改以 API 直接查詢商店的實際狀態（專案 `projf6b5f821`），
比對 artifacts 與程式碼。查了三件事：商品、Test Store、offering。

### 商品識別碼往程式碼對齊（含 bundle ID 前綴）

**落差**：商店上是 `com.shinrenpan.sidebell.tip.small`（`…medium`／`…large`），
程式與 artifacts 全都寫不含前綴的 `tip.small`。

`Purchases.products(_:)` 收的是 App Store 的 product ID，不是 RevenueCat 自己的
lookup key，因此前綴漏掉時 SDK 回傳空陣列 → `loadPlans()` 走到
`guard !plans.isEmpty` → 拋 `.unavailable` → 畫面呈現「需要網路連線」。
**這個訊息完全指不到真正的原因**，而它剛好與最常見的真實失敗（沒網路）
長得一樣，是最難查的一種。

**決定改程式碼，不改商店。** App Store Connect 的 product ID 建立後無法改名，
只能停用重建；重建要重填價格與繁中／英文雙語 metadata，再重新等狀態，
成本比改一行 rawValue 高出一個量級。反向 DNS 全名本來也是 ASC 的常見慣例。

已改 `SponsorshipProduct` 的 rawValue，並同步 spec 第 5 節、design、proposal、
tasks 1.2／2.3、W6 真機驗證清單。測試與 mocks 都走 `allCases`，不受影響。

### Test Store 補建三個商品

**落差**：Test Store app（`app8d5ca11c2b`）存在，但**底下零商品**——三個商品全掛在
App Store app（`appf561f6b87b`）。兩邊的商品目錄各自獨立，App Store 側的商品
不會自動出現在 Test Store。

這會直接打掉既定的測試分工（`test_` key 日常測試、`appl_` 只在送審前用）：
key 填對了，`products()` 一樣回空。

已透過 API 在 Test Store 補建三個 consumable，識別碼與 App Store 側逐字相同，
價格 US$0.99／$2.99／$8.99 與 NT$30／$90／$290。Test Store 商品要求
user-facing `title`，已填 Small／Medium／Large tip——它會出現在 SDK 的模擬購買
alert 上，App 內顯示的仍是 `SponsorshipProduct.purpose` 的用途文案。

### Offering 刻意留空

專案沒有任何 offering。**不補**：程式碼走
`Purchases.products([identifier])` 直接取商品，不經 offering，這正是
「商品清單寫死在程式裡，不從遠端取得」的實作方式。建一個沒人讀的 offering
只會讓下一個人以為它是活的。

`app_store_connect_api_key_configured: false` 也一併留著——它只影響 RevenueCat
自動同步商品 metadata 與狀態，不影響購買路徑。

## 工作方式：驗證條件寫「與外部系統一致」時，必須查那個系統

task 2.3 的驗證條件原本寫「識別碼與 App Store Connect 的三個商品一致」，
初次標記完成時卻只在 spec、design 與程式碼之間互相比對——三者確實一致，
於是看起來通過了，但**沒有一方是商店的實際狀態**。同一個錯字複製到四個檔案，
只會讓它看起來更像對的。

這條路徑沒有任何自動測試攔得住：單元測試以假 store 驅動狀態機，
不碰真實識別碼——那個設計本身是對的（真實金流無法穩定重現取消與商店不可用），
但它的代價就是識別碼正確性完全落在人工驗證上。

**規則**：凡驗證條件提到外部系統（App Store Connect、RevenueCat、任何主控台），
就實際查詢該系統再打勾，不用互相比對代替。這類設定錯誤的共同特徵是
**錯誤訊息指向錯誤的方向**，發現得越晚越貴。
