import Foundation
import UserNotifications

/// App 不在前景時，把呼叫呈現在鎖屏上。
///
/// 這條路徑與音訊警報**兩者都要**，因為它們解決的問題不同：
///
/// - 通知提供鎖屏上的視覺呈現與可點擊的入口，但它的聲音**受靜音開關影響**
///   ——照顧者睡前把手機轉靜音，通知就不會出聲。
/// - 音訊播放不受靜音開關影響，但不會在鎖屏上留下任何痕跡；照顧者若在警報
///   響完後才拿起手機，會不知道發生過什麼事。
///
/// 缺任一條都會產生一個真實的漏接情境。
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
        // 用同一個警報音，且這是刻意的冗餘：通知的聲音由**系統**播放，不受
        // 我們的音訊工作階段狀態影響。背景播放結束後系統會回收音訊資源，
        // `AVAudioPlayer` 因此可能失效（實測 2026-08-11），而這條路徑不會。
        //
        // 代價是非靜音時可能聽到兩次。警報寧可重複也不要漏。
        // 通知用**專屬的音檔**，不與 App 自己播放的那個共用。
        //
        // 兩者的需求相反：`Alert.caf` 為了循環而內含 3.5 秒靜音尾巴，那對
        // 只播一次的通知毫無意義；而通知音效由系統播放，用最保守的規格
        // （22050Hz、1.5 秒）可避免相容性問題。
        //
        // 這條路徑在深層背景下特別重要：App 被 suspend 後 `AVAudioPlayer`
        // 未必拿得到執行機會（2026-08-12 的 B3 實測），而系統播放的通知音
        // 不受此限。
        content.sound = UNNotificationSound(
            named: UNNotificationSoundName("AlertNotification.caf")
        )

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
