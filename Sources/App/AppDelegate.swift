import UIKit

/// SideBell 的應用程式進入點。
///
/// 採 UIKit 生命週期而非 SwiftUI `App`，是因為 Core Bluetooth 的狀態還原
/// 要求在啟動最早期就重建 manager；系統可能在完全沒有場景的情況下，
/// 因 BLE 事件把 App 於背景喚醒。
@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    /// 與 App 同壽命的事件消費者。場景可能還不存在，但它必須已經在聽。
    private(set) var callCenter: CallCenter?
    private(set) var roleStore = RoleStore()
    private(set) var disclaimerStore = DisclaimerStore()
    /// 資料容器由此持有——`ModelContext` 不持有 `ModelContainer`，
    /// 容器一旦被回收就會留下指向已死容器的 context，下次操作直接崩潰。
    private(set) lazy var modelContainer = SideBellModelContainer.make()
    private(set) lazy var gridItemStore = GridItemStore(context: modelContainer.mainContext)
    private(set) var callDelivery: CallDelivery?
    let callAnnouncer = CallAnnouncer()
    let callFeedback = CallFeedback()

    /// 照顧者端的警報三件套。與 App 同壽命：警報要在畫面不存在時也能響，
    /// 而背景喚醒時畫面正是不存在的。
    let alertPolicy = AlertPolicy()
    let alertPlayer = AlertPlayer()
    let alertAudioSession = AlertAudioSession()
    let callNotifier = CallNotifier()
    /// 警報的事件消費者。與 App 同壽命，只在 deinit 結束。
    private var alertTask: Task<Void, Never>?

    /// 不依賴角色的藍牙可用性觀察者，供首頁使用。
    /// 此處只建立物件，`startObserving()` 要等使用者確認免責聲明後才呼叫——
    /// 那一步才會建立 manager 並觸發權限請求。
    private(set) var bluetoothAvailability = BluetoothAvailability()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // 順序固定且不可調換：讀角色 → 建傳輸層 → 接消費者 → 啟動。
        // 三者都必須在任何場景啟動之前完成。
        let role = roleStore.role

        // 暱稱尚無設定介面，傳 nil：照顧者端會顯示系統的藍牙裝置名稱。
        let transport = BLETransport(nickname: nil)
        let callCenter = CallCenter(transport: transport)
        self.callCenter = callCenter

        // 呼叫生命週期與傳輸層同時建立：待送佇列與逾時判定不能綁在畫面上，
        // 那會讓它們隨畫面生滅。
        let delivery = CallDelivery(transport: transport)
        self.callDelivery = delivery
        delivery.start()

        // 警報自己取一條事件流，不共用 `CallCenter.onEvent`。
        //
        // 那個 closure 只有一個插槽，而照顧者端的畫面出現時會把它接走——
        // 警報若也搶那個位置，兩者會互相覆蓋，症狀是「開著畫面就不會響」
        // 或「響了但畫面不更新」。這與 W3 修掉的事件瓜分是同一類錯誤，
        // 差別只在那次是 `AsyncStream` 不多播，這次是 closure 只有一份。
        startAlertConsumer(on: transport)

        // 中斷（來電、鬧鐘）結束後系統不會自動恢復播放。不接這條線的後果：
        // 照顧者接了一通電話，講完之後那則還沒確認的緊急呼叫就再也不會響了
        // ——而他以為警報還在替他守著。
        alertAudioSession.onInterruptionEnded = { [weak self] in
            self?.refreshAlert()
        }

        applyAlertReadiness(for: role)

        if let transportRole = role.transportRole {
            callCenter.start(as: transportRole)
        }

        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}

// MARK: - 角色切換

extension AppDelegate {
    /// 供設定或角色選擇畫面呼叫。切換角色會重建傳輸層的角色綁定。
    ///
    /// 角色未變更時不動傳輸：啟動流程會先在 `didFinishLaunching` 依既有角色
    /// 啟動傳輸，接著場景配置又會走一次進入角色的路徑。若不擋掉，剛建立的
    /// 連線會在使用者還沒看到畫面時就被拆掉重來。
    func updateRole(_ role: AppRole) {
        let previous = roleStore.role
        roleStore.save(role)

        guard previous != role, let callCenter else { return }

        applyAlertReadiness(for: role)

        callCenter.stop()
        if let transportRole = role.transportRole {
            callCenter.start(as: transportRole)
        }
    }

