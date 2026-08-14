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
            //
            // 截圖模式跳過：系統彈窗會蓋住整個畫面，而商店截圖要呈現的是
            // App 本身。這個分支只在 Debug 且帶啟動參數時成立。
            #if DEBUG
            let skipsPrompt = ScreenshotTransport.isEnabled
            #else
            let skipsPrompt = false
            #endif
            if !skipsPrompt {
                appDelegate.callNotifier.requestAuthorization()
            }
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
    func openPatientSettings(
        from source: UIViewController,
        onCallback: (@MainActor (RoleSettingsViewModel.Callback) async -> Void)? = nil
    ) {
        guard let appDelegate else {
            assertionFailure("找不到 AppDelegate")
            return
        }

        let settings = RoleSettingsHostController(
            roleStore: appDelegate.roleStore,
            onCallback: onCallback
        )
        let nav = UINavigationController(rootViewController: settings)
        settings.navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .close,
            primaryAction: UIAction { [weak nav] _ in nav?.dismiss(animated: true) }
        )
        source.present(nav, animated: true)
    }

    /// 開啟支持開發者。
    ///
    /// 推入堆疊而非以 sheet 呈現：它掛在照顧者端設定分頁的導覽堆疊上，
    /// 而照顧者是有完整操作能力的使用者，返回鍵對他不是障礙。
    ///
    /// **患者端不存在到得了這裡的路徑**——入口本身只在角色為照顧者時出現。
    func openSponsorship(from source: UIViewController) {
        guard let navigationController = source.navigationController else {
            assertionFailure("支持頁需要導覽堆疊")
            return
        }
        navigationController.pushViewController(SponsorshipHostController(), animated: true)
    }

    /// 開啟編輯呼叫項目。
    ///
    /// 推入患者端設定那個 sheet 的堆疊上。操作者是照顧者——他有完整的操作
    /// 能力，返回鍵對他不是障礙；而入口本身在患者端設定裡，已被兩段確認
    /// 保護著。
    ///
    /// **數量上限以視窗尺寸計算，不用 `source.view` 的尺寸**：這一頁自己是
    /// 個 sheet，在 iPad 上比視窗窄得多，拿它去算會得出一個比患者實際看得到
    /// 的格子數更低的上限。要問的是「患者的格子畫面放得下幾格」。
    func openGridEditing(
        from source: UIViewController,
        onCallback: @escaping @MainActor (GridEditingViewModel.Callback) async -> Void
    ) {
        guard let appDelegate else {
            assertionFailure("找不到 AppDelegate")
            return
        }
        guard let navigationController = source.navigationController else {
            assertionFailure("編輯頁需要導覽堆疊")
            return
        }

        let size = source.view.window?.bounds.size ?? source.view.bounds.size
        navigationController.pushViewController(
            GridEditingHostController(
                store: appDelegate.gridItemStore,
                itemLimit: PatientGridView.maxItemCount(in: size),
                onCallback: onCallback
            ),
            animated: true
        )
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
