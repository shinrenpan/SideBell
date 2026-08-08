import AudioToolbox
import Foundation
import UIKit

/// 呼叫結果的非視覺回饋。
///
/// 確認是患者唯一的安心來源。畫面上的打勾對看不見的患者等於不存在，
/// 而視力不便的患者也可能剛好沒在看那一格。
///
/// ⚠️ **音效不可省略**：iPad 沒有震動硬體，而患者端多半是 iPad。
/// 把震動當成主要通道，等於在主要的目標裝置上沒有回饋。
final class CallFeedback {
    private let notificationGenerator = UINotificationFeedbackGenerator()

    /// 確認到達。
    func acknowledged() {
        notificationGenerator.notificationOccurred(.success)
        AudioServicesPlaySystemSound(Self.acknowledgedSoundID)
    }

    /// 呼叫最終無人回應。
    ///
    /// 觸感與音效都刻意與確認明顯不同——兩種結果對患者的意義相反，
    /// 混淆的代價是他以為有人要來了。
    func unanswered() {
        notificationGenerator.notificationOccurred(.error)
        AudioServicesPlaySystemSound(Self.unansweredSoundID)
    }

    /// 預先準備觸感引擎，降低首次觸發的延遲。
    func prepare() {
        notificationGenerator.prepare()
    }
}

// MARK: - 私有

private extension CallFeedback {
    /// 系統內建音效。使用系統音而非自製音檔，是因為它們在各裝置上的音量
    /// 與音色已由系統校準過，且不需要管理音訊工作階段。
    static let acknowledgedSoundID: SystemSoundID = 1057
    static let unansweredSoundID: SystemSoundID = 1053
}
