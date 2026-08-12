import AVFoundation
import Foundation
import UIKit

/// 警報的播放：音效、語音、震動。
///
/// 只管「怎麼發出來」與「多久發一次」，不管「該不該發」——後者是
/// `AlertPolicy` 的職責。重複播放時每一輪都會回頭詢問呼叫端還要不要繼續，
/// 政策的停止條件因此不必被複製到這裡。
///
/// 音訊工作階段**不在這裡設定**：它在進入照顧者角色時就要備妥，因為 BLE
/// 背景喚醒只給約 10 秒處理窗，那個預算不該花在設定音訊上。
@MainActor
final class AlertPlayer {
    /// 緊急警報的重複間隔。
    private static let repeatInterval = AlertPolicy.repeatInterval

    /// 重複次數的硬上限。
    ///
    /// 政策的三分鐘時限已經保證了終點，這個上限是**不信任呼叫端**的第二道
    /// 防線：若接線出錯讓詢問永遠回傳「還要響」，患者的求助會變成照顧者
    /// 手機上關不掉的噪音，而唯一的解法是重開 App。寧可漏響也不要停不下來。
    private static let maximumRepeats = Int(AlertPolicy.timeout / AlertPolicy.repeatInterval) + 1

    private let announcer = CallAnnouncer()
    private let feedbackGenerator = UINotificationFeedbackGenerator()
    private var player: AVAudioPlayer?
    private var repeatTask: Task<Void, Never>?
    /// 目前正在重複的那一則。用來讓 `startRepeating` 冪等——
    /// 見該方法的說明。
    private var repeatingID: UUID?
    /// 播放期間持有的背景執行時間。
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var backgroundTaskTimeout: Task<Void, Never>?

    init() {
        // 音檔載入失敗不視為錯誤：語音與震動仍是可用的通道。
        // 警報少一個通道，比因為載入失敗而完全沉默好。
        //
        // 這裡**只解析檔案，不呼叫 `prepareToPlay()`**：後者會隱式啟用音訊
        // 工作階段，而本型別是 AppDelegate 的 stored property，患者端也會
        // 建立它。實測 log（2026-08-11）顯示患者端因此印出「setActive 在
        // 主執行緒可能導致 UI 停頓」的警告——患者端根本不該碰音訊工作階段。
        // 預熱改由 `prepare()` 負責，而那只在照顧者角色下被呼叫。
        if let url = Bundle.main.url(forResource: "Alert", withExtension: "caf") {
            player = try? AVAudioPlayer(contentsOf: url)
            // 明確設到最大，不倚賴預設值。警報的音量由系統的媒體音量決定，
            // 我們能控制的只有這一段——沒有理由讓出任何一分貝。
            player?.volume = 1.0
        } else {
            SideBellLog.alert.error("警報音檔遺失，改以語音與震動播報")
        }
    }

    deinit {
        repeatTask?.cancel()
    }
}

// MARK: - 播放

extension AlertPlayer {
    /// 預先準備觸感引擎與音訊緩衝，降低首次觸發的延遲。
    func prepare() {
        feedbackGenerator.prepare()
        player?.prepareToPlay()
    }

    /// 播放一次。一般呼叫走這條路徑。
    func playOnce(title: String) {
        stopRepeating()
        player?.numberOfLoops = 0
        emit(title: title)
    }

    /// 開始重複播放某一則緊急呼叫。
    ///
    /// **重複由音檔本身的循環達成，不靠計時器**。這不是風格選擇，是必要條件：
    /// `audio` 背景模式靠「持續的音訊輸出」維持 App 執行，音檔播完 App 就會被
    /// 凍結，計時器排的下一輪永遠不會醒來。實測（2026-08-12，iPhone 在 AOD
    /// 狀態）症狀是緊急呼叫只響一次就再也沒有聲音——而那是照顧者睡著時的
    /// 常態。因此音檔內含 3.5 秒靜音段，循環播放時聽起來仍是每 5 秒響一次，
    /// 但音訊輸出從不中斷。
    ///
    /// 語音與震動仍由計時器驅動，它們搭的是音訊循環維持出來的執行時間。
    ///
    /// **對同一則呼叫重複呼叫此方法不會有任何效果**。這個冪等性是必要的：
    /// 接線後每一個傳輸事件都會來刷新警報狀態，若每次都重啟，警報會在事件
    /// 密集時變成連續噪音，而重複間隔形同虛設。
    ///
    /// - Parameters:
    ///   - id: 這一則呼叫的識別碼。與目前正在重複的相同時直接返回。
    ///   - next: 每一輪詢問「下一則要播什麼」。回傳 nil 即停止。
    ///     呼叫端在這裡檢查政策的停止條件（已確認、已逾時、已離開角色）。
    func startRepeating(id: UUID, next: @escaping () -> String?) {
        guard repeatingID != id || repeatTask == nil else { return }

        stopRepeating()
        repeatingID = id

        // 無限循環。停止條件由下方的迴圈負責，而不是靠次數上限。
        //
        // 只切換循環模式，**不重新啟動播放**：呼叫端在收到呼叫時已經先
        // `playOnce` 過了，這裡再 `play()` 一次會把進行中的播放打斷，
        // 實測（2026-08-12）的症狀是完全沒有聲音。只有在確實沒在播時
        // 才啟動——例如中斷結束後的恢復。
        player?.numberOfLoops = -1
        if player?.isPlaying != true {
            playSound()
        }

        repeatTask = Task { [weak self] in
            for _ in 0..<Self.maximumRepeats {
                try? await Task.sleep(for: .seconds(Self.repeatInterval))
                guard let self, !Task.isCancelled else { return }

                guard let title = next() else {
                    stop()
                    return
                }
                // 音效已在循環中，這裡只補語音與震動。
                announcer.announce(title)
                feedbackGenerator.notificationOccurred(.warning)
            }
            SideBellLog.alert.error("警報達重複上限仍未停止，強制中止")
            self?.stop()
        }
    }

