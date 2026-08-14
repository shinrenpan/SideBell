# SideBell 產品規格書 v0.5(BLE + 贊助制)

> ## ⚠️ 這是歷史文件，不是現況
>
> 寫於 2026-08 開發**之前**，用途是啟動 SDD（spec-driven development）。
> 內容已由實作與後續決策取代，**照它施工會做錯**。例如它寫著「預設 4 個
> 核心格子」，而實際出貨是 2 個（W7 的決定，見 `DECISIONS.md`）。
>
> 現況請看：
>
> | 要找什麼 | 去哪裡 |
> |---|---|
> | 產品行為、技術架構 | `openspec/specs/`（9 份規格，共約 2,900 行） |
> | 為什麼這樣決定 | `DECISIONS.md` 與各 change 的 `design.md` |
> | 1.0 之後要做什麼 | `docs/roadmap.md` |
> | 實機驗證結果 | `docs/device-verification/` |
> | 送審流程 | `docs/release-checklist.md` |
>
> 保留它的理由只有一個：**看得到起點**。裡面的取捨推導（尤其 1.1 節「明確
> 排除」為什麼不用 Multipeer、不自製眼控、不做訂閱制）解釋了這個產品為什麼
> 長成現在的樣子，那是規格文件不會記錄的東西。
>
> 第 7 節的里程碑與第 9.1 節的時程已經過期，第 8 節的待討論清單多數已結案。

> 目標:RevenueCat Shipaton 2026(2026/8/1–9/30 上架)。主攻 RevenueCat Peace Prize。
> 本文件為粗略 spec,供 SDD session 逐項細化。標註 `[v2]` 者不在比賽 scope 內。
> v0.3 變更:產品定名 SideBell / 隨身鈴(前名 EyeTalk,因 Google Play 同名交友 app 與 Gemini 競賽同名同題項目而棄用)。
> v0.4 變更:通訊層定案——長連線策略、緊湊二進位 payload(棄 JSON、免分片)、characteristic 加密(encryptionRequired)、State Restoration 必做、背景廣播 overflow 限制註記、transport 抽象層、Remote Push(CloudKit)列 [v2]。SDD 議程第 1 項結案。
> v0.5 變更:變現改為贊助制(consumable 小費三級距,全功能永久免費、無 gating),患者端移除所有購買 UI,SDD 議程第 5 項結案;新增 9.4 使命導向推廣通路(協會/輔具中心/OT)與語言 roadmap(1.1 加印尼/越南語)。
> v0.4.1 變更:Remote Push 由 [v2] 提升為 [v1.1](2026/10 目標)——比賽後持續開發已定案,9/5 送審空窗開工,兼作 post-release 成長敘事。

---

## 1. 產品定位

- **產品名稱**:SideBell(中文:隨身鈴)
- **Bundle ID**:`com.<yourdomain>.sidebell`(建 App Store Connect 時定案)
- **命名原則**:所有程式碼識別字、GATT 命名、claude-mem 條目一律使用 `SideBell` / `sidebell`,不得出現舊名
- **核心定位**:專為重度失能、漸凍症(ALS)患者、行動不便者及照顧者設計的**無障礙離線呼叫系統**。不限床邊——輪椅、居家休養、術後照護皆為目標場景。
- **部署型態**:單一 App,二合一角色(患者端 / 照顧者端),首次啟動或設定頁切換。
- **通訊技術**:**BLE(Core Bluetooth)**。患者端 = Peripheral,照顧者端 = Central。100% 免網際網路。
- **眼控**:不自行實作。依賴 **iOS 系統層級 Eye Tracking + Dwell Control**(設定 > 輔助使用)。App 的責任是提供「眼控友善的 UI」:超大按鈕、高對比、寬間距。

### 1.1 明確排除(決策紀錄)

| 排除項 | 原因 |
|---|---|
| Multipeer Connectivity | 無 background mode,照顧者端退背景即斷線,無 entitlement 可繞過 |
| 自製眼控(ARKit gaze estimation) | iOS 無第三方注視座標 API;自製精度差、超出時程 |
| App 內 dwell time 判定 | 與系統 Dwell Control 衝突,停留時間由系統設定管理 |
| 訂閱制 | 長期斷網下訂閱到期無法驗證,對臥床患者是災難場景 → 改買斷 |
| 靜音音訊背景保活 hack | App Store 審核高風險 |
| Local Push Connectivity (NEAppPushProvider) | 官方正解但需特殊 entitlement + 區網 TCP server,超出比賽時程 `[v2]` |

---

## 2. 角色功能與 UI

