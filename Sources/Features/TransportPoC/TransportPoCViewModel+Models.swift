import Foundation

// MARK: - State

extension TransportPoCViewModel {
    struct State: Equatable {
        var role: AppRole = .unselected
        var connectionState: ConnectionState = .idle
        var receivedCalls: [CallCenter.ReceivedCall] = []
        /// 患者端視角：已被照顧者確認的呼叫。
        var ackedCallIDs: Set<UUID> = []
        /// 照顧者端視角：本機已送出確認的呼叫。
        var locallyAckedCallIDs: Set<UUID> = []
        /// 患者端視角：本機送出過的呼叫，新的在前。用於觀察每一則各自的確認狀態。
        var sentCalls: [SentCall] = []
        /// 最近一次操作的失敗訊息。送出失敗必須看得見，不得靜默。
        var failureText: String?
    }
}

// MARK: - Action

extension TransportPoCViewModel {
    enum Action: Sendable {
        case onAppear
        case selectRole(AppRole)
        case sendCall
        case ack(UUID)
        case dismissFailure
    }
}

// MARK: - Domain Models

extension TransportPoCViewModel {
    /// PoC 送出的固定呼叫內容。真正的格子清單屬後續里程碑。
    nonisolated enum FixedCall {
        static let commandCode = "WATER"
        static let title = "喝水"
    }

    /// 患者端本機送出的一則呼叫。存在的目的是讓每一則的確認狀態各自可見，
    /// 而不是只有一個總計數字——總計數字無法分辨「第二則沒被確認」與
    /// 「重複確認了第一則」。
    nonisolated struct SentCall: Identifiable, Equatable, Sendable {
        let id: UUID
        let sentAt: Date
    }
}

// MARK: - 顯示用

extension UUID {
    /// 識別碼前 8 碼，供 PoC 畫面辨識個別呼叫。
    var shortLabel: String {
        String(uuidString.prefix(8))
    }
}