    /// 停止重複，並中斷進行中的音效與語音。
    func stop() {
        stopRepeating()
        player?.stop()
        player?.numberOfLoops = 0
        player?.currentTime = 0
        announcer.stop()
        endPlaybackBackgroundTask()
    }
}

// MARK: - 私有

private extension AlertPlayer {
    /// 三個通道同時發出。任一個失敗都不影響其他兩個——照顧者可能正戴著
    /// 耳機、可能把手機放在桌上、可能在另一個房間，沒有哪一個通道是可靠的。
    func emit(title: String) {
        playSound()
        announcer.announce(title)
        feedbackGenerator.notificationOccurred(.warning)
    }

    /// 播放警報音，失敗時重新準備後再試一次。
    ///
    /// `AVAudioPlayer.play()` 回傳 `Bool` 而**失敗是靜默的**。實測
    /// （2026-08-11）症狀是「第一則呼叫有聲音，第二則之後就再也沒有」——
    /// 背景播放結束後系統會回收音訊資源，player 隨之失效，而忽略回傳值
    /// 的話完全看不出發生了什麼。
    func playSound() {
        guard let player else { return }

        // 播放期間明確申請背景執行時間。
        //
        // `audio` 背景模式靠「確實有音訊輸出」維持 App 執行，而實測
        // （2026-08-11）顯示靜音開關開啟時系統似乎判定沒有輸出，在播放途中就把
        // App 凍結——聽到的只有喇叭通電的那幾毫秒，像蜂鳴器接電源的「波」一聲。
        // 這正是照顧者夜間的設定（手機靜音放床頭），不能漏。
        beginPlaybackBackgroundTask()

        player.currentTime = 0
        let started = player.play()
        // ⚠️ 暫時的診斷輸出（2026-08-12，長時間背景後無警報聲），定位後移除。
        SideBellLog.alert.error(
            "播放 started=\(started) isPlaying=\(player.isPlaying) loops=\(player.numberOfLoops)"
        )
        guard !started else { return }

        SideBellLog.alert.error("警報音播放失敗，重新準備後重試")
        player.prepareToPlay()
        player.currentTime = 0
        if !player.play() {
            SideBellLog.alert.error("警報音重試仍失敗，僅剩語音與震動")
        }
    }

    func stopRepeating() {
        repeatTask?.cancel()
        repeatTask = nil
        repeatingID = nil
    }

    /// 為一次播放申請背景執行時間，並在音檔長度過後歸還。
    ///
    /// 不歸還的後果是系統在逾時後強制終止 App——比漏一次警報嚴重得多。
    func beginPlaybackBackgroundTask() {
        endPlaybackBackgroundTask()

        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "SideBellAlert") {
            // 系統即將收回時間時的清理路徑。
            MainActor.assumeIsolated { self.endPlaybackBackgroundTask() }
        }

        // 循環播放時不排自動歸還——那要由 `stop()` 負責，而 `stop()` 一定會
        // 被呼叫：政策的三分鐘時限、確認、離開角色三條路徑都會走到它，
        // 重複迴圈本身也有次數上限作為最後一道保險。
        guard player?.numberOfLoops != -1 else { return }

        let duration = min(max(player?.duration ?? 2, 0.5), 8)
        backgroundTaskTimeout = Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration + 0.5))
            self?.endPlaybackBackgroundTask()
        }
    }

    func endPlaybackBackgroundTask() {
        backgroundTaskTimeout?.cancel()
        backgroundTaskTimeout = nil

        guard backgroundTask != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
}
