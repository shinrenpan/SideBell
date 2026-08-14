## 1. App Store Connect 前置作業（需開發者手動執行，與程式並行）

> 這一階段**不寫程式，但有等待時間**，是本片最可能卡住的地方。應在實作開始的同時送出，不要等程式完成。

- [x] 1.1 **開發者操作**：於 App Store Connect 完成稅務與銀行資訊（「協議、稅務與銀行業務」）。驗證：付費 App 協議狀態為「有效」——未生效前，沙盒購買會失敗且錯誤訊息不會指出真正的原因。
- [x] 1.2 **開發者操作**：建立三個消耗性內購商品，識別碼與價格依 spec 第 5 節：`com.shinrenpan.sidebell.tip.small`（US$0.99）、`…tip.medium`（US$2.99）、`…tip.large`（US$8.99），各填寫繁中與英文的顯示名稱與描述。驗證：三個商品的狀態皆為「準備提交」或更後續的狀態；**且商品 ID 與 `SponsorshipProduct` 的 rawValue 逐字相同**（見 2.3 的補記）。
- [x] 1.3 **開發者操作**：於 RevenueCat 主控台建立專案、串接 App Store Connect 的 App 專用共用密鑰，並確認三個商品可被 RevenueCat 讀取。驗證：RevenueCat 的商品列表出現三個品項。
- [x] 1.4 **開發者操作**：於 RevenueCat 主控台建立 **Test Store** 並取得其 `test_` 開頭的 API key，填入 `Config/Secrets.xcconfig`。Test Store（SDK 內部名 Simulated Store）把購買換成 SDK 自己彈的系統 alert，提供「購買／失敗／取消」三個結果，**完全不碰 App Store**——不需要沙盒帳號，商品也不必先過審。Release build 誤用 `test_` key 時 SDK 會自行跳警告擋下。驗證：以該 key 建置後開啟贊助頁，三個方案載入成功且點選後出現模擬購買 alert。

  > **補記（2026-08-13）**：Test Store 的 app 本身雖已存在，**底下卻沒有任何商品**——App Store 側的三個商品不會自動出現在 Test Store，兩者的商品目錄是各自獨立的。已透過 RevenueCat API 於 Test Store 補建三個 consumable（識別碼與 App Store 側逐字相同，價格 US$0.99／$2.99／$8.99 與 NT$30／$90／$290）。未補建之前，即使 `test_` key 填對了，`products()` 一樣回空陣列。

## 2. 依賴與資料層（測試先行）

- [x] 2.1 依「RevenueCat 的型別不得洩漏出 `Sources/Core/Sponsorship/`」與「RevenueCat SDK 的初始化在 App 啟動時完成，但不阻塞任何路徑」於 `project.yml` 加入 RevenueCat 的 Swift Package 依賴，並在 `Sources/App/AppDelegate.swift` 完成 SDK 初始化（設定 API key，不發出任何網路請求；商品載入延後到贊助頁出現時）。驗證：建置通過；以 grep 確認 `Sources/Features/` 與 `Sources/Core/` 下除 `Sponsorship` 目錄外無任何 RevenueCat 的 import。
- [x] 2.2 [P] 在 `Tests/SponsorshipTests/SponsorshipStateTests.swift` 撰寫失敗測試，以可注入的假 store 驅動、不接觸真實金流，涵蓋：載入成功後三個方案皆呈現、載入失敗時狀態為「需要網路且可重試」而非空清單、使用者取消不產生錯誤訊息、其他失敗產生可讀訊息、購買成功後標記為已支持。驗證：測試存在且因尚未實作而失敗。
- [x] 2.3 依「商品清單寫死在程式裡，不從遠端取得」建立 `Sources/Core/Sponsorship/SponsorshipProduct.swift`，以列舉定義三個方案的識別碼與用途說明（價格不寫死，由 App Store 提供），滿足 `Each option states what the money is for`。驗證：識別碼與 App Store Connect 的三個商品**逐字**一致——含 bundle ID 前綴的完整 product ID，以 RevenueCat 的商品列表（或 `list-products` API）比對，不憑記憶。

  > **補記（2026-08-13）**：本任務初次標記完成時，識別碼寫成不含前綴的 `tip.small`，而商店上是 `com.shinrenpan.sidebell.tip.small`。驗證步驟當時只在 spec、design 與程式碼之間互相比對——三者一致，於是看起來通過了，但沒有一方是**商店的實際狀態**。這條路徑沒有任何自動測試會失敗（單元測試以假 store 驅動），若未在此攔下，真機測試會 100% 卡在「需要網路連線」，而那個訊息完全指不到真正的原因。日後凡驗證條件寫「與外部系統一致」，必須實際查詢該系統。
