import AVFoundation
import Foundation

/// 觸發格子時的本機語音播報。
///
/// 存在的理由是確認：看不清或看不見螢幕的患者，否則沒有任何方式知道自己
/// 按到了哪一格——而在眼控之下，按錯是很實際的結果。
final class CallAnnouncer {
    private let synthesizer: AVSpeechSynthesizer = {
        let synthesizer = AVSpeechSynthesizer()
        // 用 App 自己的音訊工作階段，不要讓它另建一個。
        //
        // 預設行為下，合成器說完後會停用它自己的工作階段——而那會連帶影響
        // 我們在照顧者端設定的警報工作階段。實測（2026-08-11）症狀是「背景時
        // 第一則呼叫有聲音，之後每一則的 `play()` 都回傳成功卻聽不到」。
        synthesizer.usesApplicationAudioSession = true
        return synthesizer
    }()

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
        // 略慢於系統預設（0.5）。聽的人可能是聽力退化的長者，也可能是隔著
        // 一個房間的照顧者；播報只有短短幾個字，放慢的代價很小。
        utterance.rate = 0.45
        synthesizer.speak(utterance)
    }

    /// 中斷進行中的播報。
    ///
    /// 警報停止時必須連語音一起停：照顧者已經按下確認，卻還聽著裝置唸出
    /// 那則呼叫，會讓他懷疑確認到底有沒有送出去。
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
