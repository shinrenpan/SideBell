import Foundation

/// 傳輸層 PoC 的 ViewModel。
///
/// ⚠️ 丟棄式：本畫面只為驅動 W1 的實機驗證而存在，
/// 患者端與照顧者端的正式畫面完成後，整個 TransportPoC 目錄應一併刪除。
@Observable
final class TransportPoCViewModel {
    var state: State = .init()

    @ObservationIgnored private let callCenter: CallCenter
    @ObservationIgnored private let roleStore: RoleStore
    /// 角色變更需由 AppDelegate 重建傳輸層綁定，因此交給 C 層處理。
    @ObservationIgnored var onRoleChange: ((AppRole) -> Void)?

    init(callCenter: CallCenter, roleStore: RoleStore) {
        self.callCenter = callCenter
        self.roleStore = roleStore
    }

    func doAction(_ action: Action) async {
        switch action {
        case .onAppear:
            await handleOnAppear()

        case let .selectRole(role):
            handleSelectRole(role)

        case .sendCall:
            await handleSendCall()

        case let .ack(callID):
            await handleAck(callID)

        case .dismissFailure:
            state.failureText = nil
        }
    }
}

// MARK: - ViewAction

private extension TransportPoCViewModel {
    /// 先讀取 CallCenter 的狀態快照，再接上即時事件。
    ///
    /// 快照這一步是關鍵：畫面不存在時 CallCenter 仍在消費事件，
    /// 背景期間收到的呼叫就是靠這裡補回畫面上的。
    func handleOnAppear() async {
        state.role = roleStore.role
        syncFromCallCenter()

        callCenter.onEvent = { [weak self] _ in
            self?.syncFromCallCenter()
        }
    }

    func handleSelectRole(_ role: AppRole) {
        state.role = role
        onRoleChange?(role)
        syncFromCallCenter()
    }

    func handleSendCall() async {
        let message = CallMessage(
            id: UUID(),
            commandCode: FixedCall.commandCode,
            title: FixedCall.title,
            isUrgent: false,
            timestamp: Date()
        )

        do {
            try await callCenter.send(message)
            state.sentCalls.insert(SentCall(id: message.id, sentAt: message.timestamp), at: 0)
            state.failureText = nil
        } catch {
            state.failureText = Self.describe(error)
        }
    }

    func handleAck(_ callID: UUID) async {
        do {
            try await callCenter.ack(callID)
            syncFromCallCenter()
            state.failureText = nil
        } catch {
            state.failureText = Self.describe(error)
        }
    }
}

// MARK: - 私有

private extension TransportPoCViewModel {
    func syncFromCallCenter() {
        state.connectionState = callCenter.connectionState
        state.receivedCalls = callCenter.receivedCalls
        state.ackedCallIDs = callCenter.ackedCallIDs
        state.locallyAckedCallIDs = callCenter.locallyAckedCallIDs
    }

    /// 失敗一律轉成看得見的文字。PoC 階段直接顯示技術原因，
    /// 正式畫面會改成對使用者有意義的說法。
    nonisolated static func describe(_ error: Error) -> String {
        guard let transportError = error as? TransportError else {
            return "未知錯誤：\(error)"
        }
        switch transportError {
        case .notStarted:
            return "傳輸層尚未啟動（請先選擇角色）"
        case .notConnected:
            return "目前沒有連線中的對端"
        case let .roleMismatch(expected, actual):
            return "此操作屬於 \(expected) 角色，目前為 \(actual)"
        case let .encodingFailed(reason):
            return "訊息編碼失敗：\(reason)"
        case .writeRejected:
            return "對端拒絕寫入（可能尚未完成配對）"
        }
    }
}
