import Foundation

// MARK: - State

extension CaregiverCallsViewModel {
    struct State: Equatable {
        var calls: [CallRow] = []
        var connectionState: ConnectionState = .idle
        /// 上一次確認失敗的呼叫與原因。成功或尚未嘗試時為 nil。
        ///
        /// 失敗必須看得見：照顧者以為送出了確認、患者卻還停在「等待中」，
        /// 是本產品最危險的失敗模式——雙方都以為對方知道了。
        var acknowledgeFailure: AcknowledgeFailure?

        /// 呼叫目前送不送得到患者端。
        var isReachable: Bool { connectionState.isConnected }

        var hasCalls: Bool { !calls.isEmpty }
    }
}

// MARK: - Action

extension CaregiverCallsViewModel {
    enum Action: Sendable {
        case onAppear
        case onDisappear
        case acknowledge(UUID)
        case dismissFailure
    }
}

// MARK: - Domain Models

extension CaregiverCallsViewModel {
    /// 清單上的一列。
    nonisolated struct CallRow: Identifiable, Equatable, Sendable {
        let id: UUID
        let title: String
        /// 來源患者。多患者輪班時用來分辨是誰在叫。
        let peerName: String
        /// 患者按下的時刻，不是送達的時刻——照顧者要知道的是「他等了多久」。
        let pressedAt: Date
        let isUrgent: Bool
        /// 本機是否已送出確認。
        let isAcknowledged: Bool
        /// 患者端是否已經放棄等待（自按下起算滿三分鐘）。
        ///
        /// 照顧者端必須看得出這件事。逾時後的確認**送得出去但不會有任何效果**
        /// ——患者端那格早已走完生命週期，顯示的是「無人回應」。若照顧者按下
        /// 確認、看到自己這邊變綠，就會以為患者知道有人要來了，而患者那邊寫著
        /// 沒有人回應。這正是本專案從 W1 起就在消滅的假安全感。
        let isExpired: Bool

        /// 這一列還等得到回應嗎。
        var isActionable: Bool { !isAcknowledged && !isExpired }
    }

    /// 確認送不出去。
    nonisolated struct AcknowledgeFailure: Equatable, Sendable {
        let callID: UUID
        /// 給照顧者看的說法，不是技術原因。
        let message: String
    }
}
