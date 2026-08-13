import Foundation
import RevenueCat

/// RevenueCat SDK 的初始化。
///
/// **這是 RevenueCat 的型別能出現的唯一一區**（`Sources/Core/Sponsorship/`）。
/// App 到 W4 為止是完全離線、零第三方依賴的，贊助功能同時打破這兩件事；
/// 把影響圈在這個目錄裡，日後要換掉金流方案時改動範圍才是明確的。
/// 因此 `AppDelegate` 呼叫的是這裡的 `configure()`，而不是自己 import SDK。
enum SponsorshipConfiguration {
    /// `Info.plist` 的鍵名。值由 `Config/Secrets.xcconfig` 於建置時注入，
    /// 而該 xcconfig 不進版控（範本見 `Config/Secrets.example.xcconfig`）。
    private static let apiKeyInfoKey = "RevenueCatAPIKey"

    /// 可接受的 API key 前綴。用來擋掉範本值與設定錯誤。
    ///
    /// - `appl_`：正式的 Apple 平台 Public SDK Key。
    /// - `test_`：RevenueCat 的 **Test Store**（SDK 內部名為 Simulated Store）。
    ///   購買流程改由 SDK 自己彈系統 alert，提供「購買／失敗／取消」三個結果，
    ///   完全不碰 App Store——不需要沙盒帳號，也不需要商品先過審。
    ///   Release build 誤用時 SDK 會自己跳警告擋下，因此這裡不必再判斷組態。
    private static let apiKeyPrefixes = ["appl_", "test_"]
}

// MARK: - 初始化

extension SponsorshipConfiguration {
    /// 設定 API key。**此步驟不發出任何網路請求**。
    ///
    /// 商品載入延後到贊助頁出現時才進行：照顧者可能永遠不開那一頁，沒有
    /// 理由為此在啟動時連網——而啟動路徑上多一個網路請求，代價是患者端
    /// 也要跟著等。
    ///
    /// 缺少或不合法的 key **不視為錯誤**，只記一行 log 後返回。App 的核心
    /// 是呼叫與警報，兩者與金流毫無關係；為了設定缺失讓整個 App 起不來，
    /// 是把附屬功能的重要性排在患者求助之前。
    static func configure() {
        guard let apiKey else {
            SideBellLog.transport.error("RevenueCat API key 未設定，贊助功能停用")
            return
        }
        Purchases.configure(withAPIKey: apiKey)
    }

    /// SDK 是否已完成設定。贊助頁據此決定要不要嘗試載入方案——
    /// 未設定時直接呈現失敗，而不是讓 SDK 拋出難以解讀的錯誤。
    static var isConfigured: Bool {
        Purchases.isConfigured
    }
}

// MARK: - 私有

private extension SponsorshipConfiguration {
    /// 讀出並驗證 key。
    ///
    /// 驗證是必要的，因為缺檔時 `$(REVENUECAT_API_KEY)` 會展開成**空字串**
    /// 而不是消失，而範本檔裡放的是 `appl_YOUR_KEY_HERE`。兩者都會讓
    /// `Purchases.configure` 收下一個無效的值，直到使用者點下購買才爆——
    /// 那是最糟的失敗時機。寧可在啟動時就判定為未設定。
    static var apiKey: String? {
        guard
            let raw = Bundle.main.object(forInfoDictionaryKey: apiKeyInfoKey) as? String
        else { return nil }

        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            let prefix = apiKeyPrefixes.first(where: { trimmed.hasPrefix($0) }),
            trimmed.count > prefix.count,
            !trimmed.contains("YOUR_KEY_HERE")
        else { return nil }

        return trimmed
    }
}
