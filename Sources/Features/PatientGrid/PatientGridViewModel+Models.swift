import Foundation

// MARK: - State

extension PatientGridViewModel {
    struct State: Equatable {
        var items: [GridItem] = []
        var connectionState: ConnectionState = .idle
        /// 每個格子最近一次呼叫的狀態。沒有紀錄代表該格這次還沒被用過。
        var callStates: [UUID: CallState] = [:]

        /// 呼叫目前送不送得出去。
        ///
        /// 語意是「呼叫真的送得到」而不是「藍牙連著」——那盞燈是患者判斷
        /// 系統能不能用的唯一依據。
        var isReachable: Bool { connectionState.isConnected }
    }
}

// MARK: - Action

extension PatientGridViewModel {
    enum Action: Sendable {
        case onAppear
        case onDisappear
        case trigger(UUID)
        case openSettings
        /// 重新讀取格子內容。
        ///
        /// 設定是以 **sheet** 呈現的，這個畫面在它底下**從來沒有 disappear 過**，
        /// 因此 sheet 關閉後 `onAppear` 不會再跑。照顧者在編輯畫面改完項目後，
        /// 要靠這個動作才看得到結果——少了它，他會以為自己的新增沒有生效。
        case reloadItems
    }
}

// MARK: - Router

extension PatientGridViewModel {
    enum Router: Sendable {
        /// 開啟患者端設定。導航歸 C 層執行。
        case openSettings
    }
}

// MARK: - Domain Models

extension PatientGridViewModel {
    /// 畫面用的格子。刻意與資料庫的模型分開：UI 層不該持有資料庫物件，
    /// 那會讓畫面的更新綁在資料庫的生命週期上。
    nonisolated struct GridItem: Identifiable, Equatable, Sendable {
        let id: UUID
        let title: String
        let commandCode: String
        let isUrgent: Bool
    }
}
