import Foundation
import Testing

@testable import SideBell

/// 警報政策是純邏輯：什麼時候該響、要不要重複、什麼時候停。
///
/// 抽出來測的理由是實機驗證的成本：逾時規則要等三分鐘才看得到一次結果，
/// 而「緊急呼叫響一次就停」或「確認後還在響」這類錯誤，只有在真機上
/// 聽著才會發現。政策以注入的時間來源驅動後，這些規則在毫秒內就能驗完。
@Suite("警報政策")
@MainActor
struct AlertPolicyTests {
    private func makeMessage(
        title: String = "喝水",
        isUrgent: Bool = false,
        at timestamp: Date
    ) -> CallMessage {
        CallMessage(
            id: UUID(),
            commandCode: "W",
            title: title,
            isUrgent: isUrgent,
            timestamp: timestamp
        )
    }

    // MARK: - 重複規則

    /// spec: Urgent calls repeat until answered
    @Test("緊急呼叫在無人確認時持續要求警報")
    func urgentKeepsAlerting() {
        let clock = TestClock()
        let policy = AlertPolicy(now: { clock.now })

        let message = makeMessage(title: "不舒服", isUrgent: true, at: clock.now)
        policy.register(message)

        #expect(policy.currentAlert?.id == message.id)

        clock.advance(by: 30)
        policy.checkTimeouts()
        #expect(policy.currentAlert?.id == message.id)
    }

    /// spec: Urgent calls repeat until answered（Scenario: A non-urgent call is not acknowledged）
    @Test("非緊急呼叫只要求響一次")
    func nonUrgentAlertsOnce() {
        let clock = TestClock()
        let policy = AlertPolicy(now: { clock.now })

        let message = makeMessage(at: clock.now)
        policy.register(message)

        // 註冊時仍要響一次——那一次由呼叫端在收到事件時直接播放。
        // 政策只回答「還需不需要繼續響」，對非緊急一律是否。
        #expect(policy.currentAlert == nil)
    }

    /// spec: Urgent calls repeat until answered（Scenario: Several urgent calls are outstanding）
    @Test("多則緊急呼叫未確認時同時只有一個警報")
    func onlyOneAlertAtATime() {
        let clock = TestClock()
        let policy = AlertPolicy(now: { clock.now })

        let first = makeMessage(title: "不舒服", isUrgent: true, at: clock.now)
        clock.advance(by: 10)
        let second = makeMessage(title: "疼痛", isUrgent: true, at: clock.now)
        policy.register(first)
        policy.register(second)

        // 先到的先響，不疊加。
        #expect(policy.currentAlert?.id == first.id)
    }

    // MARK: - 停止條件

    /// spec: The alert stops on three conditions and no others（Scenario: The caregiver acknowledges）
    @Test("確認後該則警報立即停止")
    func acknowledgementStopsAlert() {
        let clock = TestClock()
        let policy = AlertPolicy(now: { clock.now })

        let message = makeMessage(title: "不舒服", isUrgent: true, at: clock.now)
        policy.register(message)
        policy.acknowledge(message.id)

        #expect(policy.currentAlert == nil)
    }

    /// spec: The alert stops on three conditions and no others
    /// （Scenario: Acknowledging one of several outstanding calls）
    @Test("確認其中一則後，另一則仍要求警報")
    func acknowledgingOneLeavesTheOther() {
        let clock = TestClock()
        let policy = AlertPolicy(now: { clock.now })

        let first = makeMessage(title: "不舒服", isUrgent: true, at: clock.now)
        clock.advance(by: 10)
        let second = makeMessage(title: "疼痛", isUrgent: true, at: clock.now)
        policy.register(first)
        policy.register(second)

        policy.acknowledge(first.id)

        #expect(policy.currentAlert?.id == second.id)
    }

