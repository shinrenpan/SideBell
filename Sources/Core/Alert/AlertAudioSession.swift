import AVFoundation
import Foundation

/// 警報用的音訊工作階段。
///
/// **在進入照顧者角色時就備妥，不等第一則呼叫**：BLE 背景喚醒只給約 10 秒
/// 處理窗，那個預算要留給送出通知與播放，不該花在設定音訊上。
@MainActor
final class AlertAudioSession {
    /// 中斷（來電、鬧鐘）結束時呼叫。呼叫端在此決定要不要恢復警報——
    /// 這個型別不知道還有沒有未確認的呼叫，那是政策的職責。
    var onInterruptionEnded: (() -> Void)?

    /// 中斷觀察者。由 `deactivate()` 負責移除。
    ///
    /// 刻意沒有 `deinit`：本型別由 `AppDelegate` 持有、與 App 同壽命，實際上
    /// 不會被解構；而 MainActor 隔離的 `deinit` 在 Swift 6 下也碰不到這個
    /// 非 Sendable 的值。觀察者的 closure 以 weak 捕獲，因此即使真的被解構，
    /// 留在 NotificationCenter 裡的也只是一個立刻返回的空殼。
    private var interruptionObserver: NSObjectProtocol?

    /// 是否已啟用。
    ///
    /// 沒有這個旗標的後果（2026-08-11 實機 log 發現）：患者端在啟動與選擇角色時
    /// 各會呼叫一次 `deactivate()`——即使它從未啟用過音訊——每次都讓系統印出
    /// 「setActive 在主執行緒可能導致 UI 停頓」的警告。患者端完全不該碰音訊
    /// 工作階段，那是照顧者端才有的東西。
    private var isActive = false
}

// MARK: - 生命週期

extension AlertAudioSession {
    /// 設定並啟用。由照顧者端畫面在呈現後呼叫。重複呼叫不會有額外效果。
    ///
    /// 這裡同步執行。`setActive(true)` 確實可能耗時（系統 log 從 W4 第一天
    /// 就在警告 `UI unresponsiveness`），但那個卡頓的主因是整批準備工作被
    /// 放在角色切換的路徑上——移到 `viewDidAppear` 之後即消失（見
    /// `CaregiverCallsHostController`）。
    ///
    /// 一度改為 `Task.detached` 執行以避開阻塞，但那讓啟用變成非同步、與
    /// `ensureActive()` 的同步呼叫產生不必要的競爭空間。移除後實測確認
    /// **延後之後同步執行也不卡**（2026-08-12），因此背景執行是多餘的。
    func activate() {
        guard !isActive else { return }
        isActive = true

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: Self.categoryOptions)
            try session.setActive(true)
        } catch {
            // 設定失敗不阻斷角色進入：語音與震動仍可用，本地通知也仍會送出。
            // 完全擋住使用者進入照顧者端，比少一個音訊通道嚴重得多。
            SideBellLog.alert.error(
                "音訊工作階段啟用失敗 \(String(describing: error), privacy: .public)"
            )
        }
        observeInterruptions()
    }

    /// 播放前確保仍持有音訊焦點。
    ///
    /// **每次播放前都要呼叫**。進入角色時的那一次 `activate()` 不足夠：
    /// 其他 App（音樂、影片）在前景播放時會取得音訊焦點，我們的工作階段
    /// 隨之被系統停用。實測（2026-08-11）症狀是「SideBell 在背景、Spotify
    /// 在前景時，呼叫只剩推播與震動，完全沒有警報聲」——而那正是照顧者
    /// 邊聽音樂邊做事的日常。
    ///
    /// 從未設定過（患者端）時不做任何事。
    func ensureActive() {
        guard isActive else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            // **只在設定確實不符時才寫回**：`setCategory` 會重建音訊路由，
            // 而重建會吃掉開頭幾個音框。實測（2026-08-12）症狀是第一次播放
            // 只聽到「嗚」的半聲，第二次起才完整——警報的第一聲正是最需要
            // 完整的那一聲。
            //
            // 長時間背景後系統會把工作階段連同類別一起拆掉，那時這裡就是
            // 重新設定的地方；平常則什麼都不做。
            //
            // 比對用**包含**而非相等：系統會自行補上我們沒要求的旗標——實測
            // （2026-08-13）設定 `.duckOthers`（2）之後讀回來是 3，因為 duck
            // 隱含 `.mixWithOthers`（1）。用相等比對會每次都判定不符，於是
            // 每則呼叫都重建一次路由，正是上面要避免的事。
            if session.category != .playback
                || !session.categoryOptions.isSuperset(of: Self.categoryOptions) {
                try session.setCategory(.playback, mode: .default, options: Self.categoryOptions)
            }
            try session.setActive(true)
            // ⚠️ 暫時的診斷輸出（2026-08-12，長時間背景後無警報聲），定位後移除。
            SideBellLog.alert.error(
                """
                音訊就緒 options=\(session.categoryOptions.rawValue) \
                otherAudio=\(session.isOtherAudioPlaying) \
                volume=\(session.outputVolume)
                """
            )
        } catch {
            SideBellLog.alert.error(
                "重新取得音訊焦點失敗 \(String(describing: error), privacy: .public)"
            )
        }
    }

    /// 停用並讓出音訊。離開照顧者角色時呼叫。從未啟用過則不做任何事。
    func deactivate() {
        guard isActive else { return }
        isActive = false

        if let interruptionObserver {
            NotificationCenter.default.removeObserver(interruptionObserver)
            self.interruptionObserver = nil
        }
        do {
            // `.notifyOthersOnDeactivation`：讓被我們中斷的音樂自己恢復播放。
            // 少了這個旗標，照顧者切換角色後音樂不會回來，得手動按播放。
            try AVAudioSession.sharedInstance().setActive(
                false,
                options: .notifyOthersOnDeactivation
            )
        } catch {
            SideBellLog.alert.error(
                "音訊工作階段停用失敗 \(String(describing: error), privacy: .public)"
            )
        }
    }
}

