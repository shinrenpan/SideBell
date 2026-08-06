import Foundation
import os

/// 統一的日誌出口。
///
/// W1 期間用於量測 BLE 連線與重連的時序——背景 BLE 的問題無法靠讀程式碼
/// 定位，只能靠實機上的時間戳記。後續里程碑應把 `.info` 降為 `.debug`，
/// 避免正式版持續寫入。
nonisolated enum SideBellLog {
    static let subsystem = "com.shinrenpan.sidebell"

    /// 傳輸層時序。在 Console.app 或 Xcode Console 以此 subsystem 過濾。
    static let transport = Logger(subsystem: subsystem, category: "transport")
}
