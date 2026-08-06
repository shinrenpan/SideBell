import Foundation

/// 傳輸層的角色。
///
/// 刻意與 App 層的 `AppRole` 分開：App 層有「尚未選擇」這個 UI 狀態，
/// 傳輸層沒有——沒選角色時根本不會啟動傳輸。
nonisolated enum TransportRole: Equatable, Sendable {
    case patient
    case caregiver
}

/// 藍牙不可用的成因。使用者要採取的行動不同，因此必須分開。
nonisolated enum BluetoothUnavailability: Equatable, Sendable {
    /// 藍牙已關閉——使用者自己打開即可。
    case poweredOff
    /// 未授權使用藍牙——需到系統設定授權。
    case unauthorized
    /// 裝置不支援 BLE。
    case unsupported
}

/// 傳輸層對外呈現的連線狀態。
nonisolated enum ConnectionState: Equatable, Sendable {
    /// 尚未啟動。
    case idle
    /// 藍牙不可用。
    ///
    /// 必須與 `searching` 分開：藍牙關閉時顯示「掃描中」等於謊稱系統正在
    /// 運作，照顧者會以為收得到呼叫。畫面宣稱的能力必須等於實際能力。
    case unavailable(BluetoothUnavailability)
    /// 已啟動但尚無對端：患者端廣播中、照顧者端掃描中。
    case searching
    /// 已與至少一個對端連線。
    ///
    /// 帶對端數量而非布林值，是為了讓多患者情境（一照顧者對多患者）
    /// 不需要改動這個型別。1.0 的 UI 只呈現一位患者。
    case connected(peerCount: Int)

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
}

/// 傳輸層推送給核心層的事件。
nonisolated enum TransportEvent: Equatable, Sendable {
    /// 收到一則呼叫。`peerName` 為來源裝置名稱，用於多患者情境下區分來源。
    case callReceived(CallMessage, peerName: String)
    /// 收到對呼叫的確認。
    case ackReceived(callID: UUID)
    /// 連線狀態改變。
    case connectionStateChanged(ConnectionState)
}

/// 傳輸操作的失敗原因。
///
/// 全部以 `throws` 表達：送出失敗若能以布林值忽略，
/// 使用者會看到「已送出」而照顧者什麼也沒收到——本產品最致命的失敗模式。
nonisolated enum TransportError: Error, Equatable, Sendable {
    /// 尚未呼叫 start。
    case notStarted
    /// 已啟動但目前沒有任何連線中的對端。
    case notConnected
    /// 此操作不屬於目前角色（例如照顧者端嘗試送出呼叫）。
    case roleMismatch(expected: TransportRole, actual: TransportRole)
    /// 訊息無法編碼成合法 wire format。
    case encodingFailed(WireFormatError)
    /// 對端拒絕寫入，通常是尚未完成配對。
    case writeRejected
}
