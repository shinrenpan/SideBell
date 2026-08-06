import Foundation

/// App 層的角色。
///
/// 比傳輸層的 `TransportRole` 多一個「未選擇」——那是首次啟動時的 UI 狀態，
/// 傳輸層沒有對應概念，未選擇時根本不啟動傳輸。
nonisolated enum AppRole: String, Equatable, Sendable, CaseIterable {
    case unselected
    case patient
    case caregiver

    /// 對應的傳輸角色。未選擇時為 nil，呼叫端據此決定不啟動傳輸。
    var transportRole: TransportRole? {
        switch self {
        case .unselected: nil
        case .patient: .patient
        case .caregiver: .caregiver
        }
    }
}