    /// 備妥照顧者端的警報資源。由照顧者畫面在呈現後呼叫。
    ///
    /// 冪等，重複呼叫不會有額外效果。
    func prepareCaregiverAlert() {
        guard roleStore.role == .caregiver else { return }
        alertAudioSession.activate()
        alertPlayer.prepare()
    }

    /// 依政策目前的狀態決定要不要響、響哪一則。
    ///
    /// 這是警報唯一的驅動點：收到呼叫、送出確認、音訊中斷結束，全部走這裡。
    /// 分散在各處自行呼叫 `AlertPlayer` 會讓「什麼時候該停」散成好幾份，
    /// 而漏掉任何一份的症狀都是警報停不下來。
    func refreshAlert() {
        alertPolicy.checkTimeouts()

        guard let alert = alertPolicy.currentAlert else {
            alertPlayer.stop()
            return
        }

        alertPlayer.startRepeating(id: alert.id) { [weak self] in
            guard let self else { return nil }
            alertPolicy.checkTimeouts()
            return alertPolicy.currentAlert?.title
        }
    }
}

// MARK: - 私有

private extension AppDelegate {
    /// 與 App 同壽命的警報消費者。
    ///
    /// 必須獨立於畫面：呼叫可能在照顧者鎖著螢幕時到達，那時 App 被 BLE 事件
    /// 於背景喚醒，畫面與 ViewModel 都不存在——若由畫面驅動警報，那則呼叫
    /// 等於沒有人接。
    func startAlertConsumer(on transport: any CallTransport) {
        let events = transport.makeEventStream()
        alertTask = Task { [weak self] in
            for await event in events {
                guard let self else { return }
                handleAlertEvent(event)
            }
        }
    }

    func handleAlertEvent(_ event: TransportEvent) {
        // 患者端不響警報：它收到的確認由格子自己呈現，那是另一套回饋。
        guard roleStore.role == .caregiver else { return }
        guard case let .callReceived(message, peerName) = event else { return }

        // ⚠️ 暫時的診斷輸出（2026-08-12，長時間背景後無警報聲），定位後移除。
        // 不含患者內容，只記 App 的執行狀態。
        SideBellLog.alert.error(
            "收到呼叫 appState=\(UIApplication.shared.applicationState.rawValue) urgent=\(message.isUrgent)"
        )

        alertPolicy.register(message)

        // 先取回音訊焦點再播。其他 App 在前景播放時會把焦點拿走，
        // 少了這一步，警報在「照顧者邊聽音樂邊做事」時完全沉默。
        alertAudioSession.ensureActive()

        // 到達當下一律響一次，不論緊急與否——那是「有事情發生了」的提示。
        // 之後要不要繼續響，由 refreshAlert 依政策決定。
        alertPlayer.playOnce(title: message.title)
        refreshAlert()

        // 前景時畫面本身就是呈現，再送通知只會在螢幕上疊一層橫幅擋住清單。
        guard UIApplication.shared.applicationState != .active else { return }
        callNotifier.notify(message, peerName: peerName)
    }

    /// 離開照顧者角色時收掉警報資源。
    ///
    /// **只負責關，不負責開**：開的那一側成本高（音訊工作階段、緩衝配置、
    /// 觸感引擎），放在角色切換的路徑上會卡住畫面轉場，因此改由照顧者端
    /// 畫面的 `viewDidAppear` 觸發——見 `prepareCaregiverAlert()`。
    ///
    /// 患者端不需要音訊工作階段：它只播報自己按了什麼，用系統音效即可，
    /// 而佔用 `.playback` 類別會讓患者端在背景時無謂地保有音訊焦點。
    func applyAlertReadiness(for role: AppRole) {
        guard role != .caregiver else { return }

        // 只在確實可能有警報在響時才碰播放器——患者端從未播放過，
        // 而 `stop()` 會經由語音合成器 touch 到音訊工作階段。
        if alertPolicy.currentAlert != nil {
            alertPlayer.stop()
        }
        alertPolicy.reset()
        alertAudioSession.deactivate()
    }

    // 裝置名稱不再由此提供。
    //
    // 實測發現照顧者端的 `CBPeripheral.name` 就能取得系統設定裡的完整名稱
    // （例如「Joe iPad mini 7」），比 `UIDevice.current.name` 好——後者自
    // iOS 16 起只回傳機型名稱（「iPad」）。因此 Device Info 特徵的語意改為
    // 「患者自訂暱稱」，未設定時不傳，讓照顧者端沿用系統名稱。
}
