import UIKit

/// 患者端容器。
///
/// 只做導覽裝配與防休眠，不持有任何畫面狀態——設定入口屬於主畫面的
/// toolbar，狀態歸該畫面的 ViewModel，導航經由 `onRoute` 交給 C 層。
final class PatientHomeContainer: UINavigationController {
    init(
        callCenter: CallCenter,
        roleStore: RoleStore,
        store: GridItemStore,
        delivery: CallDelivery,
        announcer: CallAnnouncer,
        feedback: CallFeedback
    ) {
        super.init(
            rootViewController: PatientGridHostController(
                store: store,
                delivery: delivery,
                announcer: announcer,
                feedback: feedback,
                callCenter: callCenter
            )
        )
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setIdleTimerDisabled(true)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        setIdleTimerDisabled(false)
    }
}

// MARK: - 防休眠

private extension PatientHomeContainer {
    /// 患者端停留期間停用自動鎖定。
    ///
    /// 這不是偏好而是必要條件：裝置鎖屏後純眼控的患者**無法喚醒它**
    /// （眼球追蹤在鎖定畫面不運作），螢幕一暗整套呼叫系統即等同離線，
    /// 而患者沒有任何辦法讓它回來。
    ///
    /// 放在容器而非畫面，是因為患者端之後會有多個畫面（例如格子編輯），
    /// 防休眠應涵蓋整段停留期間；而恢復必須確實發生——照顧者端的手機
    /// 不能跟著一起不睡。
    func setIdleTimerDisabled(_ disabled: Bool) {
        UIApplication.shared.isIdleTimerDisabled = disabled
        SideBellLog.transport.info("patient: 自動鎖定 \(disabled ? "已停用" : "已恢復", privacy: .public)")
    }
}
