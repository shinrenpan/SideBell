import Foundation

/// 兩端共用的設定畫面。
///
/// 提供「切換角色」與照顧者端的「支持開發者」入口。前者是唯一非有不可的
/// 功能：沒有它，使用者選錯角色後就再也回不到首頁。
@Observable
final class RoleSettingsViewModel {
    var state: State = .init()

    @ObservationIgnored private let roleStore: RoleStore
    /// 只用來讀「曾經支持過」這個本機旗標。以協定注入，設定頁因此不依賴
    /// 任何金流型別。
    @ObservationIgnored private let sponsorship: any SponsorshipProviding
    @ObservationIgnored var onRoute: (@MainActor (Router) -> Void)?
    /// 回報給呈現這一頁的畫面。目前只有患者端用得到——它需要知道格子變了。
    @ObservationIgnored var onCallback: (@MainActor (Callback) async -> Void)?

    init(roleStore: RoleStore, sponsorship: any SponsorshipProviding = SponsorshipStore()) {
        self.roleStore = roleStore
        self.sponsorship = sponsorship
    }

    func doAction(_ action: Action) async {
        switch action {
        case .onAppear:
            state.role = roleStore.role
            // 每次出現都重讀：使用者可能剛從贊助頁回來。
            state.hasSupported = sponsorship.hasSupported

        case .switchRole:
            onRoute?(.leaveRole)

        case .openSponsorship:
            onRoute?(.sponsorship)

        case .openGridEditing:
            onRoute?(.gridEditing)

        case .gridItemsDidChange:
            await onCallback?(.gridItemsDidChange)
        }
    }
}
