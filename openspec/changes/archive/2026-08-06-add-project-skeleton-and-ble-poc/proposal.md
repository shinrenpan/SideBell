## Why

SideBell 目前只有一份需求文件與一組已拍板的架構決策，沒有任何可執行的程式。而本專案風險最高的區域——BLE 背景行為（鎖屏喚醒、系統終止後復活、加密配對）——是「程式碼看起來對、真實情境會壞」的典型，且無法靠單元測試或模擬器驗證，只能靠雙實機實測。

因此第一個 change 的目的不是交付功能，而是**盡早把不確定性換成事實**：先立起最小可運作的傳輸骨架並在真實裝置上驗證背景行為，再開始堆疊業務邏輯。若背景喚醒在實機上不成立，整個產品的可行性假設就得重新檢視——這件事必須發生在 W1，不能發生在 W5。

## What Changes

- 建立 xcodegen 專案骨架（`project.yml` 產生 Xcode 專案），deployment target iOS 18.0，Universal（iPhone + iPad）。
- 建立 UIKit lifecycle 進入點（AppDelegate + SceneDelegate）託管 SwiftUI，讓 Core Bluetooth 的 State Restoration 能在 App 啟動最早期重建 manager。
- 定義 `CallTransport` 抽象契約：呼叫發送、Ack、連線狀態、事件流。核心邏輯自此不得直接觸碰 Core Bluetooth。
- 定義呼叫訊息的緊湊二進位 wire format 與其編解碼器，含 round-trip 與截斷／畸形封包的防禦行為（test-first）。
- 實作 `BLETransport`：患者端 Peripheral 廣播、照顧者端 Central 背景連線與長連線維持、notify 送達、Ack 回寫、State Restoration 裝配、characteristic 全部 `.encryptionRequired`。
- 建立角色（患者／照顧者）的最小持久化，讓啟動最早期即可判斷該重建哪一端的 manager。
- 建立一個**丟棄式**的 PoC 畫面（兩顆按鈕：發送呼叫、顯示收到的呼叫與連線狀態），僅為驅動實機驗證，後續里程碑會刪除。
- 交付一份實機驗證清單，涵蓋鎖屏長時間背景送達、離開範圍後自動重連、系統終止後由 BLE 事件復活，每項須標註取得結果的 OS 版本。

## Non-Goals

- 患者端格子 UI、格子編輯、照顧者端儀表板與歷史紀錄等業務畫面——留待後續里程碑。
- SwiftData 的 `GridItemModel` 與 `CallRecord`——本 change 不建立任何持久化資料模型（角色設定除外，且不走 SwiftData）。
- 警報播放、TTS 播報、本地通知——PoC 只需在畫面上顯示收到，不需要發出聲音。
- RevenueCat 整合與贊助頁。
- 未 Ack 呼叫的重送狀態機與逾時轉「未送達」的完整行為——本 change 只需送達與 Ack 的單次路徑，重送規則屬後續 change。
- 多患者的 UI 呈現——傳輸層以集合管理連線，但本 change 不提供任何多患者介面。
- 使用者手動上滑殺掉 App 後的復活——iOS 不允許，屬平台限制而非待解問題。

## Capabilities

### New Capabilities

- `app-shell`: App 啟動與生命週期裝配——UIKit 進入點、角色持久化與讀取時機、State Restoration 的註冊點、背景模式宣告。
- `call-wire-format`: 呼叫訊息與 Ack 的二進位編解碼契約，含長度上限、欄位語意、截斷與畸形輸入的防禦行為。
- `call-transport`: 傳輸層對核心邏輯暴露的契約（發送、Ack、連線狀態、事件流）與其 BLE 實作的連線生命週期行為。

### Modified Capabilities

(none)

## Impact

- Affected specs: `app-shell`、`call-wire-format`、`call-transport`（皆為新建）
- Affected code:
  - New:
    - `project.yml`
    - `Sources/App/AppDelegate.swift`
    - `Sources/App/SceneDelegate.swift`
    - `Sources/App/Info.plist`
    - `Sources/Core/Role/AppRole.swift`
    - `Sources/Core/Role/RoleStore.swift`
    - `Sources/Core/Transport/CallTransport.swift`
    - `Sources/Core/Transport/CallMessage.swift`
    - `Sources/Core/Transport/TransportEvent.swift`
    - `Sources/Core/Transport/WireFormat/CallMessageCodec.swift`
    - `Sources/Core/Transport/BLE/SideBellGATT.swift`
    - `Sources/Core/Transport/BLE/BLETransport.swift`
    - `Sources/Core/Transport/BLE/BLEPeripheralEndpoint.swift`
    - `Sources/Core/Transport/BLE/BLECentralEndpoint.swift`
    - `Sources/Features/TransportPoC/TransportPoCHostController.swift`
    - `Sources/Features/TransportPoC/TransportPoCView.swift`
    - `Sources/Features/TransportPoC/TransportPoCViewModel.swift`
    - `Sources/Features/TransportPoC/TransportPoCViewModel+Models.swift`
    - `Tests/WireFormatTests/CallMessageCodecTests.swift`
    - `docs/device-verification/w1-ble-poc.md`
  - Modified:
    - `.gitignore`
  - Removed: (none)
- Dependencies: 新增 xcodegen 作為建置前置工具（以 Homebrew 安裝）。本 change 不引入任何第三方 Swift 套件。
- Platform: 需要 `bluetooth-central` 與 `bluetooth-peripheral` 背景模式；`audio` 背景模式已拍板但屬警報功能，留待後續 change 加入。
