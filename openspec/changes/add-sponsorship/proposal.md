## Why

Shipaton 的參賽要求是「以 RevenueCat SDK 驅動至少一項 IAP」——**沒有它就不符合參賽資格**。這不是加分項，而是門檻，且它牽涉的不只是程式：App Store Connect 的稅務與銀行資訊、商品建立與審核都有等待時間，等程式寫完才開始會卡在最後。

同時它是產品價值主張的一部分。spec 第 5 節的決策路徑是「訂閱制（離線到期是死角）→ 買斷制（gating 違背使命）→ **贊助制**」：全功能永久免費，IAP 只是使用者表達支持的管道。對外文案的主軸「無障礙工具，全功能免費，永遠不鎖功能」正是 Peace Prize 的敘事核心，而贊助頁是它在產品裡唯一的體現。

## What Changes

- 照顧者端設定分頁新增「支持開發者」入口，開啟贊助頁。
- 贊助頁提供三個消耗性內購，可重複購買：`com.shinrenpan.sidebell.tip.small`（US$0.99 / NT$30）、`…tip.medium`（US$2.99 / NT$90）、`…tip.large`（US$8.99 / NT$290）。每個品項說明款項的具體用途，而非抽象的支持程度。
- 引入 RevenueCat SDK 處理購買流程與交易狀態。**這是本專案第一個第三方依賴**——W1 的決策是「不引入任何第三方 Swift 套件」，本片是唯一的例外，理由是參賽要求指名該 SDK。
- 購買成功後於設定頁顯示純裝飾性的感謝徽章。**不與任何功能掛鉤**，App 內不存在 entitlement 判斷，也沒有功能解鎖的程式路徑。
- 贊助頁是**全 App 唯一需要網路的畫面**。無網路或商品載入失敗時明確說明，其餘畫面完全不受影響。
- **患者端不得出現任何購買 UI**，包含入口、按鈕與價格文字。

## Non-Goals

- **社福機構的捐款連結清單**——原規劃以後端 API 動態載入，但那與「完全離線」的產品定位衝突，也要求維護一個服務。比賽結束後再評估。
- **公開的捐贈比例承諾**（例如「收入 50% 捐出並每季公告」）。承諾一旦公開就必須履行，牽涉稅務認列與公告方式，非本片範圍。
- **恢復購買（Restore Purchases）**。消耗性商品重複購買即可，Apple 對此類商品不要求提供恢復入口。
- **訂閱制與買斷制**。spec 第 5 節已排除，理由是離線驗證的死角與 gating 違背使命。
- **贊助者的 app icon 變體**——spec 標為 `[v1.1]`。
- **收入分析與轉換率追蹤**。RevenueCat 的儀表板本身即提供，App 內不做。

## Capabilities

### New Capabilities

- `sponsorship`: 使用者表達支持的管道——商品的呈現、購買的結果、感謝的回饋，以及「購買不影響任何功能」這條約束在產品中如何成立。

### Modified Capabilities

(none)

## Impact

- Affected specs: `sponsorship`（新建）
- Affected code:
  - New:
    - `Sources/Core/Sponsorship/SponsorshipStore.swift`
    - `Sources/Core/Sponsorship/SponsorshipProduct.swift`
    - `Sources/Features/Sponsorship/SponsorshipHostController.swift`
    - `Sources/Features/Sponsorship/SponsorshipView.swift`
    - `Sources/Features/Sponsorship/SponsorshipViewModel.swift`
    - `Sources/Features/Sponsorship/SponsorshipViewModel+Models.swift`
    - `Sources/Features/Sponsorship/SponsorshipMocks.swift`
    - `Tests/SponsorshipTests/SponsorshipStateTests.swift`
    - `docs/device-verification/w6-sponsorship.md`
  - Modified:
    - `Sources/Features/RoleSettings/RoleSettingsView.swift`
    - `Sources/Features/RoleSettings/RoleSettingsViewModel.swift`
    - `Sources/Features/RoleSettings/RoleSettingsHostController.swift`
    - `Sources/App/AppRouter.swift`
    - `Sources/App/AppDelegate.swift`
    - `project.yml`
  - Removed: (none)
- Dependencies: **新增 RevenueCat SDK**（Swift Package Manager）。這是本專案唯一的第三方依賴。
- Platform: 需要 App Store Connect 的 In-App Purchase 能力、完成稅務與銀行資訊、建立三個消耗性商品並通過審核。**這些是程式之外的前置作業，且有等待時間。**
