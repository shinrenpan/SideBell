import Foundation

// MARK: - State

extension RoleSelectionViewModel {
    struct State: Equatable {
        var isDisclaimerAcknowledged = false
        /// nil 表示可用或尚未判定。尚未判定不阻擋進入——見 `blockReason`。
        var bluetoothUnavailability: BluetoothUnavailability?

        /// 角色按鈕被擋住的原因，nil 表示可以選擇。
        ///
        /// 免責確認優先於藍牙：未確認時連藍牙觀察者都還沒建立，
        /// 此時談藍牙狀態沒有意義。
        var blockReason: BlockReason? {
            guard isDisclaimerAcknowledged else { return .disclaimerNotAcknowledged }
            guard let bluetoothUnavailability else { return nil }
            return .bluetooth(bluetoothUnavailability)
        }

        var isRoleSelectionEnabled: Bool { blockReason == nil }
    }
}

// MARK: - Action

extension RoleSelectionViewModel {
    enum Action: Sendable {
        case onAppear
        case acknowledgeDisclaimer
        case selectRole(AppRole)
    }
}

// MARK: - Router

extension RoleSelectionViewModel {
    enum Router: Sendable {
        case enterRole(AppRole)
    }
}

// MARK: - Domain Models

extension RoleSelectionViewModel {
    /// 角色無法選擇的原因。必須可區分——只說「無法選擇」等於要使用者自己猜。
    nonisolated enum BlockReason: Equatable, Sendable {
        case disclaimerNotAcknowledged
        case bluetooth(BluetoothUnavailability)
    }
}
