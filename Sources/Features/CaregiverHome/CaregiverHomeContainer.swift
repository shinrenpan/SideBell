import UIKit

/// 照顧者端容器。
///
/// 兩個分頁各自持有導覽堆疊——兩邊後續都會有子頁（呼叫詳情、設定項目）。
/// 照顧者端沒有患者端的誤觸顧慮：使用者是有完整操作能力的家屬或看護。
final class CaregiverHomeContainer: UITabBarController {
    init(
        callCenter: CallCenter,
        roleStore: RoleStore,
        alertPolicy: AlertPolicy,
        notifier: CallNotifier,
        onAlertChanged: @escaping @MainActor () -> Void,
        onDidAppear: @escaping @MainActor () -> Void
    ) {
        super.init(nibName: nil, bundle: nil)

        let calls = UINavigationController(
            rootViewController: CaregiverCallsHostController(
                callCenter: callCenter,
                alertPolicy: alertPolicy,
                notifier: notifier,
                onAlertChanged: onAlertChanged,
                onDidAppear: onDidAppear
            )
        )
        // UIKit 不吃 `LocalizedStringKey`，字面值必須自己包進 `String(localized:)`，
        // 否則編譯器擷取不到。
        calls.tabBarItem = UITabBarItem(
            title: String(localized: "Calls"),
            image: UIImage(systemName: "bell"),
            selectedImage: UIImage(systemName: "bell.fill")
        )

        let settings = UINavigationController(
            rootViewController: RoleSettingsHostController(roleStore: roleStore)
        )
        settings.tabBarItem = UITabBarItem(
            title: String(localized: "Settings"),
            image: UIImage(systemName: "gearshape"),
            selectedImage: UIImage(systemName: "gearshape.fill")
        )

        viewControllers = [calls, settings]
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
