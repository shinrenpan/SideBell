import Foundation
import UserNotifications

/// App 不在前景時，把呼叫呈現在鎖屏上。
///
/// 這條路徑與音訊警報**兩者都要**，因為它們解決的問題不同：
///
/// - **通知**在鎖屏上留下可見的痕跡與可點擊的入口。音訊響完就消失了，照顧者
///   若在事後才拿起手機，沒有通知就不知道發生過什麼事。
/// - **音訊**是主要的聲音通道，且不受靜音開關影響（2026-08-12 實測，靜音、
///   背景、他人正在播音樂的組合皆能持續發聲）。
///
/// 通知的聲音另有價值：它由**系統**播放，不依賴 App 拿到執行機會。App 在
/// 深層背景被 suspend 時，那可能是唯一還會出聲的通道。
@MainActor
final class CallNotifier {
    private let center = UNUserNotificationCenter.current()
}

// MARK: - 權限

extension CallNotifier {
    /// 請求通知權限。
    ///
    /// 時機由呼叫端決定，且應該是**進入照顧者角色時**而非 App 啟動時：
    /// 啟動時請求會與藍牙權限擠在一起，而此時使用者還不知道通知要用來做什麼。
    ///
    /// 已經決定過的使用者不會再看到系統彈窗（那是 `UNUserNotificationCenter`
    /// 的行為），因此重複呼叫是安全的——但仍不該主動重問，反覆騷擾只會讓
    /// 刻意拒絕的照顧者更抗拒。
    func requestAuthorization() {
        // 不要 `.badge`：未讀數字對警報沒有意義，患者的呼叫不是待辦事項。
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                SideBellLog.alert.error(
                    "通知權限請求失敗 \(String(describing: error), privacy: .public)"
                )
                return
            }
            SideBellLog.alert.info("通知權限 granted=\(granted)")
        }
    }
}

// MARK: - 送出

extension CallNotifier {
    /// 送出一則呼叫通知。
    ///
    /// 未授權時系統會直接拒絕這個請求，這裡不預先查詢權限狀態、也不因此
    /// 改變行為——呼叫端不該為了權限而長出分支，那會讓「有沒有響」的判斷
    /// 散到兩個地方。
    func notify(_ message: CallMessage, peerName: String) {
        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = peerName
        // 用**系統預設音效**，不用自訂音檔。
        //
        // 這條路徑在深層背景下特別重要：App 被 suspend 後音訊工作階段會被
        // 系統拆除，`AVAudioPlayer` 未必發得出聲（2026-08-13 的 B3 log），
        // 而通知音由系統播放，不受此限。它是警報失效時的最後一道聲音。
        //
        // 既然是最後一道，就不該冒任何風險。自訂音檔（`AlertNotification.caf`，
        // 規格檢查過是合規的 Linear PCM）在 B3 實測中完全沒出聲，而前一天用
        // 系統預設時聽得到——換句話說**自訂音檔這條路目前無法證明可靠**。
        // 辨識度換不到這個。系統預設是已知可用的基準，就用它。
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: message.id.uuidString,
            content: content,
            // nil 代表立即送出。呼叫已經在路上耽擱過了，不該再排程。
            trigger: nil
        )

        center.add(request) { error in
            guard let error else { return }
            // 未授權會走到這裡。靜默記錄即可——照顧者刻意拒絕過，
            // 不該再用任何方式提醒他。
            SideBellLog.alert.info(
                "通知未送出 \(String(describing: error), privacy: .public)"
            )
        }
    }

    /// 移除某一則已送出的通知。
    ///
    /// 照顧者在 App 內按下確認後，鎖屏上那則通知就過期了——留著會讓他
    /// 稍後解鎖時以為還有事情沒處理。
    func clear(_ callID: UUID) {
        center.removeDeliveredNotifications(withIdentifiers: [callID.uuidString])
    }
}