### 2.1 患者端(Patient Mode)

- **受眾**:臥床、無法流暢言語或行動之患者(以系統眼控、頭控或單指操作)。
- **介面**:
  - LazyVGrid 超大網格按鈕(建議單格 ≥ 150pt,間距 ≥ 24pt,支援 Dynamic Type)。
  - 頂部:連線狀態指示(綠 = 已有照顧者連線 / 紅 = 無)。
  - 點擊格子 → 本機 TTS 播報 + BLE notify 發送。
- **無障礙要求**(Peace Prize 評審重點):
  - 全面支援 VoiceOver、Switch Control、Dynamic Type。
  - 高對比模式、可調字級。
  - 按鈕觸發不依賴任何手勢(純 tap,系統眼控可直接驅動)。
- **格子編輯(全功能免費,無 gating)**:
  - 預設 4 個核心格子(喝水、翻身、洗手間、不舒服)。
  - 編輯模式:無限新增、改文字、換圖示(SF Symbols)、拖曳排序、設定緊急等級。
  - > 決策紀錄:曾規劃「免費 4 格 + 買斷解鎖編輯」,棄用——ALS 病程推進最需要客製化的正是目標族群,對最需要的人收費違背產品使命。

### 2.2 照顧者端(Caregiver Mode)

- **受眾**:同住家屬、看護、輪班照顧者。
- **介面**:
  - 配對狀態儀表板(自動掃描/連線,無需手動配對流程)。
  - 歷史呼叫紀錄清單(時間、項目、緊急等級),可依日期分組檢視頻率。
- **核心功能**:
  - **背景監聽**:`bluetooth-central` background mode,背景持續掃描與接收 notify。
  - 收到呼叫 → 高分貝警報(AVAudioSession `.playback`,忽略靜音鍵)+ TTS 播報(「注意,阿公需要翻身」)+ 本地通知(App 在背景時)。
  - `isUrgent = true` → 最高音量 + 重複警報直到手動確認。
  - 確認機制:照顧者按「已收到」→ 回寫 Ack → 患者端格子顯示 ✓(閉環回饋,患者知道有人看到了)。
- `[v2]` Critical Alerts entitlement(App 被殺掉/勿擾模式下仍強制響鈴,需向 Apple 申請)。

---

## 3. 通訊架構(v0.4 定案)

### 3.0 傳輸抽象層(架構約束)

- 核心邏輯不得直接依賴 Core Bluetooth。定義 `protocol CallTransport`(send/receive/ack/connectionState),v1 唯一實作為 `BLETransport`。
- 目的:1.1 插入 `CloudKitPushTransport`(見 3.7)而不動呼叫/警報核心。

### 3.1 角色與連線策略

- **患者端 = Peripheral(Advertiser)**:App 啟動即廣播自訂 Service UUID;`bluetooth-peripheral` background mode 維持背景廣播。
- **照顧者端 = Central**:`bluetooth-central` background mode。背景掃描**必須指定 Service UUID 過濾**(iOS 背景掃描規則),不可 wildcard。
- **維持長連線,不反覆掃描**:發現後即連線並常駐。已連線下 notify 到達會喚醒背景 App(約 10 秒處理窗)播警報/發本地通知。
- **重連**:`didDisconnect` 回呼中立即再次 `connect()`——iOS connect 請求無 timeout,系統掛住意圖,裝置回到範圍自動完成。不自行輪詢。

### 3.2 GATT 設計

```
Service: SideBell Call Service
UUID: 實作時 uuidgen 產生(128-bit 自訂)

Characteristics(全部 .encryptionRequired,見 3.5):
1. Call Message  (Notify)        患者端發送呼叫,payload 見 3.3
2. Ack           (Write)         照顧者端回寫確認,payload = callId(16 bytes)
3. Device Info   (Read)          患者暱稱 UTF-8(例:「阿公的 iPad」),多裝置識別
```

### 3.3 訊息結構(緊湊二進位,取代 JSON)

> 決策:JSON 編碼(UUID 字串 36B + ISO 時間戳 + key/引號)逼近 150–180 bytes,背景情境不保證協商到大 MTU。改定長二進位,單包必過,**不實作分片**。SDD 議程原第 1 項結案。

```
CallMessage wire format(little-endian):
  version      : UInt8            (= 1)
  flags        : UInt8            (bit 0 = isUrgent)
  id           : 16 bytes         (UUID binary)
  timestamp    : UInt32           (epoch 秒)
  commandCode  : 8 bytes          (ASCII,右補 0x00,例 "WATER")
  titleLen     : UInt8
  title        : ≤ 100 bytes      (UTF-8,UI 層限制輸入長度)
合計 ≤ 131 bytes
```

