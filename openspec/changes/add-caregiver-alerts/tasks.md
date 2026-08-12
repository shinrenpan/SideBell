## 1. 警報政策（測試先行）

- [x] [P] 1.1 在 `Tests/AlertTests/AlertPolicyTests.swift` 撰寫失敗測試，逐列對照 `caregiver-alert` spec 的 `Urgent calls repeat until answered` 與 `The alert stops on three conditions and no others`：緊急呼叫持續要求警報、非緊急只要求一次、確認後停止、患者按下起算三分鐘後停止（含「排隊兩分鐘才送達的呼叫於患者按下後第三分鐘停止，而非第五分鐘」）、兩則未確認時確認其中一則後仍要求警報、離開角色後全部停止、多則未確認時同時只有一個警報。驗證：測試存在且因尚未實作而失敗；逾時測試以可注入的時間來源驅動，不得真的等待三分鐘。
- [x] 1.2 依「警報政策與播放分離」與「警報的停止條件有三個，且都不需要患者端配合」建立 `Sources/Core/Alert/AlertPolicy.swift`，持有未確認呼叫集合，提供加入、標記已確認、掃描逾時、查詢是否應有警報四個操作；逾時自 `CallMessage.timestamp`（患者按下時刻）起算，不依賴患者端傳來任何額外訊息。使 1.1 全數通過。驗證：測試全綠；以 grep 確認該檔未 import AVFoundation 或 UIKit。

## 2. 警報播放與通知

- [x] 2.1 依「音訊類別的選項依當下情況動態決定」建立 `Sources/Core/Alert/AlertPlayer.swift`（開始播放、停止兩個操作，內部持有 `AVAudioPlayer` 與 `AVSpeechSynthesizer`）並加入 `Sources/Resources/Alert.caf`，滿足 `An arriving call raises an alert` 與 `The alert is heard in every situation the platform permits`。驗證：實機上前景靜音時仍出聲；背景且他人正在播放時仍出聲且對方被壓低；音效載入失敗時語音與震動仍執行；`AVAudioPlayer.play()` 的回傳值不得被忽略。
  > 原任務要求「播放時正在播放的音樂被中斷而非混音」，已於 2026-08-11 依實測改寫——iOS 不允許背景 App 中斷前景 App 的音訊，改為 duck。同時確立「靜音 ＋ 背景」為平台限制，改以誠實告知處理，見 `DECISIONS.md`。
- [x] 2.2 依「音訊工作階段在角色啟動時就設定並啟用」修改 `Sources/App/AppDelegate.swift`，於進入照顧者角色時設定 `AVAudioSession` 並啟用、離開角色時停用，並處理中斷通知以滿足 `An interrupted alert resumes`。驗證：以 grep 確認音訊工作階段的設定不在任何 View 或 ViewModel 中；實機上背景 30 分鐘後收到呼叫仍能出聲；來電中斷後若仍有未確認的緊急呼叫則恢復播放。
- [x] 2.3 依「背景時同時走通知與音訊兩條路徑」建立 `Sources/Core/Notification/CallNotifier.swift`（請求權限、送出呼叫通知兩個操作），滿足 `A call arriving in the background is visible on the lock screen`：App 不在前景時，通知與音訊兩條路徑同時發出。驗證：實機鎖屏時通知顯示項目名稱與來源患者，且警報聲不受通知本身是否靜音影響。
- [x] 2.4 依「通知權限被拒不影響前景警報」把權限請求接上 `Sources/App/AppRouter.swift` 的進入照顧者角色路徑，滿足 `Permission to notify is requested at a moment the caregiver understands`。驗證：權限請求不發生於 App 啟動；拒絕後不再重複請求；未授權時送出通知的路徑靜默略過，音訊警報仍照常。
- [x] 2.5 於 `Sources/App/Info.plist` 加入 `audio` 背景模式（spec 6.2 已拍板）。驗證：實機上 App 在背景時警報仍出聲。

## 3. 照顧者端呼叫畫面

