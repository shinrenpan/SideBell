import UIKit

/// 只負責視窗與導航裝配，不碰傳輸層——傳輸層的生命週期屬於 `AppDelegate`，
/// 因為系統可能在完全沒有場景的情況下把 App 於背景喚醒。
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard
            let windowScene = scene as? UIWindowScene,
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
        else {
            assertionFailure("場景啟動時 AppDelegate 應已存在")
            return
        }

        let home = RoleSelectionHostController(
            disclaimerStore: appDelegate.disclaimerStore,
            availability: appDelegate.bluetoothAvailability
        )

        let window = UIWindow(windowScene: windowScene)
        // 自訂轉場期間若無不透明背景色會露出黑底。
        window.backgroundColor = .systemBackground
        let root = UINavigationController(rootViewController: home)
        window.rootViewController = root
        window.makeKeyAndVisible()
        self.window = window

        // 從 root 而非其子控制器呈現：子控制器此刻可能尚未接上 view hierarchy，
        // 系統會警告「presenting from detached view controller」，且該警告
        // 在未來版本會變成硬性錯誤。
        enterStoredRoleIfNeeded(appDelegate: appDelegate, from: root)
    }
}

// MARK: - 私有

private extension SceneDelegate {
    /// 已選過角色就直接進入，不帶動畫。
    ///
    /// 首頁不會被跳過建立——它必須實際存在於根，否則設定頁的「切換角色」
    /// 沒有可返回的目標。
    ///
    /// 這段刻意寫在場景配置而非啟動回呼中：系統因 BLE 事件在背景啟動 App 時
    /// 可能根本不建立場景，在那裡呈現畫面會落空。
    func enterStoredRoleIfNeeded(appDelegate: AppDelegate, from root: UIViewController) {
        let role = appDelegate.roleStore.role
        guard role.transportRole != nil else { return }

        AppRouter.shared.enterRole(role, from: root, animated: false)
    }
}
