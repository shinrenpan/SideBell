## 1. 專案骨架與建置設定

- [x] 1.1 依「以 xcodegen 從 project.yml 生成 Xcode 專案」建立 `project.yml`，滿足 `Project is generated from a declarative manifest`：乾淨 checkout 執行 xcodegen 後可直接建置，不需任何手動 Xcode 設定。驗證：刪除生成的 xcodeproj 後重新生成並執行 xcodebuild build，建置成功。
- [x] 1.2 於 manifest 設定 `Deployment target and supported devices`：最低版本 iOS 18.0、裝置家族含 iPhone 與 iPad。驗證：xcodebuild -showBuildSettings 輸出的 IPHONEOS_DEPLOYMENT_TARGET 為 18.0 且 TARGETED_DEVICE_FAMILY 同時含 1 與 2。
- [x] 1.3 建立 `Sources/App/Info.plist` 並滿足 `Bluetooth background modes and usage description are declared`：宣告 bluetooth-central 與 bluetooth-peripheral 背景模式，以及繁體中文的藍牙用途說明。驗證：讀取建置產物 bundle 內的 Info.plist，確認兩個背景模式與 NSBluetoothAlwaysUsageDescription 皆存在且用途說明非空白。
- [x] 1.4 擴充 `.gitignore` 排除 xcodegen 生成物與 Xcode 使用者資料，使建置後工作目錄保持乾淨。驗證：執行生成與建置後 git status 不出現未追蹤的生成檔案。

## 2. Wire format 編解碼（測試先行）

- [x] 2.1 在 `Tests/WireFormatTests/CallMessageCodecTests.swift` 撰寫涵蓋 `Call message binary encoding` 與 `Call message binary decoding` 的失敗測試，包含 spec 中列出的欄位偏移量表與四組 round-trip 案例（含 100 位元組標題與空標題的邊界）。驗證：測試存在且因尚未實作而失敗。
- [x] 2.2 於同一測試檔補上 `Malformed frame defense` 的全部拒絕案例（空資料、30 位元組、標題長度與實際位元組不符、標題長度 101、版本非 1、非法 UTF-8、132 位元組）與 `Acknowledgement payload` 的 round-trip 及長度錯誤案例。驗證：測試存在且失敗，且拒絕案例斷言的是具名錯誤而非崩潰。
- [x] 2.3 實作 `Sources/Core/Transport/CallMessage.swift` 與 `Sources/Core/Transport/WireFormat/CallMessageCodec.swift`，編解碼為不接觸隔離狀態的純函式，使 2.1 與 2.2 的測試全數通過。驗證：swift test 或 xcodebuild test 全綠，且逾長標題在編碼前即拋錯而非被截斷。

## 3. 傳輸契約與 BLE 實作

- [x] 3.1 依「CallTransport 契約以角色啟動、送出、確認、事件流四項為界」定義 `Sources/Core/Transport/CallTransport.swift` 與 `Sources/Core/Transport/TransportEvent.swift`，滿足 `Transport contract isolates core logic from Core Bluetooth`。驗證：以 grep 確認傳輸模組以外無任何檔案 import CoreBluetooth，且送出與確認的失敗以具名錯誤表達、無布林回傳值。
- [x] 3.2 依「GATT 定義集中於單一檔案，服務識別碼一次產生後固定」建立 `Sources/Core/Transport/BLE/SideBellGATT.swift`：以 uuidgen 產生服務與三個特徵的識別碼並寫死，三個特徵全部宣告需要加密，滿足 `Encrypted characteristics reject unpaired peers` 的宣告面。驗證：檔案內容檢視確認所有特徵權限皆為 encryptionRequired，且識別碼不重複、不散落於其他檔案。
- [x] 3.3 實作 `Sources/Core/Transport/BLE/BLEPeripheralEndpoint.swift`：患者角色啟動後廣播 SideBell 服務、透過通知送出呼叫、接收確認寫入。驗證：以 PoC 畫面在實機上觀察廣播啟動後連線狀態轉為已連線。
- [x] 3.4 實作 `Sources/Core/Transport/BLE/BLECentralEndpoint.swift`，滿足 `Automatic pairing without a manual device-selection flow` 與 `Long-lived connection rather than repeated scanning`：依「照顧者端掃描一律以服務識別碼過濾」前景背景皆以識別碼過濾掃描，發現後連線並常駐、不輪詢、不因閒置斷線。驗證：實機上完成連線後閒置三十分鐘，連線狀態仍為已連線。
- [x] 3.5 於 Central 端點實作「斷線後立即重新發出連線請求，不自行輪詢」，滿足 `Automatic reconnection after range loss`。驗證：實機測試離開範圍至斷線後返回，無使用者操作即恢復連線。
- [x] 3.6 於 Central 端點以集合管理連線並為每則收到的呼叫標記來源裝置名稱，滿足 `Connections are tracked as a collection`。驗證：PoC 畫面顯示的收到呼叫含來源裝置名稱，且連線容器型別為集合而非單一可選值。
- [x] 3.7 依「BLETransport 內部依角色拆為兩個端點，對外仍是單一實作」與「傳輸層整體採主動作者隔離，Bluetooth 回呼走主佇列」實作 `Sources/Core/Transport/BLE/BLETransport.swift`，並依「事件序列採無上限緩衝，並在啟動回呼即接上消費者」建立事件序列。驗證：以患者角色啟動時不進行掃描、以照顧者角色啟動時不進行廣播，兩者以 PoC 畫面狀態確認。
- [x] 3.8 為兩端註冊 Bluetooth 狀態還原識別碼並實作還原回呼，滿足 `Recovery after system termination`。驗證：實機上以開發工具終止照顧者端 App 後由患者端送出呼叫，App 於背景復活並收到該則呼叫。
- [x] 3.9 確保未確認呼叫僅存在於記憶體，滿足 `Pending calls are not persisted across launches`。驗證：送出呼叫後於收到確認前終止 App，重新啟動後 PoC 畫面無待確認呼叫且未發生重送。

