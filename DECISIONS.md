# SideBell 決策紀錄

> 每則一行：日期 + 決策 + 一句理由。spec 檔（`SideBell_Spec_v0.5.md`）不在此修改，由開發者另行改版。
> 本檔只記錄 session 中新產生的決策；spec 內已載明的決策不重複抄錄。

## 2026-08-05

- **採用 Spectra SDD 流程管理本專案**：以 SpecDemo 為模板 bootstrap（`openspec/` + `.spectra.yaml`），讓跨 session 的規格與決策有單一真相來源。
- **`git init` 建立版控**：Spectra 的 snapshot / drift / commit 流程依賴 git，且比賽後需要 tag 與 GitHub Release。
- **Build 系統採 xcodegen（`project.yml`）**：Info.plist、Background Modes、Capabilities 等 BLE 關鍵設定以純文字管理，改動在 diff 上看得見，避免 pbxproj 被誤改而無聲失效。
- **Spectra `tdd: true`，但範圍限定核心邏輯**：wire format codec、重送/Ack 狀態機、去重邏輯 test-first；BLE / UI / AVFoundation / RevenueCat 的平台行為改以實機驗證清單把關，不寫低價值 mock。
- **Spectra `audit: true`**：本專案有三個安全表面（RevenueCat 金流、BLE 加密配對與 Ack 偽造、患者健康相關呼叫紀錄），且「靜默失敗」（呼叫未送出但患者端顯示成功）是本產品最致命的 bug 類型。
- **Deployment target 定為 iOS 18.0**：無任何 API 需求逼往上，取系統眼控門檻（iOS 18 + A12）對齊，語意上「能用眼控的裝置就一定裝得起 SideBell」；已知代價是 iOS 18–25 區間無實機可驗。
- **Universal app（iPhone + iPad 皆支援），患者端格子採 adaptive 欄數**：照顧者端必為隨身 iPhone；患者端眼控場景推薦 iPad（注視目標大、可架床邊固定距離），觸控/輪椅場景 iPhone 亦適用，故不做 iPad-only。
- **開發驗證機組合**：患者端 iPad mini 7（iOS 27 beta）、照顧者端 iPhone 15 Pro（iOS 26）。維持 beta 不降版，必要時另借正式版裝置。
- **實機驗證清單須標註 OS 版本**：凡「背景喚醒」與「State Restoration 復活」類結果若在 beta 機取得，須於正式版裝置複驗後才採信；功能性結果（配對、Ack 閉環、UI）不需複驗。
- **未 Ack 的呼叫狀態不持久化，只活在記憶體的 Delivery 狀態機**：呼叫本質有時效，App 重啟後復活的舊呼叫對照顧者是假警報，侵蝕產品唯一資產（信任）；改以縮短「未送達」紅色回饋的路徑來補償。
- **照顧者端啟用 `audio` background mode**：`isUrgent` 需「重複警報直到確認」，超出 BLE 喚醒的約 10 秒處理窗，不開等於緊急呼叫在鎖屏時只響一聲。與 spec 1.1 排除的「靜音音訊保活 hack」性質不同——此處是真的播放使用者需聽見的警報。附帶兩條實作紀律：(1) 非播放期間必須 deactivate AVAudioSession，不得長開；(2) 重複警報須有上限（如 2 分鐘自動停），不得無限響。
- **多患者（一 Central 對多 Peripheral）：架構預留、v1 UI 只做單患者**（議程第 6 項結案）：BLETransport 內部以集合管理連線、CallRecord 保留 `patientDeviceName`；UI/onboarding/設定頁一律只呈現一位患者。寫集合與寫 optional 成本差異極小，卻避免 1.1 重寫連線與重連策略。
- **簽章設定寫入 `project.yml`（`DEVELOPMENT_TEAM: VZWPMD258L`、Automatic）**：沿用 HerbMeet 專案的 Team ID。寫在 manifest 而非 Xcode UI，避免每次 `xcodegen generate` 後都要重新選 Team。
- **Bundle ID 定為 `com.shinrenpan.sidebell`**：spec 1 留待 App Store Connect 建立時定案的欄位，於 W1 建 `project.yml` 前先行拍板。
- **確認的來源未知時廣播給所有已連線患者端，不得直接拒絕**（W1 角色切換測試發現）：`callOrigins` 住在傳輸層、`stop()` 時清空，而呼叫清單住在 CallCenter 且將持久化到資料庫，兩者生命週期不同。「清單看得到、傳輸層不記得來源」是常態——照顧者端每次重啟 App 後皆如此。若直接拒絕，歷史清單裡的呼叫將永遠按不了「已收到」，患者端永遠停在「等待中」。廣播安全：患者端會靜默丟棄不認識的呼叫識別碼，且識別碼為隨機 UUID 不洩漏內容。
- **App 重啟後的狀態恢復須同時覆蓋還原路徑與手動啟動路徑**（W1 V9 驗證，實測 log 佐證）：兩個必要修正——(1) `didDiscoverCharacteristicsFor` 須檢查 `isNotifying` 以恢復訂閱旗標，因為還原時訂閱從未失效，`didUpdateNotificationStateFor` 不會再觸發；(2) `didDiscover` 發現「已連線但我方缺少特徵」的對端時須主動補做服務探索，涵蓋使用者手動開啟 App（無還原、但系統層 BLE 連線仍存活）的路徑。不補這兩處的症狀是「呼叫收得到（系統層訂閱未失效，delegate 一設上 notify 就進來），但顯示未連線且確認寫不出去」，患者端永遠停在「等待中」。
  - 更正：本條先前記為「`willRestoreState` 未被呼叫」，那是誤判——當時 Console.app 未開啟 info 訊息。實測 log 確認 App 被 BLE 事件喚醒時 `willRestoreState` **會**被呼叫；使用者手動開啟 App 時則不會，故兩條路徑都要覆蓋。
