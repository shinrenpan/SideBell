import SwiftUI
import UIKit

/// 兩端共用的設定畫面 C 層。
final class RoleSettingsHostController: UIHostingController<RoleSettingsView> {
    init(roleStore: RoleStore) {
        let viewModel = RoleSettingsViewModel(roleStore: roleStore)
        super.init(rootView: RoleSettingsView(viewModel: viewModel))

        viewModel.onRoute = { [weak self] route in
            guard let self else { return }
            switch route {
            case .leaveRole:
                AppRouter.shared.leaveRole(from: self)
            }
        }
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
