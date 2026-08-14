# 上架前檢查清單

> 每次送審前跑一遍。與 `device-verification/` 的 W1–W7 不同，這份**不屬於任何
> 一個 change**——它檢查的是「這包東西能不能出門」，而不是某個功能對不對。

## 為什麼需要這份清單

2026-08-14 為了出 v1.0.0 的第一個 build，一個下午挖出**七個**問題。它們的共同
特徵是：**在平常開發最常走的那條路上都不會出現**，因此各自安穩地活過了先前
標記「✅ 通過」的驗證。

其中三個會直接讓照顧者收不到或看不懂患者的呼叫——也就是這個 App 存在的理由。

> ⚠️ **最重要的一條原則**：驗證清單上的「✅ 通過」記錄的是**那一次的觀察**，
> 不是永久的事實。W4 的 C1 在 8/11 標記通過、白紙黑字寫著「語音『喝水』到位」，
> 8/14 卻發現它回歸了，而且是使用者在日常使用中注意到的。**送審前重跑，不要
> 相信勾勾。**

> 📌 **這份清單自己也會有盲點。** 它寫成後第一次使用就漏掉了 A8（隱私清單）
> ——那一項是人想起來的，不是清單抓到的，而且它足以讓上傳被拒。
> **發現漏項就當場補進來**，否則下次還是會漏同一個。

---

## A. 建置與打包

這一組全部是 8/14 實際踩到的。它們的共同點是 **Debug build 一路正常**，只有在
archive 或上傳時才爆——也就是最沒有時間處理的時候。

| # | 檢查 | 怎麼確認 | 踩過的坑 |
|---|---|---|---|
| A1 | **Release build 編得過** | `xcodebuild -configuration Release build` | `#Preview` 用了 `#if DEBUG` 裡的 mock，自己卻沒包起來 → Release 編不過。**這代表專案從未成功 archive 過** |
| A2 | **設定寫在 `project.yml`** | 改完跑一次 `xcodegen generate`，再確認設定還在 | `project.pbxproj` 由 XcodeGen 生成且**不進版控**，改在那裡下次 generate 就消失 |
| A3 | **API key 是 `appl_`** | `grep REVENUECAT_API_KEY Config/Secrets.xcconfig` | 用 `test_` key 送審**會被拒**（SDK 自己會警告） |
| A4 | **圖示存在且編得進去** | archive 後看 `SideBell.app/` 有 `AppIcon60x60@2x.png`（120×120）與 `AppIcon76x76@2x~ipad.png`（152×152） | 專案原本連 `.xcassets` 都不存在，`ASSETCATALOG_COMPILER_APPICON_NAME` 卻設著 |
| A5 | **`CFBundleIconName` 有值** | `PlistBuddy -c 'Print :CFBundleIconName' <app>/Info.plist` | 自訂 `Info.plist` 的專案**不會自動注入**這個鍵，缺了它上傳被擋（錯誤碼 90713） |
| A6 | **出口合規已申報** | `Info.plist` 有 `ITSAppUsesNonExemptEncryption` | 沒有的話每個 build 上傳後都要手動回答一次 |
| A7 | **版本號與 build 號** | `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` | build 號重複會被 App Store Connect 拒收 |
| A8 | **隱私清單存在且涵蓋所有 Required Reason API** | archive 後確認 `SideBell.app/PrivacyInfo.xcprivacy` 存在；比對程式碼實際用到的 API | 自 2024-05-01 起，**沒有宣告的 App 不被 App Store Connect 接受**（ITMS-91053）。本專案用 `UserDefaults`（四處），理由 `CA92.1` |

> **A8 補充**：第三方 SDK 的宣告由 SDK 自己負責——RevenueCat 自帶
> `PrivacyInfo.xcprivacy`，SPM 會打包進 `RevenueCat_RevenueCat.bundle/`，不必也
> 不該在 App 的清單裡重複宣告。
>
> **新增依賴或改動儲存方式時要回頭看這一項。** 其餘 Required Reason 類別
> （檔案時間戳、開機時間、磁碟空間、鍵盤）目前都沒用到，用了就要補宣告。

