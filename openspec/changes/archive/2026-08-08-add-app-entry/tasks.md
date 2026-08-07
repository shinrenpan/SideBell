## 1. 儲存與藍牙可用性基礎

- [x] [P] 1.1 依「免責確認與角色同層儲存」建立 `Sources/Core/Role/DisclaimerStore.swift`，滿足 `Role is persisted and readable before transport start` 中新增的同步讀取要求：確認狀態可於場景配置時同步讀出，不需載入資料庫。驗證：`Tests/RoleTests/DisclaimerStoreTests.swift` 斷言預設未確認、標記後為已確認、以同一份儲存重建後仍為已確認（測試先行）。
- [x] [P] 1.2 建立 `Sources/Core/Transport/BluetoothAvailability.swift`：不需選定角色即可觀察藍牙狀態，並依「藍牙可用性只採信明確狀態，未判定一律放行」把 `CBManagerState` 映射為既有的 `BluetoothUnavailability`，未判定與重設中回 nil。驗證：映射邏輯的單元測試逐列對照 `role-selection` spec 的範例表六種組合。
- [x] 1.3 讓可用性觀察者在免責確認之後才建立，使藍牙權限請求出現在使用者已看過說明的時點。驗證：實機首次啟動時，勾選確認之前不出現系統藍牙權限對話框，勾選後才出現。

## 2. 導航中樞

- [x] 2.1 依「導航集中於 AppRouter，畫面不自行操作導覽控制器」建立 `Sources/App/AppRouter.swift`，提供進入指定角色、離開角色回首頁、開啟角色設定三個操作；stateless、由 `source.navigationController` 動態取得，nil 時 `assertionFailure`。驗證：以 grep 確認 Features 目錄下無任何檔案直接操作 `navigationController` 或呼叫 `present` / `dismiss`。
- [x] 2.2 依「首頁為根畫面，角色容器以全螢幕呈現而非推入堆疊」實作進入角色的轉場，滿足 `Choosing a role opens its container full screen`。驗證：實機上選擇任一角色後容器全螢幕呈現，且以除錯器確認根導覽控制器仍持有首頁。
- [x] 2.3 依「離開角色時停止該角色的傳輸活動」實作返回首頁，滿足 `Either role can return to the home screen`。驗證：從照顧者端設定切換角色後回到首頁，log 出現 `central: stop 被呼叫`；患者端同理出現 `peripheral: stop 被呼叫`。

## 3. 首頁

- [x] 3.1 依「首頁說明區可捲動，角色按鈕釘在底部」在 `Sources/Features/RoleSelection/` 建立首頁四件套，滿足 `Disclaimer is permanently present on the home screen` 與 `Role buttons stay reachable regardless of content length`：免責聲明於任何一次啟動皆無需捲動或展開即可見。驗證：實機上重啟 App 多次，聲明恆在首屏可見範圍內。
- [x] 3.2 實作免責確認控制項，滿足 `First launch requires explicit acknowledgement of the disclaimer`：未確認時兩顆角色按鈕停用，確認後啟用，且再次啟動不重複詢問。驗證：實機首次啟動按鈕為停用；勾選後啟用；重啟 App 後確認控制項不再出現且按鈕可用。
- [x] 3.3 實作角色按鈕的可用性判斷，滿足 `Role selection is blocked only when Bluetooth is definitively unavailable`：停用時須顯示可區分的原因（需確認免責／藍牙已關閉／未授權／不支援）。驗證：ViewModel 單元測試逐列對照 spec 範例表；實機上關閉藍牙後按鈕停用並顯示原因，開啟後自動恢復。

## 4. 角色容器

- [x] [P] 4.1 依「角色容器的主畫面暫時沿用傳輸驗證畫面」與「患者端不設分頁列，設定入口採兩步驟確認」建立 `Sources/Features/PatientHome/PatientHomeContainer.swift`，滿足 `The patient role has no persistent navigation controls`：導覽列隱藏、內容佔滿全螢幕、右上角設定控制項需連續兩次點擊。驗證：實機上點一次不開啟且控制項變為「再按一次」、三秒內再點一次可進入設定、超過三秒自動取消；畫面無分頁列。
- [x] [P] 4.2 依「照顧者端為分頁容器，兩個分頁各自持有導覽堆疊」建立 `Sources/Features/CaregiverHome/CaregiverHomeContainer.swift`：兩個分頁，各自包在導覽控制器內。驗證：實機上兩個分頁皆可切換，且分頁一內可正常運作傳輸驗證畫面。
- [x] 4.3 在 `Sources/Features/RoleSettings/` 建立兩端共用的最小設定畫面四件套，僅提供「切換角色」。驗證：兩端皆可由此返回首頁，且返回後首頁的角色按鈕可再次選擇。
- [x] 4.4 依「啟動時依既有角色決定去向，且不帶轉場動畫」修改 `Sources/App/SceneDelegate.swift`，滿足 `A previously chosen role bypasses the home screen` 與 `UIKit lifecycle entry point hosting SwiftUI` 修改後的根結構。驗證：實機上已選角色時重啟 App，畫面直接停在角色容器且無首頁閃現；未選角色時停在首頁。

## 5. 無障礙

- [x] 5.1 依「無障礙隨畫面實作，不留到後期打磨」為首頁的所有互動元素加上無障礙標籤與提示，滿足 `The home screen is fully operable with VoiceOver`：角色按鈕須說明用途而非只讀出字面、停用時須說明原因（需確認免責／藍牙已關閉），免責聲明可被導覽到。驗證：實機開啟 VoiceOver，逐一聚焦所有元素，確認朗讀內容符合上述四個場景。
- [x] 5.2 確認首頁的朗讀順序為免責聲明 → 確認控制項 → 患者端按鈕 → 照顧者端按鈕，與視覺順序一致。驗證：實機以 VoiceOver 由上往下滑動導覽，記錄實際順序。
- [x] 5.3 驗證患者端設定控制項在 VoiceOver 下可用兩次標準雙擊開啟，且第一次後有朗讀通知。驗證：實機以 VoiceOver 雙擊設定控制項，應聽到「再按一次以開啟設定」，再雙擊後設定畫面開啟；需重試即視為未通過。

## 6. 驗證

- [x] 6.1 建立 `docs/device-verification/w2-app-entry.md`，涵蓋首次啟動流程、重啟直接進入角色、切換角色回首頁、藍牙開關時按鈕狀態、患者端兩步驟確認的行為，每項含前置條件、步驟、預期結果、實際結果與 OS 版本欄位。驗證：文件涵蓋本 change 全部實機驗收項目，逐項可獨立執行。
- [x] 6.2 執行並記錄眼控誤觸驗證。驗證：以眼控在患者端設定控制項上反覆停留，記錄能否在三秒內完成兩次精準觸發而開啟設定；若能輕易觸發，則兩步驟方案的防護不足，需加大兩步驟之間的位置差異並回頭修改 `role-selection` spec。
- [x] 6.3 執行 W1 驗證清單的 V3 與 V7 回歸測試，確認骨架改動未使傳輸行為退化。驗證：`docs/device-verification/w1-ble-poc.md` 的 V3（呼叫送達與確認閉環）與 V7（鎖屏背景送達）在新骨架上重跑通過，結果記入 w2 清單的回歸章節。
