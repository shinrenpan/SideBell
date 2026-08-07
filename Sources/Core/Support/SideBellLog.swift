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
    ///
    /// 診斷用的錯誤訊息須標 `privacy: .public`——`os_log` 預設遮蔽動態字串，
    /// 在 Console.app（無 debugger）會顯示為 `<private>`，等於看不到原因。
    /// 這些訊息不含任何患者資料，公開無虞。
    ///
    /// ⚠️ 反過來說，**呼叫標題等患者內容絕不可寫入 log**，無論是否標記
    /// privacy——那是患者的健康相關資訊。
    static let transport = Logger(subsystem: subsystem, category: "transport")
}
