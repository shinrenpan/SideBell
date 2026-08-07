import CoreBluetooth
import Foundation
import Testing

@testable import SideBell

@Suite("藍牙可用性判定")
struct BluetoothAvailabilityTests {
    /// spec `role-selection`: Role selection is blocked only when Bluetooth is
    /// definitively unavailable —— 逐列對照範例表。
    ///
    /// `unknown` 與 `resetting` 必須回 nil（視為可用）。首次啟動時尚未建立
    /// 任何 manager，狀態必然是 unknown；若當成不可用會鎖死整個 App——
    /// 權限對話框要等 manager 建立才會出現，而 manager 要選了角色才建立。
    @Test(
        "CBManagerState 映射",
        arguments: [
            (state: CBManagerState.poweredOn, expected: BluetoothUnavailability?.none),
            (state: .poweredOff, expected: .poweredOff),
            (state: .unauthorized, expected: .unauthorized),
            (state: .unsupported, expected: .unsupported),
            (state: .unknown, expected: nil),
            (state: .resetting, expected: nil),
        ]
    )
    func mapping(state: CBManagerState, expected: BluetoothUnavailability?) {
        #expect(BluetoothAvailability.unavailability(for: state) == expected)
    }

    @Test("尚未開始觀察時視為可用")
    func idleObserverReportsAvailable() {
        let availability = BluetoothAvailability()
        #expect(availability.current == nil)
    }
}
