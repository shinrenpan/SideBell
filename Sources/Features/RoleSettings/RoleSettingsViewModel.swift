import Foundation

/// 兩端共用的設定畫面。
///
/// 本 change 只提供「切換角色」——那是唯一非有不可的功能：沒有它，
/// 使用者選錯角色後就再也回不到首頁。警報設定、支持開發者、關於等項目
/// 屬後續里程碑。
@Observable
final class RoleSettingsViewModel {
    var state: State = .init()

    @ObservationIgnored private let roleStore: RoleStore
    @ObservationIgnored var onRoute: (@MainActor (Router) -> Void)?

    init(roleStore: RoleStore) {
        self.roleStore = roleStore
    }

    func doAction(_ action: Action) async {
        switch action {
        case .onAppear:
            state.role = roleStore.role

        case .switchRole:
            onRoute?(.leaveRole)
        }
    }
}