- [x] 2.4 依「感謝徽章只記在本機，不向 RevenueCat 查詢」建立 `Sources/Core/Sponsorship/SponsorshipStore.swift`，對外提供載入方案、購買、是否曾經支持過三個操作，滿足 `Thanks is decoration, not a benefit`（Scenario: 離線時仍顯示）。**2.2 的測試驗的是狀態機，而狀態機住在 ViewModel，因此它們要到 3.1 完成後才會轉綠**——artifacts 原本寫成本任務即可轉綠，那是階段劃分的疏漏。驗證：建置通過；RevenueCat 型別未洩漏出 `Sources/Core/Sponsorship/`；已支持的旗標與角色設定同層儲存，離線時仍讀得到。

## 3. 贊助畫面

- [x] 3.1 在 `Sources/Features/Sponsorship/` 建立四件套與 `SponsorshipMocks.swift`，列出三個方案與其在地化價格及用途說明，滿足 `Each option states what the money is for`。驗證：Preview 呈現三個方案；重複購買同一方案不受阻擋。
- [x] 3.2 依「贊助頁是唯一需要網路的畫面，且失敗要說清楚」實作載入失敗的呈現，滿足 `The support screen states plainly when it needs a network`：說明需要網路連線並提供重試，不顯示空清單或無限的載入狀態。驗證：關閉網路後開啟贊助頁，畫面明確說明並可重試。
- [x] 3.3 依「購買失敗分成「使用者取消」與「其他錯誤」」實作購買流程的結果處理，滿足 `Cancelling is not an error`：取消時靜默返回，其他失敗顯示可理解的說明並可重試，不顯示原始錯誤碼。驗證：沙盒環境下取消購買不出現任何錯誤訊息。
- [x] 3.4 於 `Sources/Features/RoleSettings/` 三件套加入「支持開發者」入口與感謝徽章，並在 `Sources/App/AppRouter.swift` 加入開啟贊助頁的轉場，滿足 `The support screen is reachable only from the caregiver side` 與 `Thanks is decoration, not a benefit`。驗證：以 grep 確認 `Sources/Features/PatientGrid/` 與 `Sources/Features/PatientHome/` 不含任何贊助相關識別字；患者端設定畫面無此入口。
- [x] 3.5 依 W5（`add-localization`）建立的流程處理本 change 新增的所有使用者可見字串：字面值一律**英文**且直接寫在 `Text()` 或 `String(localized:)` 內（不得把字串當參數傳給自訂函式，那樣擷取不到），建置後以 `xcrun xcstringstool sync Sources/Resources/Localizable.xcstrings --stringsdata <DerivedData 下每個 .stringsdata>` 併回 catalog，再補繁中翻譯。價格**不自行格式化**，一律使用 App Store 提供的在地化價格字串。驗證：`Localizable.xcstrings` 的 stale 數為 0、缺翻譯數為 0；以 grep 確認 `Sources/Features/Sponsorship/` 與 `Sources/Core/Sponsorship/` 無中文字面值（註解與 `#Preview` 名稱除外）。

## 4. 約束驗證

- [x] 4.1 依「不存在「已解鎖」的概念，程式裡沒有可判斷的旗標」以 grep 確認全專案**不存在**依購買狀態決定功能可用性的判斷，滿足 `Supporting the developer never changes what the app can do`。驗證：已支持的旗標只被設定頁的徽章讀取，沒有任何其他讀取點；全專案無 entitlement 或功能解鎖相關的分支。

## 5. 驗證

- [x] 5.1 建立 `docs/device-verification/w6-sponsorship.md`，涵蓋沙盒帳號的購買流程、重複購買、取消購買、無網路時的呈現、患者端無入口、購買後功能完全不變、以及離線時徽章仍顯示，每項含前置條件、步驟、預期結果、實際結果與 OS 版本欄位。驗證：文件涵蓋本 change 全部實機驗收項目，逐項可獨立執行。
- [x] 5.2 以 **Test Store** 執行並記錄購買驗證：三個方案各購買一次、重複購買同一方案、中途取消、以及模擬失敗。驗證：清單中填入實際結果與 OS 版本；「購買成功」的判準以 App 內徽章出現為準。
- [x] 5.4 **送審前**以 TestFlight 跑一次真實的 StoreKit 路徑（原訂沙盒帳號，卡在雙重認證，改用測試者自己的 Apple ID；前置條件 1–3 已於 2026-08-14 因商品成功載入而間接驗證通過，見 w6 清單 S7）：三個方案各購買一次並確認 RevenueCat 主控台收到交易。Test Store 驗的是我們自己的判斷與接線，**驗不到 App Store 那一側**——付費 App 協議未生效、商品未在該地區上架、銀行資訊不全，這些只有真實路徑才會現形，而它們的錯誤訊息不會指出真正的原因。驗證：三筆交易出現在 RevenueCat 主控台；清單中填入實際結果。
- [x] 5.3 執行並記錄約束驗證：關閉網路後確認呼叫、警報、確認閉環完全不受影響；患者端全畫面無任何購買入口或價格；購買後再次確認所有功能與購買前相同。驗證：清單中填入實際結果。
