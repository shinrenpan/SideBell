import SwiftUI
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
            let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let callCenter = appDelegate.callCenter
        else {
            assertionFailure("場景啟動時 AppDelegate 應已建立 CallCenter")
            return
        }

        let host = TransportPoCHostController(
            callCenter: callCenter,
            roleStore: appDelegate.roleStore,
            onRoleChange: { [weak appDelegate] role in
                appDelegate?.updateRole(role)
            }
        )

        let window = UIWindow(windowScene: windowScene)
        // 自訂轉場期間若無不透明背景色會露出黑底。
        window.backgroundColor = .systemBackground
        window.rootViewController = UINavigationController(rootViewController: host)
        window.makeKeyAndVisible()
        self.window = window
    }
}