- Swift 端以 struct + 手寫 encode/decode(或輕量 binary codec),單元測試必含 round-trip 與截斷封包防禦。

### 3.4 可靠性

- 未 Ack 重送:每 10 秒重送,最多 6 次,格子顯示「等待中」;逾時轉「未送達」狀態(紅色警示)。
- 多照顧者:一 Peripheral 可被多 Central 同時連線訂閱,天然支援輪班;任一人 Ack 即全體閉環(Ack 經 notify 回推全體)。
- 去重:照顧者端以 message id 去重(重送與多路徑情境)。

### 3.5 安全性(v0.4 新增)

- 所有 characteristic 權限設 **`.encryptionRequired`**:首次連線觸發系統配對對話框,bonding 後全程 link-layer 加密,未配對裝置的讀寫在 GATT 層被拒。
- 代價僅為首次設定多一步配對,換得患者呼叫內容不可被鄰近裝置竊聽/偽造 Ack。列入 Peace Prize 敘事(患者隱私)。

### 3.6 iOS 平台已知限制(約束,非 bug)

1. **背景廣播 overflow area**:患者端進背景後,service UUID 移入 overflow 區,僅「明確指定掃描該 UUID 的 iOS central」可見。iOS 對 iOS 成立;未來 Android 照顧者端對背景中的 iOS 患者端幾乎不可見 `[v2 風險註記]`。
2. **State Restoration 必做**:兩端皆實作 `CBCentralManagerOptionRestoreIdentifierKey` / `CBPeripheralManagerOptionRestoreIdentifierKey` + `willRestoreState`。系統因記憶體壓力終止 App 後,BLE 事件可將 App 於背景復活。
3. **使用者手動上滑殺 App 不會復活**(iOS 鐵律)。緩解:onboarding 明確教學「不要滑掉 App」;患者端引導使用模式 + 插電。

### 3.7 `[v1.1,目標 2026/10]` Remote Push 互補通道

- **定位**:BLE 為主(同一空間、零網路依賴),push 補「照顧者短暫外出」場景。**非替代**。
- **技術路線**:CloudKit 共享資料庫 + `CKQuerySubscription` → 患者端寫入呼叫紀錄,照顧者端經 APNs 收推播,**免自建 server**。
- **不進 1.0 原因**:CloudKit 共享 onboarding(雙方 iCloud、邀請流程)是一整塊工程;推播延遲/折疊語意與 BLE 不同,警報邏輯需分岔。威脅 9/15 上架目標。
- **排程**:9/5 送審後即開 CloudKit branch(利用審核空窗),目標 10 月初隨 1.1 發布——同時作為 Shipaton post-release 成長敘事(Grand Prize 評 traction)。
- 1.0 僅以 3.0 的 transport 抽象預留插槽,不含任何 CloudKit 程式碼。

---

## 4. 本地儲存(SwiftData)

- **患者端**:`GridItemModel`(id、title、symbolName、commandCode、isUrgent、sortOrder)。
- **照顧者端**:`CallRecord`(id、timestamp、title、commandCode、isUrgent、ackedAt、patientDeviceName)。
- 不做雲端同步。純本地,符合離線定位與醫療隱私最小化原則。

---

## 5. 變現(RevenueCat,贊助制)

> 決策紀錄:訂閱制(離線到期死角)→ 買斷制(gating 違背使命)→ **贊助制定案**。全功能永久免費,IAP 僅為使用者表達支持的管道,同時滿足 Shipaton「RevenueCat SDK 驅動至少一項 IAP」的參賽要求。

- **商品**:Consumable 小費三級距——`com.shinrenpan.sidebell.tip.small` NT$30、`…tip.medium` NT$90、`…tip.large` NT$290(US$0.99 / $2.99 / $8.99)。可重複購買。識別碼一律寫完整的反向 DNS 全名:那是 App Store Connect 上實際登記的 product ID,也是 SDK 查詢商品時唯一認得的字串。
- **入口**:僅照顧者端設定頁「支持開發者 ❤️」。患者端不出現任何購買 UI(眼控操作購買流程的疑慮就此消除)。
- **贊助回饋**:純裝飾性——設定頁顯示「❤️ 感謝您的支持」徽章;`[v1.1]` 可加 app icon 變體。不得與任何功能掛鉤。
- **無 entitlement gating**:App 內不存在功能解鎖判斷,離線憑證驗證問題不復存在。
- **價值主張(對外文案主軸)**:「無障礙工具,全功能免費,永遠不鎖功能。」——Peace Prize 敘事、協會/輔具中心/OT 推廣的核心訊息。