- [x] 3.1 依「呼叫清單只存在記憶體，沿用 `CallCenter` 既有的快照」在 `Sources/Features/CaregiverCalls/` 建立四件套與 `CaregiverCallsMocks.swift`，列出 `CallCenter.receivedCalls`（新的在前），每列顯示項目名稱、來源患者、患者按下時間與本機確認狀態，滿足 `The caregiver sees the calls that arrived` 與 `Call state does not survive a restart`。驗證：畫面出現時讀得到背景期間累積的呼叫；同一識別碼的呼叫不重複列出；重啟 App 後清單為空。
- [x] 3.2 實作確認動作，滿足 `Acknowledging a call closes the loop`：單一動作即送出 Ack，成功後該列標記為已確認，並通知 `AlertPolicy` 停止該則警報。驗證：雙機上按下確認後患者端格子轉為「已確認」且警報立即停止。
- [x] 3.3b 依實測發現補上逾時的呈現：滿三分鐘的呼叫標示為「無人回應」且不再提供確認按鈕，滿足 `A call the patient has given up on cannot be acknowledged`；等待中的呼叫改以相對時間呈現，滿足 `The waiting time is shown as elapsed time`。驗證：畫面開著時該列會自行轉為無人回應，無需照顧者操作；已確認與已逾時的列顯示絕對時間。
  > 2026-08-12 實機發現：逾時的呼叫在照顧者端仍顯示可按的「已收到」，而按下去雖然送得出 Ack，患者端那格早已顯示「無人回應」不會有變化——照顧者會以為患者知道有人要來了。原 spec 未涵蓋此情境，一併補上。
- [x] 3.3 依「Ack 寫入失敗時警報不停止」實作失敗路徑：該列維持未確認、畫面明確呈現「確認未送達」、可重試。驗證：關閉患者端藍牙後按確認，畫面顯示未送達、該列未被標記為已確認、警報未停止。
- [x] 3.4 依 `patient-grid` 既有的連線指示做法，在照顧者端呈現常駐連線狀態，滿足 `The caregiver screen shows whether calls can arrive`。驗證：患者端離開範圍後數秒內指示改變；符號與文字皆不同，不單靠顏色。
- [x] 3.5 把 `AlertPolicy`、`AlertPlayer`、`CallNotifier` 接上 `Sources/Core/CallCenter.swift` 的事件，並在 `Sources/Features/CaregiverHome/CaregiverHomeContainer.swift` 以新畫面取代 TransportPoC 的掛載。驗證：收到呼叫時警報與清單同時反應；確認後警報停止；離開照顧者角色後警報停止。

## 4. 清理

- [x] 4.1 在雙機上確認新畫面可完成完整閉環之後，刪除 `Sources/Features/TransportPoC/` 四件套。驗證：以 grep 確認全專案無任何檔案引用 TransportPoC；建置與測試全綠。

## 5. 驗證

- [x] 5.1 建立 `docs/device-verification/w4-caregiver-alerts.md`，涵蓋靜音開關開啟時仍出聲、其他音訊被中斷、鎖屏時的通知與聲音、背景 30 分鐘後的警報、來電中斷後恢復、緊急呼叫的重複與三分鐘停止、確認閉環、Ack 失敗的呈現、通知權限被拒後的降級，每項含前置條件、步驟、預期結果、實際結果與 OS 版本欄位。驗證：文件涵蓋本 change 全部實機驗收項目，逐項可獨立執行。
- [ ] 5.2 執行並記錄警報驗證：靜音開關、音訊中斷與恢復、緊急重複與三分鐘停止、背景與鎖屏、通知權限被拒的降級。驗證：清單中填入實際結果與 OS 版本。
- [x] 5.3 執行並記錄閉環驗證：確認送達患者端、Ack 失敗的呈現、背景期間累積的呼叫在畫面出現時補上。驗證：清單中填入實際結果。
- [x] 5.4 執行 W1 驗證清單中原本依賴 TransportPoC 畫面的項目，於新畫面上重跑。驗證：結果記入 w4 清單的回歸章節。
