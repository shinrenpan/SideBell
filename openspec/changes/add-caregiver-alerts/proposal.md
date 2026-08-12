## Why

患者端已經完整：格子、單擊送出、三種狀態、確認閉環全部通過雙機實測。但照顧者端至今仍是 W1 那個丟棄式的傳輸驗證畫面——收到呼叫只會靜靜地多一列文字，**沒有任何聲音**。照顧者把手機放在口袋、或人在另一個房間，患者按了也不會有人知道。

這是整個產品唯一不能失敗的環節：患者已經付出凝視數秒的代價送出求助，若照顧者端不出聲，前面所有的工作都沒有意義。相較之下格子編輯的缺席只是「不能自訂」，預設四格仍可使用。

同時它解除兩項阻塞：`Sources/Features/TransportPoC/` 是 W1 就標記為丟棄式的畫面，在照顧者端有正式畫面之前刪不掉；而比賽的 demo 影片必須拍出完整閉環（患者按下 → 照顧者被警報叫醒 → 按確認 → 患者看到回應），少了中間那段只能拍半個故事。

## What Changes

- 照顧者端的「呼叫」分頁改為正式的呼叫清單：顯示收到的呼叫、來源患者、觸發時間，以及本機是否已確認。
- 收到呼叫時發出警報：音效（以 `AVAudioSession` 的 `.playback` 類別播放，靜音開關開啟時仍出聲）、語音播報項目名稱、震動。
- 緊急呼叫（`isUrgent`）的警報重複播放直到照顧者確認，一般呼叫只響一次。
- App 在背景或鎖屏時改以本地通知呈現；通知權限於照顧者角色首次進入時請求，被拒絕不影響前景警報。
- 照顧者按「已收到」即回寫 Ack，患者端格子轉為「已確認」——閉環行為沿用 `call-transport` 既有的 ack 路徑，本片只補上正式的觸發介面。
- 警報停止的條件明確化：按下確認即停；未確認的緊急呼叫在三分鐘逾時後也停（患者端此時已轉為「無人回應」，繼續響會與患者端的狀態不一致）。
- **BREAKING**：移除 `Sources/Features/TransportPoC/` 四件套與其在照顧者容器中的掛載。W1 與 W2 驗證清單中依賴該畫面的項目，改以本片的正式畫面重跑。

## Non-Goals

- 歷史呼叫紀錄與依日期分組的統計——需要持久化的 `CallRecord` 資料模型，屬後續里程碑。本片的呼叫清單僅存在記憶體，與 `call-delivery` 既有的「呼叫狀態不持久化」一致。
- 多患者的介面呈現。傳輸層已以集合管理連線，但本片的清單只呈現單一患者。
- Critical Alerts entitlement（勿擾模式下強制響鈴）——需向 Apple 申請，spec 標為 `[v2]`。
- 自訂警報音檔與音量調整介面。本片使用單一內建音效，音量策略留給實機驗證後再定（spec 議程第 4 項）。
- 患者端的任何改動。本片不碰 `Sources/Features/PatientGrid/`。
- 照顧者端設定分頁的內容擴充（贊助頁、暱稱設定）——維持 W2 建立的骨架。

## Capabilities

### New Capabilities

- `caregiver-calls`: 照顧者端呼叫清單的呈現與確認行為——收到的呼叫如何列出、確認的觸發與其對患者端的效果、背景期間累積的呼叫在畫面出現時如何補上。
- `caregiver-alert`: 收到呼叫時的警報行為——音效與靜音開關的關係、語音播報、震動、緊急呼叫的重複規則、警報的停止條件、App 在背景時改以本地通知呈現。

### Modified Capabilities

(none)

## Impact

- Affected specs: `caregiver-calls`、`caregiver-alert`（皆為新建）
- Affected code:
  - New:
    - `Sources/Core/Alert/AlertPlayer.swift`
    - `Sources/Core/Alert/AlertPolicy.swift`
    - `Sources/Core/Notification/CallNotifier.swift`
    - `Sources/Features/CaregiverCalls/CaregiverCallsHostController.swift`
    - `Sources/Features/CaregiverCalls/CaregiverCallsView.swift`
    - `Sources/Features/CaregiverCalls/CaregiverCallsViewModel.swift`
    - `Sources/Features/CaregiverCalls/CaregiverCallsViewModel+Models.swift`
    - `Sources/Features/CaregiverCalls/CaregiverCallsMocks.swift`
    - `Sources/Resources/Alert.caf`（App 播放用，內含循環間隔）
    - `Sources/Resources/AlertNotification.caf`（通知用，無間隔）
    - `Tests/AlertTests/AlertPolicyTests.swift`
    - `docs/device-verification/w4-caregiver-alerts.md`
  - Modified:
    - `Sources/App/AppDelegate.swift`
    - `Sources/App/AppRouter.swift`
    - `Sources/App/Info.plist`
    - `Sources/Features/CaregiverHome/CaregiverHomeContainer.swift`
    - `Sources/Core/CallCenter.swift`
  - Removed:
    - `Sources/Features/TransportPoC/TransportPoCHostController.swift`
    - `Sources/Features/TransportPoC/TransportPoCView.swift`
    - `Sources/Features/TransportPoC/TransportPoCViewModel.swift`
    - `Sources/Features/TransportPoC/TransportPoCViewModel+Models.swift`
- Dependencies: 不新增第三方套件。使用系統的 `AVFoundation`（音效與語音）與 `UserNotifications`（本地通知）。
- Platform: 新增 `audio` 背景模式（spec 第 6.2 節已拍板，W1 刻意延後至警報功能才加入）；新增本地通知權限請求。