// MARK: - 私有

private extension AlertAudioSession {
    /// 音訊類別的選項。**恆為 `.duckOthers`，不看當下有沒有別人在播。**
    ///
    /// 約束是這條：**背景 App 不得啟用會中斷他人的音訊工作階段**。獨佔模式
    /// （空選項）就屬於這一類，`setActive` 會回
    /// `AVAudioSessionErrorCodeCannotInterruptOthers`（`560557684`），結果是
    /// 完全無聲。`.duckOthers` 隱含混音，不觸發這條規則。
    ///
    /// 一度依 `isOtherAudioPlaying` 分流「有人在播就 duck，沒人在播就獨佔」。
    /// **那是錯的**（2026-08-13 由裝置 log 推翻）：這條規則管的是 App 在不在
    /// 背景，不是有沒有人在播。長時間背景後工作階段已被系統拆除，重新啟用
    /// 時就會撞上——而 `isOtherAudioPlaying` 此時是 false，正好選到獨佔模式。
    /// 實測 B3（背景八小時後收到呼叫）四次全部無聲，log 每次都是那個錯誤碼。
    ///
    /// 短時間背景測不出來：工作階段沒被拆過，`setActive(true)` 對已啟用的
    /// 階段是 no-op，不會走到啟用判定。
    ///
    /// duck 沒有代價：`.playback` 類別本身就不受靜音開關管轄，混音與否不改變
    /// 這件事（2026-08-12 實測，靜音 ＋ 背景 ＋ 對方正在播音樂仍持續發聲）。
    /// 完整推導見 `DECISIONS.md` 2026-08-12、2026-08-13。
    static let categoryOptions: AVAudioSession.CategoryOptions = [.duckOthers]

    /// 來電或鬧鐘會中斷我們的音訊，且**中斷結束後系統不會自動恢復**。
    /// 不處理的後果：照顧者接了一通電話，講完之後那則還沒確認的緊急呼叫
    /// 就再也不會響了——而他以為警報還在替他守著。
    func observeInterruptions() {
        guard interruptionObserver == nil else { return }

        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            guard
                let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                let type = AVAudioSession.InterruptionType(rawValue: raw),
                type == .ended
            else { return }

            MainActor.assumeIsolated {
                guard let self else { return }
                // 中斷期間工作階段被系統停用，恢復播放前必須重新啟用。
                try? AVAudioSession.sharedInstance().setActive(true)
                self.onInterruptionEnded?()
            }
        }
    }
}
