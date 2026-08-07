import Foundation

/// 首頁：免責聲明、確認、角色選擇。
///
/// 這個畫面的使用者是**照顧者**，不是患者——患者端裝置的初始設定（選角色、
/// 通過系統配對對話框、關閉自動鎖定）在眼控下做不到，現實中是家屬把裝置
/// 設定好、架在床邊，患者才開始使用。文案與互動都據此撰寫。
@Observable
final class RoleSelectionViewModel {
    var state: State = .init()

    @ObservationIgnored private let disclaimerStore: DisclaimerStore
    @ObservationIgnored private let availability: BluetoothAvailability
    @ObservationIgnored var onRoute: (@MainActor (Router) -> Void)?

    init(disclaimerStore: DisclaimerStore, availability: BluetoothAvailability) {
        self.disclaimerStore = disclaimerStore
        self.availability = availability
    }

    func doAction(_ action: Action) async {
        switch action {
        case .onAppear:
            handleOnAppear()

        case .acknowledgeDisclaimer:
            handleAcknowledge()

        case let .selectRole(role):
            handleSelectRole(role)
        }
    }
}

// MARK: - ViewAction

private extension RoleSelectionViewModel {
    func handleOnAppear() {
        state.isDisclaimerAcknowledged = disclaimerStore.isAcknowledged
        state.bluetoothUnavailability = availability.current

        // 已確認過的使用者不需要再看一次確認控制項，但仍需要藍牙狀態。
        if state.isDisclaimerAcknowledged {
            startObservingBluetooth()
        }
    }

    func handleAcknowledge() {
        disclaimerStore.acknowledge()
        state.isDisclaimerAcknowledged = true

        // 確認之後才開始觀察藍牙——`startObserving()` 會建立 CBCentralManager，
        // 那會觸發系統的權限請求。放在使用者已看過說明的時點，而不是一打開
        // App 就被彈窗攔住；沒有上下文的權限請求只會換來一個「不允許」。
        startObservingBluetooth()
    }

    func handleSelectRole(_ role: AppRole) {
        // 畫面已停用按鈕，這裡是第二道防線：狀態與畫面之間永遠可能有時間差
        // （例如使用者按下的瞬間藍牙剛被關閉）。
        guard state.isRoleSelectionEnabled else { return }
        onRoute?(.enterRole(role))
    }
}

// MARK: - 私有

private extension RoleSelectionViewModel {
    func startObservingBluetooth() {
        availability.onChange = { [weak self] value in
            self?.state.bluetoothUnavailability = value
        }
        availability.startObserving()
        state.bluetoothUnavailability = availability.current
    }
}