### 工具陷阱

- **`exportArchive` 要避開 Homebrew 的 rsync**：Apple 的匯出流程與 rsync 3.x 不相容，
  症狀是 `Copy failed` ＋ log 裡的 `rsync error: syntax or usage error`。解法是把
  PATH 收乾淨：

  ```bash
  env PATH=/usr/bin:/bin:/usr/sbin:/sbin xcodebuild -exportArchive ...
  ```

- **zsh 有內建的 `log` 命令**，會搶走 `log show`。查 log 一律用 `/usr/bin/log`。

---

## B. 功能驗證

### B1. 冷啟動路徑的警報 ⚠️ 最容易漏

**App 被系統回收後由 BLE 事件喚醒**時，畫面永遠不會出現。任何綁在畫面生命週期
上的準備工作，在這條路徑上都不會發生。

**三秒重現法**（不必等一整夜）：

1. Xcode run 到照顧者端 → 兩端連線
2. **停止 Xcode**（`Debug session ended with code 9: killed`）
3. 確認患者端**仍顯示連線**
4. 患者端送一則呼叫

> **為什麼這等於真實情境**：Xcode 停止 debug 與系統記憶體回收，對 CoreBluetooth
> 而言都不是「使用者主動終止」，兩者都會觸發 state restoration。
>
> **使用者從切換器滑掉則完全不同**：restoration 被**停用**、連線立即取消，患者端
> 會看到未連線。分不清這兩者，就會把冷啟動的症狀誤診成音訊設定問題。

判讀（`subsystem:com.shinrenpan.sidebell`）：

| log | 意義 |
|---|---|
| `central: 狀態還原，交還 N 個對端` | 確認走的是冷啟動路徑 |
| `音訊就緒 options=…` | 音訊有備妥。**這行不在 = 音訊從未啟用** |
| `播放 started=true` | 警報音真的出來了 |

### B2. 一般呼叫與緊急呼叫**分開測**

> 8/14 的教訓：只測「不舒服」（緊急）會漏掉一般呼叫的語音缺失。緊急呼叫的語音
> 由重複迴圈驅動、排在五秒後，正好躲開所有會蓋掉它的東西——**它的正常是僥倖，
> 不能代表一般呼叫**。

| 送出 | 預期 |
|---|---|
| 一般呼叫（如「喝水」） | 音效 ＋ **語音唸出項目名稱** ＋ 震動，各一次 |
| 緊急呼叫（「不舒服」） | 同上，且每 5 秒重複到確認或逾時 |
| 緊急響起後按確認 | 聲音與語音**立刻停止**，且不再多唸一次 |

### B3. 前景與背景**分開測**

同一個缺陷在兩處的表徵不同，只測一邊會以為是兩個問題（或只發現一個）：

- **前景**：看清單、聽語音。前景**不送通知**（避免橫幅擋住清單），所以通知音測不到
- **背景／AOD**：聽警報與通知音，看鎖屏通知

### B4. 金流走真實 StoreKit 路徑

Test Store 驗的是自己的判斷與接線，**驗不到 App Store 那一側**——付費 App 協議、
商品上架地區、銀行資訊，這些只有真實路徑才會現形，而它們的錯誤訊息**不會指出
真正的原因**。

送審前用 **TestFlight**（測試者自己的 Apple ID，不需要沙盒帳號）跑一次，確認
RevenueCat 主控台收到交易。詳見 `device-verification/w6-sponsorship.md` S7。

> 沙盒帳號那條路會卡在雙重認證，TestFlight 沒有這個問題。

---

## B5. 商店截圖

`./scripts/screenshots.sh` 產出 8 張（兩裝置 × 兩語言 × 兩角色）到
`build/screenshots/`，尺寸直接就是規格要求的，不需要後製。

| 需求 | 模擬器 | ASC 的 display type |
|---|---|---|
| iPhone 6.9" → 1320×2868 | iPhone 17 Pro Max | `APP_IPHONE_67` |
| iPad 13" → 2064×2752 | iPad Pro 13-inch | `APP_IPAD_PRO_3GEN_129` |

