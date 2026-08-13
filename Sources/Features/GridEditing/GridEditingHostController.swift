import SwiftUI
import UIKit

/// 編輯呼叫項目的 C 層。**只在患者端被建立**——照顧者端沒有路徑到得了這裡，
/// 因為格子的資料在患者的裝置上。
///
/// ViewModel 在此組裝而非由呼叫端傳入：上層（`AppRouter`）只需要知道
/// `GridItemStore` 與一個數字，不必認識 `GridEditingViewModel` 的內部型別。
@MainActor
final class GridEditingHostController: UIHostingController<GridEditingView> {
    private let viewModel: GridEditingViewModel

    init(
        store: GridItemStore,
        itemLimit: Int,
        onCallback: @escaping @MainActor (GridEditingViewModel.Callback) async -> Void
    ) {
        let viewModel = GridEditingViewModel(store: store, itemLimit: itemLimit)
        self.viewModel = viewModel
        super.init(rootView: GridEditingView(viewModel: viewModel))

        // 導航子 VC 前先接上回報路徑：項目一有變動就往上傳，
        // 患者端的格子才會跟著更新。
        viewModel.onCallback = onCallback
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
