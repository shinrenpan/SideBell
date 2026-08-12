import UIKit

/// 唯一的導航執行者。
///
/// 三個不同來源會觸發同一種轉場——首頁選擇角色、啟動時依既有設定自動進入、
/// 設定頁切換角色。各自實作會長出三套略有出入的行為，因此全部集中於此。
///
/// Stateless：不持有 window、容器或任何 view controller 的參考，需要的物件
/// 一律當場取得。
@MainActor
final class AppRouter: NSObject {
    static let shared = AppRouter()

    private override init() {}
}

// MARK: - 角色進出

extension AppRouter {
    /// 進入指定角色：儲存角色、啟動傳輸、全螢幕呈現對應容器。
    ///
    /// - Parameter animated: 啟動時依既有角色自動進入的情況傳 false——
    ///   使用者不該看到首頁一閃而過，那會讓人以為自己按錯了什麼。
    func enterRole(_ role: AppRole, from source: UIViewController, animated: Bool = true) {
        guard role.transportRole != nil else {
            assertionFailure("未選擇角色不應進入角色容器")
            return
        }
        guard let appDelegate, let callCenter = appDelegate.callCenter else {
            assertionFailure("進入角色時 CallCenter 應已建立")
            return
        }

        appDelegate.updateRole(role)

        if role == .caregiver {
            // 通知權限在**進入照顧者角色時**才請求，不在 App 啟動時：啟動時
            // 請求會與藍牙權限擠在一起，而使用者此時還不知道通知要用來做什麼。
            //
            // 已決定過的使用者不會再看到系統彈窗，因此不必自行記錄是否問過。
            appDelegate.callNotifier.requestAuthorization()
        }

        let container = makeContainer(for: role, appDelegate: appDelegate, callCenter: callCenter)
        container.modalPresentationStyle = .fullScreen
        source.present(container, animated: animated)
    }

    /// 離開目前角色回到首頁，並停止該角色的傳輸活動。
    ///
    /// 不停止傳輸的話，患者端會在使用者以為已經離開的情況下繼續廣播——
    /// 畫面宣稱的狀態必須等於實際行為。
    func leaveRole(from source: UIViewController) {
        guard let appDelegate else {
            assertionFailure("找不到 AppDelegate")
            return
        }
        guard let root = source.view.window?.rootViewController else {
            assertionFailure("找不到 root view controller")
            return
        }

        appDelegate.updateRole(.unselected)
        // 從 root 開始 dismiss，一次收掉容器與其上的任何覆蓋層。
        root.dismiss(animated: true)
    }

    /// 開啟患者端設定。
    ///
    /// 以 sheet 呈現而非推入堆疊：患者端的導覽列是隱藏的（格子要佔滿全螢幕），
    /// 推入會需要為了返回而把導覽列叫回來，等於在患者的視線路徑上放一顆
    /// 返回按鈕——那正是要避免的東西。
    func openPatientSettings(from source: UIViewController) {
        guard let appDelegate else {
            assertionFailure("找不到 AppDelegate")
            return
        }

        let settings = RoleSettingsHostController(roleStore: appDelegate.roleStore)
        let nav = UINavigationController(rootViewController: settings)
        settings.navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .close,
            primaryAction: UIAction { [weak nav] _ in nav?.dismiss(animated: true) }
        )
        source.present(nav, animated: true)
    }
}

// MARK: - 私有

private extension AppRouter {
    /// 動態取得，不持有——Stateless 原則。
    var appDelegate: AppDelegate? {
        UIApplication.shared.delegate as? AppDelegate
    }

    func makeContainer(
        for role: AppRole,
        appDelegate: AppDelegate,
        callCenter: CallCenter
    ) -> UIViewController {
        switch role {
        case .patient:
            guard let delivery = appDelegate.callDelivery else {
                preconditionFailure("進入患者端時 CallDelivery 應已建立")
            }
            return PatientHomeContainer(
                callCenter: callCenter,
                roleStore: appDelegate.roleStore,
                store: appDelegate.gridItemStore,
                delivery: delivery,
                announcer: appDelegate.callAnnouncer,
                feedback: appDelegate.callFeedback
            )
        case .caregiver:
            return CaregiverHomeContainer(
                callCenter: callCenter,
                roleStore: appDelegate.roleStore,
                alertPolicy: appDelegate.alertPolicy,
                notifier: appDelegate.callNotifier,
                // 確認送出後要重新評估警報——確認是三個停止條件之一，
                // 而評估的唯一入口在 AppDelegate。
                onAlertChanged: { [weak appDelegate] in appDelegate?.refreshAlert() },
                // 警報資源在畫面呈現後才備妥，避免卡住角色切換的轉場。
                onDidAppear: { [weak appDelegate] in appDelegate?.prepareCaregiverAlert() }
            )
        case .unselected:
            preconditionFailure("已於呼叫端排除")
        }
    }
}