    /// spec: The alert stops on three conditions and no others
    /// （Scenario: Three minutes pass without acknowledgement）
    @Test("患者按下滿三分鐘後警報停止")
    func timeoutStopsAlert() {
        let clock = TestClock()
        let policy = AlertPolicy(now: { clock.now })

        let message = makeMessage(title: "不舒服", isUrgent: true, at: clock.now)
        policy.register(message)

        clock.advance(by: AlertPolicy.timeout - 1)
        policy.checkTimeouts()
        #expect(policy.currentAlert?.id == message.id)

        clock.advance(by: 1)
        policy.checkTimeouts()
        #expect(policy.currentAlert == nil)
    }

    /// spec: The alert stops on three conditions and no others
    /// （Example: a queued call）
    ///
    /// 逾時的基準點是**患者按下**，不是照顧者收到。若從收到起算，一則排隊
    /// 兩分鐘才送達的呼叫會讓照顧者比患者晚兩分鐘才停止警報——而患者端
    /// 此時早已顯示「無人回應」。
    @Test("排隊兩分鐘才送達的呼叫，於患者按下後第三分鐘停止")
    func timeoutCountsFromPatientPress() {
        let clock = TestClock()
        let policy = AlertPolicy(now: { clock.now })

        let pressedAt = clock.now
        let message = makeMessage(title: "不舒服", isUrgent: true, at: pressedAt)

        // 呼叫在患者按下後兩分鐘才送達照顧者端。
        clock.advance(by: 120)
        policy.register(message)
        #expect(policy.currentAlert?.id == message.id)

        // 自患者按下起算的第三分鐘——即送達後第一分鐘。
        clock.advance(by: 60)
        policy.checkTimeouts()
        #expect(policy.currentAlert == nil)
    }

    /// spec: The alert stops on three conditions and no others
    /// （Scenario: The caregiver leaves the role）
    @Test("離開照顧者角色後所有警報停止")
    func leavingRoleStopsEverything() {
        let clock = TestClock()
        let policy = AlertPolicy(now: { clock.now })

        policy.register(makeMessage(title: "不舒服", isUrgent: true, at: clock.now))
        policy.register(makeMessage(title: "疼痛", isUrgent: true, at: clock.now))

        policy.reset()

        #expect(policy.currentAlert == nil)
    }

    // MARK: - 邊界

    @Test("重複註冊同一則呼叫不會產生第二筆")
    func registeringTwiceIsIdempotent() {
        let clock = TestClock()
        let policy = AlertPolicy(now: { clock.now })

        let message = makeMessage(title: "不舒服", isUrgent: true, at: clock.now)
        policy.register(message)
        policy.register(message)
        policy.acknowledge(message.id)

        #expect(policy.currentAlert == nil)
    }

    /// 逾時後才到達的確認不該讓警報復活。
    @Test("確認一則已逾時的呼叫不會重新開始警報")
    func acknowledgingTimedOutCallDoesNotRevive() {
        let clock = TestClock()
        let policy = AlertPolicy(now: { clock.now })

        let message = makeMessage(title: "不舒服", isUrgent: true, at: clock.now)
        policy.register(message)
        clock.advance(by: AlertPolicy.timeout)
        policy.checkTimeouts()

        policy.acknowledge(message.id)

        #expect(policy.currentAlert == nil)
    }

    /// 送達時就已經超過三分鐘的呼叫——照顧者端剛從長時間背景醒來時的情境。
    @Test("送達時已逾時的呼叫不會觸發持續警報")
    func alreadyExpiredOnArrival() {
        let clock = TestClock()
        let policy = AlertPolicy(now: { clock.now })

        let pressedAt = clock.now
        clock.advance(by: AlertPolicy.timeout + 60)
        policy.register(makeMessage(title: "不舒服", isUrgent: true, at: pressedAt))

        #expect(policy.currentAlert == nil)
    }
}

// MARK: - 測試用時鐘

/// 可控制的時間來源。逾時測試不能真的等三分鐘。
private final class TestClock {
    private(set) var now = Date(timeIntervalSince1970: 1_754_000_000)

    func advance(by seconds: TimeInterval) {
        now = now.addingTimeInterval(seconds)
    }
}
