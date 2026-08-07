import Foundation
import Testing

@testable import SideBell

@Suite("首頁角色按鈕的可用性")
struct RoleSelectionStateTests {
    typealias State = RoleSelectionViewModel.State
    typealias BlockReason = RoleSelectionViewModel.BlockReason

    /// 逐列對照 `role-selection` spec 的範例表。
    ///
    /// 「尚未判定」與「已開啟」在本模型中同為 nil——兩者都不阻擋進入。
    /// 尚未判定必須放行：首次啟動時還沒有任何 manager，狀態必然是未判定，
    /// 擋住等於鎖死整個 App。
    nonisolated static let availabilityCases: [(Bool, BluetoothUnavailability?, BlockReason?)] = [
        (false, nil, .disclaimerNotAcknowledged),
        (true, nil, nil),
        (true, .poweredOff, .bluetooth(.poweredOff)),
        (true, .unauthorized, .bluetooth(.unauthorized)),
        (true, .unsupported, .bluetooth(.unsupported)),
    ]

    @Test("可用性對照表", arguments: availabilityCases)
    func blockReason(
        acknowledged: Bool,
        unavailability: BluetoothUnavailability?,
        expected: BlockReason?
    ) {
        var state = State()
        state.isDisclaimerAcknowledged = acknowledged
        state.bluetoothUnavailability = unavailability

        #expect(state.blockReason == expected)
        #expect(state.isRoleSelectionEnabled == (expected == nil))
    }

    /// 未確認免責時，即使藍牙有問題也先報免責——那時連藍牙觀察者
    /// 都還沒建立，談藍牙狀態沒有意義。
    @Test("免責未確認時優先於藍牙原因")
    func disclaimerTakesPrecedence() {
        var state = State()
        state.isDisclaimerAcknowledged = false
        state.bluetoothUnavailability = .poweredOff

        #expect(state.blockReason == .disclaimerNotAcknowledged)
    }

    @Test("預設狀態不可選擇角色")
    func defaultStateIsBlocked() {
        #expect(State().isRoleSelectionEnabled == false)
    }
}
