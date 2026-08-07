import SwiftUI
import UIKit

/// 首頁的 C 層。
final class RoleSelectionHostController: UIHostingController<RoleSelectionView> {
    init(disclaimerStore: DisclaimerStore, availability: BluetoothAvailability) {
        let viewModel = RoleSelectionViewModel(
            disclaimerStore: disclaimerStore,
            availability: availability
        )
        super.init(rootView: RoleSelectionView(viewModel: viewModel))

        viewModel.onRoute = { [weak self] route in
            guard let self else { return }
            switch route {
            case let .enterRole(role):
                AppRouter.shared.enterRole(role, from: self)
            }
        }
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
