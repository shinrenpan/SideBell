import SwiftUI
import UIKit

/// 兩端共用的設定畫面 C 層。
final class RoleSettingsHostController: UIHostingController<RoleSettingsView> {
    private let viewModel: RoleSettingsViewModel

    init(
        roleStore: RoleStore,
        onCallback: (@MainActor (RoleSettingsViewModel.Callback) async -> Void)? = nil
    ) {
        let viewModel = RoleSettingsViewModel(roleStore: roleStore)
        self.viewModel = viewModel
        super.init(rootView: RoleSettingsView(viewModel: viewModel))

        viewModel.onCallback = onCallback
        viewModel.onRoute = { [weak self] route in
            guard let self else { return }
            switch route {
            case .leaveRole:
                AppRouter.shared.leaveRole(from: self)
            case .sponsorship:
                AppRouter.shared.openSponsorship(from: self)
            case .gridEditing:
                // 編輯畫面的回報只是轉手：這一頁自己不顯示格子，
                // 要重載的是呈現這個 sheet 的患者端主畫面。
                AppRouter.shared.openGridEditing(from: self) { [weak self] callback in
                    guard let self else { return }
                    switch callback {
                    case .itemsDidChange:
                        await viewModel.doAction(.gridItemsDidChange)
                    }
                }
            }
        }
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
