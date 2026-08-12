import Foundation

/// 警報該不該響、要不要繼續響、什麼時候停。
///
/// 這裡**只有規則，沒有平台**：不 import AVFoundation、不碰音訊工作階段、
/// 不知道音效長什麼樣。分離的理由是驗證成本——逾時規則要等三分鐘才看得到
/// 一次結果，而「緊急呼叫響一次就停」或「確認後還在響」這類錯誤只有在真機上
/// 聽著才會發現。規則抽成純邏輯後，注入時間來源即可在毫秒內驗完。
///
/// 狀態只存在記憶體：App 重啟後復活的舊呼叫是假警報，而假警報會侵蝕
/// 照顧者對警示的信任。
@Observable
final class AlertPolicy {
    /// 自**患者按下**起算的停止時限，與患者端的逾時同一個基準點。
    ///
    /// 若改從「照顧者收到」起算，一則排隊兩分鐘才送達的呼叫會讓照顧者比
    /// 患者晚兩分鐘才停止警報——而患者端此時早已顯示「無人回應」。照顧者
    /// 會為一則患者已經放棄的呼叫奔走。
    nonisolated static let timeout: TimeInterval = CallDelivery.timeout

    /// 緊急警報的重複間隔。
    nonisolated static let repeatInterval: TimeInterval = 5

    /// 尚未確認、尚未逾時的緊急呼叫，依患者按下的先後排列。
    ///
    /// 只收緊急呼叫：一般呼叫在到達時響一次就結束，沒有「還要不要繼續響」
    /// 的問題，留在這裡只會讓停止條件的判斷多一個無意義的分支。
    private(set) var outstanding: [OutstandingAlert] = []

    @ObservationIgnored private let now: () -> Date

    /// - Parameter now: 時間來源。可注入讓逾時測試不必真的等三分鐘。
    init(now: @escaping () -> Date = { Date() }) {
        self.now = now
    }
}

// MARK: - 登記與解除

extension AlertPolicy {
    /// 登記一則到達的呼叫。
    ///
    /// **到達當下要響一次**是呼叫端的責任，與這個方法無關——政策只回答
    /// 「之後還需不需要繼續響」。這個分工讓一般呼叫不必為了響那一次而被
    /// 放進集合裡，再立刻被移除。
    func register(_ message: CallMessage) {
        guard message.isUrgent else { return }
        // 送達時就已經超過時限：照顧者端剛從長時間背景醒來時會遇到。
        // 此時患者端早已顯示「無人回應」，開始重複警報只會製造矛盾。
        guard !hasExpired(pressedAt: message.timestamp) else { return }
        guard !outstanding.contains(where: { $0.id == message.id }) else { return }

        outstanding.append(
            OutstandingAlert(
                id: message.id,
                title: message.title,
                pressedAt: message.timestamp
            )
        )
        outstanding.sort { $0.pressedAt < $1.pressedAt }
    }

    /// 照顧者確認了某一則呼叫。未登記的識別碼會被安靜忽略——一般呼叫與
    /// 已逾時的呼叫本來就不在集合裡，那不是錯誤。
    func acknowledge(_ callID: UUID) {
        outstanding.removeAll { $0.id == callID }
    }

    /// 移除已達時限的呼叫。對外開放供測試以受控時間驅動。
    func checkTimeouts() {
        outstanding.removeAll { hasExpired(pressedAt: $0.pressedAt) }
    }

    /// 離開照顧者角色：停止一切。
    func reset() {
        outstanding.removeAll()
    }
}

// MARK: - 查詢

extension AlertPolicy {
    /// 目前應該持續響的那一則，沒有則為 nil。
    ///
    /// 刻意只回傳一則：同時響兩個警報只會讓兩者都聽不清楚，而照顧者要做的
    /// 事情是一樣的——去看患者。先到的先響，確認後換下一則。
    var currentAlert: OutstandingAlert? {
        outstanding.first
    }
}

// MARK: - 私有

private extension AlertPolicy {
    func hasExpired(pressedAt: Date) -> Bool {
        now().timeIntervalSince(pressedAt) >= Self.timeout
    }
}

// MARK: - Models

/// 一則仍在要求照顧者注意的緊急呼叫。
nonisolated struct OutstandingAlert: Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
    /// 患者按下的時刻。停止時限自此起算。
    let pressedAt: Date
}