- **兩種「離線」必須分開處理，重連策略不同**（W1 連線循環的收尾決策）：(1)**範圍外斷線**——自動重連、永不放棄，這是照護產品的安全底線，照顧者走回房間時不能依賴他記得按按鈕（spec 3.1）；(2)**連上但探索不到服務**——真實意義是對端不是患者端角色，重試再多次也不會好，連續 3 次後停止自動重連。`[待正式 UI 實作]` 照顧者端須顯示顯眼提示「找不到患者端裝置，請確認對方已設定為患者端角色」與手動重新連線按鈕；不在丟棄式 PoC 畫面上做。
- **iPad 切換角色後仍持續廣播服務 UUID，根因未明**（W1 已知未解問題）：`stopAdvertising()` + `removeAllServices()` 已呼叫，保留 manager 不釋放也試過，對端仍被掃描到。實際影響有限——恢復時間 2.6 秒可接受，且此狀態只在角色設錯時出現，真實使用不會發生。以上述重試上限止血，不再追根因。若 1.1 有餘裕可重啟調查。
- **帶還原識別碼的 Bluetooth manager 一旦建立就不釋放**（W1 連線循環追查的最終根因）：`CBPeripheralManager` / `CBCentralManager` 帶 `RestoreIdentifierKey` 時，其狀態由系統保管——那正是 App 被終止後能復活的原因。把 manager 設為 nil 只丟掉我們這側的參考，系統層的廣播不會停止，且會打斷緊接在前的 `stopAdvertising`。實測後果：切換角色後 iPad 仍持續廣播服務 UUID，對端連上卻找不到服務，形成長達 16 秒、8 次的連線循環。改為 manager 長期持有、以意圖旗標（`wantsAdvertising` / `wantsScanning`）控制行為與連線狀態判定。此前三次修正（重啟掃描、主動連線、無服務斷線）都只在 central 端修補症狀，根因在 peripheral 端。
- **照顧者端訂閱成功後停止掃描，斷線時才重啟**（W1 log 噪音檢視發現）：連上後仍持續掃描唯一的用途是發現第二台患者裝置，而多患者介面 1.0 不做，等於讓照顧者手機整天為用不到的功能耗電，也違反 spec 3.1「維持長連線，不反覆掃描」。1.1 支援多患者時，把停止條件由「已有任一連線」改為「已達目標患者數」。
- **連上但探索不到 SideBell 服務時必須主動斷線，且不得掛連線意圖**（W1 重連速度量測發現）：留著這條無服務的連線，會讓 central 誤判自己「已連線」而忽略對端恢復後的廣播，一路卡到對端自行超時斷開——實測 66 秒。改為主動斷線後，重連時間降至約 4 秒。但實測進一步顯示：斷線後掛的連線意圖會在 1.2 秒內自行完成、又探索不到服務、又斷線，形成連線循環；對端若長時間不恢復服務，這個循環會整夜空轉耗電。因此這類斷線改為不掛連線意圖，改等對端重新廣播時由掃描發現。此為 audit 紀律中「靜默失敗」的典型案例。
- **藍牙不可用必須是獨立的連線狀態，且區分成因**（W1 V8/V10 驗證中發現）：藍牙關閉時原本仍顯示「掃描中」，等於謊稱系統正在運作——照顧者誤觸控制中心關掉藍牙後，會以為呼叫收得到，實際上完全失聯。與先前「顯示已連線卻送不到」同屬假安全感。新增 `ConnectionState.unavailable(BluetoothUnavailability)`，區分 poweredOff / unauthorized / unsupported，因為使用者要採取的行動不同。`unknown` / `resetting` 屬啟動暫態，不映射，以免文字閃爍。`[待正式 UI 實作]` 正式畫面需以顯眼樣式呈現並引導使用者開啟藍牙或授權。
- **連線狀態以「已訂閱呼叫通道」判定，不以 BLE link 層的 connected 判定**（W1 V5 驗證中發現）：BLE 的 link 與 GATT 服務是兩層，對端釋放服務後 link 可能仍在，此時呼叫送不到卻仍顯示已連線。spec 2.1 的綠燈語意必須是「呼叫真的送得到」——顯示已連線卻收不到，是比顯示未連線更危險的假安全感。同時補上 `didModifyServices` 回呼處理服務失效。
- **BLE 配對採系統預設的 Just Works，不自建應用層金鑰交換**（W1 實機驗證後確認）：Core Bluetooth 未提供 API 指定 IO capability，自訂 GATT 服務無法要求配對碼。Just Works 提供 link-layer 加密（擋被動竊聽）與未配對裝置的 GATT 層拒絕（擋偽造 Ack），但不抗「首次配對當下在場」的主動中間人。威脅模型下可接受：攻擊者須物理在場於設定當下，收益僅為偽造一則呼叫。對外文案僅可宣稱「不可被鄰近裝置竊聽／偽造」，不得出現「端對端加密」或「防中間人」。
- **傳輸事件的消費者壽命與 App 相同，停止傳輸時不停止消費**（W1 實機測試中發現的 bug）：`AsyncStream` 只能迭代一次，取消消費 Task 會使序列永久終止，重新啟動接到的是死序列。症狀為「切換角色後再也連不上，重開 App 才正常」。已由 `CallCenterLifecycleTests` 釘住。
- **患者裝置名稱直接採用照顧者端的 `CBPeripheral.name`，Device Info 特徵改為選用的自訂暱稱**（W1 V9 驗證中修正）：`CBPeripheral.name` 取得的是系統設定裡的裝置名稱（如「Joe iPad mini 7」），spec 3.2 期望的「阿公的 iPad」照顧者端本來就看得到，1.0 不需要為此做設定頁欄位。Device Info 特徵的語意改為「患者自訂暱稱」，未設定時傳空值，照顧者端據此保留 `CBPeripheral.name`。
  - 更正：本條先前記為「必須做 App 內自訂暱稱，因為 `UIDevice.current.name` 自 iOS 16 起只回機型名稱」。前半是誤判——`UIDevice.current.name` 的限制屬實，但那不是唯一來源。實測中「來源」欄位先顯示完整名稱、讀到 Device Info 後才變成「iPad」，正是我用較差的值覆蓋了較好的值。
- **進入點採 AppDelegate + SceneDelegate（UIKit lifecycle）託管 SwiftUI**：符合既有 MVVMC 慣例，且 Core Bluetooth State Restoration 需要在 `application(_:didFinishLaunchingWithOptions:)` 早期重建 manager，SwiftUI `@main` App 生命週期較難保證此時序。