---

## 6. Xcode 專案配置

### 6.1 Info.plist

| Key | Value |
|---|---|
| `NSBluetoothAlwaysUsageDescription` | 我們需要使用藍牙,在不需要網路的情況下即時連線患者與照顧者的裝置,傳送呼叫訊息。 |
| `UIBackgroundModes` | `bluetooth-central`(照顧者端)、`bluetooth-peripheral`(患者端)、`audio`(警報播放,SDD 確認必要性) |

> 註:改用 BLE 後不再需要 `NSBonjourServices` 與 `NSLocalNetworkUsageDescription`(那是 MC/Bonjour 的需求)。

### 6.2 Capabilities

- Background Modes:Uses Bluetooth LE accessories、Acts as a Bluetooth LE accessory。
- In-App Purchase。

---

## 7. 里程碑(倒推 9/30,粗排)

| 週次 | 目標 |
|---|---|
| W1(8/5–8/11) | SDD 定稿、專案骨架、BLE PoC(兩台實機通、背景 notify 收得到) |
| W2–W3 | 患者端 UI + SwiftData 格子編輯;照顧者端警報/紀錄/Ack 閉環 |
| W4 | RevenueCat 整合(小費商品 + 贊助頁);多語言基礎(繁中/英,預留印尼/越南語字串架構) |
| W5 | 無障礙打磨(VoiceOver、眼控實測)、onboarding、雙語(繁中/英) |
| W6 | TestFlight、實機長時間背景穩定性測試、App Store 素材 |
| W7(9/9–) | 送審 buffer(預留一次被拒重送)+ #BuildInPublic 素材、Devpost 提交 |

---

## 8. SDD 待討論清單

1. ~~BLE 分片~~(已結案:二進位定長格式免分片,見 3.3)。
2. 重送/Ack 狀態機完整定義(含多 Central 情境)。
3. 患者端防休眠策略:`isIdleTimerDisabled` + 引導使用模式教學 vs 其他。
4. 警報音檔與音量策略(系統音量被調低時的處理)。
5. ~~Paywall 動線~~(已結案:贊助制,入口僅在照顧者端設定頁,患者端無購買 UI,見第 5 節)。
6. 多患者(一 Central 連多 Peripheral)是否納入 v1。
7. Devpost 提交需求對照(demo 影片、#BuildInPublic 紀錄)。

---

## 9. 非開發事項(比賽與上架,不進 SDD 但影響 scope 決策)

### 9.1 時程策略

- **目標上架日:9/15 前**,非 9/30。Grand Prize 評 traction,上架後需留 ≥ 2 週衝下載與 #BuildInPublic 聲量。
- SDD 做 scope 取捨時以此為準:任何威脅 9/15 的功能一律砍或降級為 `[v2]`。
- Devpost 報名、#BuildInPublic 從即日開始紀錄(改名決策過程即為素材)。

### 9.2 定價(已定案:贊助制)

- 小費級距:NT$30 / 90 / 290(US$0.99 / $2.99 / $8.99),consumable,詳見第 5 節。
- 收入預期:小費制轉換率普遍 < 1%,本產品不以營收為目標;RevenueCat 數據僅作觀察用。

### 9.3 審核風險與免責定位(必做,寫進 onboarding 需求)

- **產品定位措辭**:「照護輔助呼叫工具」。App 內文案與 App Store 描述**不得**暗示為緊急醫療警報系統或可靠救命裝置(BLE 距離有限、App 被終止即失效)。
- **免責聲明**:onboarding 首次啟動與 App Store 描述皆須明示——本 App 不可取代緊急醫療警報服務或撥打 119/當地緊急電話。
- 此為 App Review Guideline(醫療類敏感聲明)與產品責任的雙重考量,SDD 時將免責聲明納入 onboarding flow 需求。

### 9.4 推廣通路(使命導向)

- 目標族群不逛 App Store。上架後主動觸及:漸凍人協會、各縣市輔具資源中心、醫院職能治療師(OT)、居服督導體系。
- 目的雙重:觸及真實需求家庭 + 取得真實患者實測回饋(眼控精度、格子詞彙適配)。
- 語言 roadmap:1.0 繁中/英;`[v1.1]` 印尼語、越南語(台灣居家照護現場外籍看護為照顧者端主要操作者之一,本地化成本低、實際價值高)。
- `[v2]` Android 照顧者端評估(照護家庭 Android 佔比高;注意 3.6 overflow area 限制)。
