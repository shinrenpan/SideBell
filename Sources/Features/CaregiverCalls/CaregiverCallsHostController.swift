import SwiftUI
import UIKit

/// 照顧者端呼叫清單的 C 層。
final class CaregiverCallsHostController: UIHostingController<CaregiverCallsView> {
    /// 畫面呈現後才準備警報資源。
    ///
    /// 音訊硬體的準備（工作階段啟用、緩衝配置、觸感引擎預熱）加起來會讓
    /// 「按下照顧者端」到畫面出現之間卡住數秒——實測 3–4 秒，首次安裝更久。
    /// 把它們留在轉場之前做，等於讓使用者為了聽得見警報而先盯著沒有反應的
    /// 按鈕，而凌晨解鎖進 App 的那幾秒正是最不能卡的時候。
    ///
    /// 延後的代價是畫面出現後的極短時間內音訊尚未就緒；那個縫由
    /// `AlertAudioSession.ensureActive()` 補上，它在每次播放前都會執行。
    private let onDidAppear: @MainActor () -> Void

    init(
        callCenter: CallCenter,
        alertPolicy: AlertPolicy,
        notifier: CallNotifier,
        onAlertChanged: @escaping @MainActor () -> Void,
        onDidAppear: @escaping @MainActor () -> Void
    ) {
        self.onDidAppear = onDidAppear

        let viewModel = CaregiverCallsViewModel(
            callCenter: callCenter,
            alertPolicy: alertPolicy,
            notifier: notifier,
            onAlertChanged: onAlertChanged
        )
        super.init(rootView: CaregiverCallsView(viewModel: viewModel))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 冪等：從設定分頁切回來也會走這裡，重複呼叫不會有額外效果。
        onDidAppear()
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
