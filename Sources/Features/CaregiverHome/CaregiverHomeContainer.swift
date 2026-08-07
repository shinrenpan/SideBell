import UIKit

/// 照顧者端容器。
///
/// 兩個分頁各自持有導覽堆疊——兩邊後續都會有子頁（呼叫詳情、設定項目）。
/// 照顧者端沒有患者端的誤觸顧慮：使用者是有完整操作能力的家屬或看護。
final class CaregiverHomeContainer: UITabBarController {
    init(callCenter: CallCenter, roleStore: RoleStore) {
        super.init(nibName: nil, bundle: nil)

        // 分頁一暫時沿用 W1 的傳輸驗證畫面；正式的呼叫清單與歷史紀錄
        // 屬後續里程碑。
        let calls = UINavigationController(
            rootViewController: TransportPoCHostController(callCenter: callCenter)
        )
        calls.tabBarItem = UITabBarItem(
            title: "呼叫",
            image: UIImage(systemName: "bell"),
            selectedImage: UIImage(systemName: "bell.fill")
        )

        let settings = UINavigationController(
            rootViewController: RoleSettingsHostController(roleStore: roleStore)
        )
        settings.tabBarItem = UITabBarItem(
            title: "設定",
            image: UIImage(systemName: "gearshape"),
            selectedImage: UIImage(systemName: "gearshape.fill")
        )

        viewControllers = [calls, settings]
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
