import SwiftUI
import UIKit

/// 傳輸層 PoC 的 C 層。
///
/// ⚠️ 丟棄式：正式畫面完成後整個 TransportPoC 目錄刪除。
final class TransportPoCHostController: UIHostingController<TransportPoCView> {
    /// 角色由容器決定，畫面本身不再提供切換——切換角色的入口在設定頁。
    init(callCenter: CallCenter, roleStore: RoleStore = .init()) {
        let viewModel = TransportPoCViewModel(callCenter: callCenter, roleStore: roleStore)
        super.init(rootView: TransportPoCView(viewModel: viewModel))

        viewModel.onRoute = { [weak self] route in
            guard let self else { return }
            switch route {
            case .openPatientSettings:
                AppRouter.shared.openPatientSettings(from: self)
            }
        }
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
