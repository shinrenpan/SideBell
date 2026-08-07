import UIKit

/// SideBell 的應用程式進入點。
///
/// 採 UIKit 生命週期而非 SwiftUI `App`，是因為 Core Bluetooth 的狀態還原
/// 要求在啟動最早期就重建 manager；系統可能在完全沒有場景的情況下，
/// 因 BLE 事件把 App 於背景喚醒。
@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    /// 與 App 同壽命的事件消費者。場景可能還不存在，但它必須已經在聽。
    private(set) var callCenter: CallCenter?
    private(set) var roleStore = RoleStore()
    private(set) var disclaimerStore = DisclaimerStore()
    /// 不依賴角色的藍牙可用性觀察者，供首頁使用。
    /// 此處只建立物件，`startObserving()` 要等使用者確認免責聲明後才呼叫——
    /// 那一步才會建立 manager 並觸發權限請求。
    private(set) var bluetoothAvailability = BluetoothAvailability()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // 順序固定且不可調換：讀角色 → 建傳輸層 → 接消費者 → 啟動。
        // 三者都必須在任何場景啟動之前完成。
        let role = roleStore.role

        // 暱稱尚無設定介面，傳 nil：照顧者端會顯示系統的藍牙裝置名稱。
        let transport = BLETransport(nickname: nil)
        let callCenter = CallCenter(transport: transport)
        self.callCenter = callCenter

        if let transportRole = role.transportRole {
            callCenter.start(as: transportRole)
        }

        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}

// MARK: - 角色切換

extension AppDelegate {
    /// 供設定或角色選擇畫面呼叫。切換角色會重建傳輸層的角色綁定。
    ///
    /// 角色未變更時不動傳輸：啟動流程會先在 `didFinishLaunching` 依既有角色
    /// 啟動傳輸，接著場景配置又會走一次進入角色的路徑。若不擋掉，剛建立的
    /// 連線會在使用者還沒看到畫面時就被拆掉重來。
    func updateRole(_ role: AppRole) {
        let previous = roleStore.role
        roleStore.save(role)

        guard previous != role, let callCenter else { return }

        callCenter.stop()
        if let transportRole = role.transportRole {
            callCenter.start(as: transportRole)
        }
    }
}

// MARK: - 私有

private extension AppDelegate {
    // 裝置名稱不再由此提供。
    //
    // 實測發現照顧者端的 `CBPeripheral.name` 就能取得系統設定裡的完整名稱
    // （例如「Joe iPad mini 7」），比 `UIDevice.current.name` 好——後者自
    // iOS 16 起只回傳機型名稱（「iPad」）。因此 Device Info 特徵的語意改為
    // 「患者自訂暱稱」，未設定時不傳，讓照顧者端沿用系統名稱。
}
