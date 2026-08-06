import Foundation

/// 一則患者發出的呼叫。
///
/// 這是核心層的值型別，與傳輸方式無關——BLE 只是目前唯一的載體。
/// 本模組預設 MainActor 隔離；呼叫訊息會在 Bluetooth 回呼中建立，
/// 因此整個型別脫離隔離。
nonisolated struct CallMessage: Identifiable, Equatable, Sendable {
    /// 訊息識別碼，同時是照顧者端去重與回寫確認的鍵。
    let id: UUID
    /// 機器可讀的指令代碼，上限 8 位元組 ASCII（例：`WATER`）。
    let commandCode: String
    /// 給人看的標題，上限 100 位元組 UTF-8（例：`喝水`）。
    let title: String
    /// 緊急呼叫。照顧者端據此決定是否重複警報直到確認。
    let isUrgent: Bool
    /// 送出時間。wire format 只保留整秒，次秒精度不保證存活。
    let timestamp: Date
}
