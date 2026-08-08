import AVFoundation
import Foundation

/// 觸發格子時的本機語音播報。
///
/// 存在的理由是確認：看不清或看不見螢幕的患者，否則沒有任何方式知道自己
/// 按到了哪一格——而在眼控之下，按錯是很實際的結果。
final class CallAnnouncer {
    private let synthesizer = AVSpeechSynthesizer()

    /// 播報一段文字，並中止進行中的播報。
    ///
    /// 刻意不排隊：連續誤觸數次時，排隊會讓患者聽到一長串與現況無關的內容，
    /// 而他最需要確認的只有「我剛剛按到的是什麼」。
    func announce(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: text)
        // 依系統語言選擇語音；未指定時 AVSpeechSynthesizer 會挑到不可預測的
        // 語音——實測曾出現以韓文語音朗讀中文的情況。
        utterance.voice = AVSpeechSynthesisVoice(language: Locale.current.identifier)
            ?? AVSpeechSynthesisVoice(language: "zh-TW")
        synthesizer.speak(utterance)
    }
}
