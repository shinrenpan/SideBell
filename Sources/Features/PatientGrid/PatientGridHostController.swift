import SwiftUI
import UIKit

/// 患者端主畫面的 C 層。
final class PatientGridHostController: UIHostingController<PatientGridView> {
    init(
        store: GridItemStore,
        delivery: CallDelivery,
        announcer: CallAnnouncer,
        feedback: CallFeedback,
        callCenter: CallCenter
    ) {
        let viewModel = PatientGridViewModel(
            store: store,
            delivery: delivery,
            announcer: announcer,
            feedback: feedback,
            callCenter: callCenter
        )
        super.init(rootView: PatientGridView(viewModel: viewModel))

        viewModel.onRoute = { [weak self] route in
            guard let self else { return }
            switch route {
            case .openSettings:
                // 設定是 sheet，這個畫面在它底下不會 disappear，因此
                // 關閉後 `onAppear` 不會再跑。項目變動要靠這條回報路徑
                // 才會反映到格子上。
                AppRouter.shared.openPatientSettings(from: self) { [weak self] callback in
                    guard let self else { return }
                    switch callback {
                    case .gridItemsDidChange:
                        await viewModel.doAction(.reloadItems)
                    }
                }
            }
        }
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
