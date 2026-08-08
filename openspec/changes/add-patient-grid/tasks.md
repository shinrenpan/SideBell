## 1. 格子儲存（測試先行）

- [x] [P] 1.1 在 `Tests/PersistenceTests/GridItemStoreTests.swift` 撰寫失敗測試，涵蓋 `Grid items are stored on the device`、`Grid order is explicit and stable`、`Item content stays within the wire format limits`（逐列對照 `grid-storage` spec 的五種驗證情形）與 `A first launch is seeded with four default items`（含「刻意清空後不重新種子」）。驗證：測試存在且因尚未實作而失敗。
- [x] 1.2 依「呼叫狀態只存在記憶體，格子項目才進資料庫」與「預設格子以是否種過為判準，不以是否為空」實作 `Sources/Core/Persistence/GridItemModel.swift`、`GridItemStore.swift`、`SideBellModelContainer.swift`，使 1.1 全數通過。驗證：測試全綠；種子旗標與角色設定同層儲存，清空格子後重啟不會被塞回預設項目。

## 2. 呼叫生命週期（測試先行）

- [x] [P] 2.1 在 `Tests/DeliveryTests/CallDeliveryTests.swift` 撰寫失敗測試，涵蓋 `A call that cannot be sent is queued rather than failed`、`Pending calls are sent when the connection returns`（含多筆依序送出）、`A call gives up after three minutes without a response`（逐列對照 `call-delivery` spec 的四種組合）、`The patient sees three call states and no more` 與 `Call state does not survive a restart`。驗證：測試存在且失敗；逾時測試以可注入的時間來源驅動，不得真的等待三分鐘。
- [x] 2.2 依「呼叫狀態機獨立於 Core，不長在 ViewModel 裡」建立 `Sources/Core/Delivery/CallDelivery.swift` 與 `PendingCall.swift`，使 2.1 全數通過。驗證：測試全綠；以 grep 確認 `Sources/Features/` 下無任何檔案持有待送佇列或逾時計時器。
- [x] 2.3 依「重送以連線事件觸發，不做定時輪詢」與「逾時的計時起點是患者按下，不是送出」接上傳輸層事件，並修改 `Sources/Core/CallCenter.swift` 轉發連線狀態變化。驗證：單元測試斷言「連線事件到達時待送呼叫立即送出」，且逾時自觸發時刻起算——一則排隊兩分鐘後才送出的呼叫，於觸發後第三分鐘逾時而非第五分鐘。

## 3. 患者端畫面

- [x] 3.1 依「格子欄數依可用寬度自適應，不寫死」在 `Sources/Features/PatientGrid/` 建立四件套與 `PatientGridMocks.swift`，滿足 `The grid fills the screen with large targets`。驗證：iPhone 直向與 iPad 橫向的欄數不同，且兩者每格短邊皆不小於 150pt、間距不小於 24pt。
- [x] 3.2 實作格子觸發，滿足 `A single tap sends the call`：單擊即送出，無確認步驟、無其他手勢。驗證：以 grep 確認格子的觸發路徑未使用 long press、double tap、swipe 或 drag；實機上單擊即送出。
- [x] 3.3 依「狀態以符號與文字表達，顏色只是輔助」實作每格的狀態呈現，滿足 `Each cell shows the state of its own most recent call` 與 `Call state is conveyed by more than colour`。驗證：三種狀態各有不同符號，去除顏色後仍可區分；VoiceOver 聚焦時朗讀標題與狀態；重複觸發同一格會以新狀態取代舊狀態。
- [x] 3.4 在導覽列左側實作常駐連線指示，滿足 `Connection status is permanently visible`。驗證：格子捲動至任意位置指示仍可見；照顧者離開範圍後數秒內指示改變，無需患者操作；不單靠顏色區分。

## 4. 回饋與輔助

- [x] 4.1 依「語音播報只播最新一則，不排隊」建立 `Sources/Core/Speech/CallAnnouncer.swift`，滿足 `Triggering a cell is announced aloud`。驗證：實機上觸發格子會唸出標題；連續快速觸發多格時只聽到最後一則，不會依序播完。
- [x] 4.2 依「確認到達時發出震動與音效，不只更新畫面」建立 `Sources/Core/Feedback/CallFeedback.swift`，滿足 `Acknowledgement is felt or heard, not only seen`。驗證：實機上確認到達時有可感知的回饋；失敗的回饋與確認明顯不同；**iPad 上無震動硬體，故音效不可省略**——在 iPad 上僅以音效即可辨識。
- [x] 4.3 依「防休眠在患者容器的顯示與消失時切換」修改 `Sources/Features/PatientHome/PatientHomeContainer.swift`，滿足 `The patient screen keeps the display awake`。驗證：患者畫面靜置超過系統自動鎖定時間後螢幕仍亮；離開角色後恢復正常鎖定行為（回到首頁靜置後會自動鎖屏）。

## 5. 驗證

- [x] 5.1 建立 `docs/device-verification/w3-patient-grid.md`，涵蓋單擊送出與語音、確認回饋、離開範圍後自動送出、三分鐘逾時、螢幕不自動鎖定、VoiceOver 朗讀、兩種裝置的版面，每項含前置條件、步驟、預期結果、實際結果與 OS 版本欄位。驗證：文件涵蓋本 change 全部實機驗收項目，逐項可獨立執行。
- [x] 5.2 執行並記錄基本路徑驗證：單擊送出、語音播報、照顧者確認後的震動或音效回饋、格子狀態轉換。驗證：清單中填入實際結果與 OS 版本。
- [x] 5.3 執行並記錄重送與逾時驗證：照顧者離開範圍時送出呼叫（應維持等待中而非失敗）、照顧者回來後自動送達、三分鐘無回應轉為「無人回應」。驗證：清單中填入實際結果，並確認等待期間患者端未顯示任何失敗字樣。
- [ ] 5.4 執行並記錄無障礙與版面驗證：VoiceOver 朗讀格子標題與狀態、去色後三種狀態仍可區分、iPhone 與 iPad 的欄數與格子尺寸。驗證：清單中填入實際結果與 OS 版本。
- [ ] 5.5 執行 W1 驗證清單的 V3 與 V7 回歸測試，確認新增的呼叫生命週期未影響傳輸行為。驗證：兩項在新畫面上重跑通過，結果記入 w3 清單的回歸章節。