> Apple **沒有**為 6.9" 與 13" 開獨立的 display type，兩者併入上一代的集合。
> 找不到 `APP_IPHONE_69` 是正常的，不要以為是 API 版本不對。

### 四個會擋住你的坑（都已在腳本裡處理）

1. **模擬器沒有 CoreBluetooth** — 連線狀態永遠是「未連線」、照顧者端清單永遠
   空的。靠 `ScreenshotTransport`（`#if DEBUG` ＋ 啟動參數
   `-SideBellScreenshotMode`）演出真實狀態。
2. **通知權限對話框蓋住畫面** — 截圖模式跳過請求。若模擬器裡還有殘留的對話框，
   `xcrun simctl erase <device>` 清掉。
3. **切語言後格子仍是舊語言** — 那些是資料庫的種子資料，以第一次啟動時的語言
   寫入。腳本每個語言前重裝 App 讓種子重新產生。
4. **實機截圖尺寸對不上** — iPad 尤其：mini 的長寬比 0.657、13 吋是 0.75，
   等比縮放會留下大片黑邊。用模擬器的原生解析度才對得上。

> ⚠️ `ScreenshotTransport` 會**偽造「已連線」**，而「畫面說連著、實際送不出去」
> 正是本產品最致命的失敗模式。它靠兩層保護：`#if DEBUG`（Release 編不到）
> 與啟動參數（Debug 也要明確帶）。**改動啟動流程時要確認這兩層都還在。**

## C. 資源

| # | 檢查 | 判準 |
|---|---|---|
| C1 | String Catalog 乾淨 | stale = **0**、缺翻譯 = **0** |
| C2 | 音檔有進 bundle | archive 後確認 `.caf` 在 `SideBell.app/` 根目錄 |

C1 的做法（`SWIFT_EMIT_LOC_STRINGS=YES` 建置後）：

```bash
xcrun xcstringstool sync Sources/Resources/Localizable.xcstrings \
  --stringsdata <DerivedData 下每個 .stringsdata>
```

---

## D. 收 log 的注意事項

事後要判讀隔夜或長時間放置的行為時：

- **不要整夜掛 Console.app**——即時串流把訊息全留在記憶體，一夜下來數 GB，通常
  撐不到早上。改用事後收集：

  ```bash
  sudo log collect --device-name "<裝置名稱>" --last 12h
  ```

- **unified logging 預設不持久化 `.info`**。事後要看的關鍵訊息，測試前先暫時提升
  為 `.error`，測完改回。`BLECentralEndpoint.willRestoreState` 那行就是這種情況。

- **不要用 Xcode 測長時間背景**：debugger attached 的 App 不會被系統以正常規則
  回收或 suspend，測到的生命週期與真實使用者不同。用 Xcode 安裝後，**從主畫面
  點開 App**。

---

## E. 一個會讓人誤判的模式

> 8/14 差點把一個真實缺陷判為不存在，值得單獨記下來。

冷啟動後八小時收到呼叫，警報**正常**——看起來像冷啟動路徑沒問題。實際上是期間
**有人打開過 App**，而畫面呈現觸發了警報資源的準備。那個動作在 log 裡完全隱形
（成功時不記錄任何訊息）。

**通則**：當「成功路徑不留下痕跡」時，你無法從 log 分辨「它沒發生」與「它發生了
但沒記錄」。要驗某條路徑，就必須**確保沒有其他路徑代它完成工作**——例如驗冷啟動
就不能中途打開 App。

---

## 送審流程

1. 跑完上面的 A、B、C
2. `xcodegen generate`（若動過 `project.yml`）
3. archive → export → 上傳
4. App Store Connect 送審
5. 送審通過後 tag `vX.Y.Z` ＋ GitHub Release

> tag 要對應**真正送審的那個 build**。build 還沒上傳就打 tag，會讓 tag 指向一個
> 沒出過門的狀態。
