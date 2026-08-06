import SwiftUI
import UIKit

/// 傳輸層 PoC 的 C 層。
///
/// ⚠️ 丟棄式：正式畫面完成後整個 TransportPoC 目錄刪除。
final class TransportPoCHostController: UIHostingController<TransportPoCView> {
    init(callCenter: CallCenter, roleStore: RoleStore, onRoleChange: @escaping (AppRole) -> Void) {
        let viewModel = TransportPoCViewModel(callCenter: callCenter, roleStore: roleStore)
        viewModel.onRoleChange = onRoleChange
        super.init(rootView: TransportPoCView(viewModel: viewModel))
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