## 4. App 裝配與 PoC 畫面

- [x] 4.1 實作 `Sources/Core/Role/AppRole.swift` 與 `Sources/Core/Role/RoleStore.swift`，依「角色設定存於輕量鍵值儲存」滿足 `Role is persisted and readable before transport start`：值域為患者、照顧者、未選擇，可於啟動回呼同步讀取。驗證：單元測試斷言首次啟動讀出未選擇、寫入後再讀出相同角色。
- [x] 4.2 依「進入點採 AppDelegate + SceneDelegate，並在啟動回呼建立傳輸層」實作兩個進入點檔案，滿足 `UIKit lifecycle entry point hosting SwiftUI`：啟動回呼依序讀角色、建傳輸層、接消費者；SceneDelegate 只裝配視窗與導航並設定不透明背景色。驗證：於啟動回呼設中斷點確認其在任何場景啟動前執行完畢。
- [x] 4.3 依「引入 CallCenter 作為 App 生命週期的事件消費者」實作最小形式的 CallCenter：持有傳輸層、消費事件序列、暴露連線狀態與最近收到的呼叫與確認。驗證：App 進入背景後由對端送出呼叫，重新開啟畫面時該則呼叫已在狀態中，證明消費不依賴畫面存在。
- [x] 4.4 依「PoC 畫面遵循既有分層慣例，但明確標記為丟棄式」在 `Sources/Features/TransportPoC/` 建立畫面：兩個動作（送出固定內容呼叫、確認收到的呼叫）與三項顯示（連線狀態、最近收到的呼叫、最近收到的確認），滿足 `Acknowledgement closes the loop to the patient`。驗證：兩台實機上患者送出後照顧者顯示該則呼叫，照顧者確認後患者顯示同一識別碼已被確認。

## 5. 實機驗證

- [x] 5.1 依「實機驗證清單以獨立文件交付並標註 OS 版本」建立 `docs/device-verification/w1-ble-poc.md`，每項含前置條件、操作步驟、預期結果、實際結果與 OS 版本欄位，並標明背景喚醒與系統終止復活兩類須於正式版裝置複驗。驗證：文件涵蓋本 change 全部實機驗收項目，逐項可獨立執行。
- [x] 5.2 執行並記錄鎖屏背景送達驗證，確認 `Call delivery while the caregiver app is backgrounded`：照顧者端鎖屏且背景至少三十分鐘後由患者端送出呼叫。驗證：清單中該項填入實際結果與 OS 版本，照顧者端記錄的接收時間為送達當下而非開啟 App 當下。
- [x] 5.3 執行並記錄配對與加密驗證：首次連線出現系統配對提示，且未配對裝置無法訂閱呼叫特徵。驗證：清單中填入實際結果與 OS 版本，未配對情境確認無任何呼叫內容傳出。
- [x] 5.4 執行並記錄重連與系統終止復活驗證，於正式版裝置複驗背景喚醒與復活兩項並填回結果。驗證：清單中兩項皆有 beta 與正式版兩筆記錄，結論以正式版為準。
