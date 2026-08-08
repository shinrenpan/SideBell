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
                AppRouter.shared.openPatientSettings(from: self)
            }
        }
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
