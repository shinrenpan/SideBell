import CoreBluetooth
import Foundation

/// 不依賴角色的藍牙可用性觀察者。
///
/// 存在的理由：首頁必須在使用者尚未選擇角色時就知道藍牙能不能用，
/// 而傳輸層的兩個端點都要選了角色才會建立。
///
/// ⚠️ `startObserving()` 會建立 `CBCentralManager`，因此**會觸發系統的藍牙
/// 權限請求**。呼叫時機必須在使用者已看過免責聲明與說明之後——沒有上下文
/// 的權限彈窗只會換來一個「不允許」。
final class BluetoothAvailability: NSObject {
    /// 目前的不可用原因。nil 表示可用或尚未判定。
    private(set) var current: BluetoothUnavailability?

    /// 狀態變化時通知。首頁據此即時更新角色按鈕。
    var onChange: ((BluetoothUnavailability?) -> Void)?

    private var manager: CBCentralManager?
}

// MARK: - 觀察

extension BluetoothAvailability {
    func startObserving() {
        guard manager == nil else { return }

        // 不帶還原識別碼：這只是狀態觀察者，不參與連線，也不該在背景被復活。
        // 關閉系統的電源警示，改由首頁以自己的文案說明——我們的訊息帶得動
        // 上下文（「照顧者收不到呼叫」），系統的泛用彈窗帶不動。
        manager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [CBCentralManagerOptionShowPowerAlertKey: false]
        )
    }

    func stopObserving() {
        manager = nil
        current = nil
    }
}

// MARK: - 映射

extension BluetoothAvailability {
    /// 由 `CBManagerState` 映射出使用者需要知道的不可用原因。
    ///
    /// `unknown` 與 `resetting` 回 nil：兩者都是暫態，而首次啟動時尚未建立
    /// 任何 manager，狀態必然是 unknown。把它當成不可用會鎖死 App。
    nonisolated static func unavailability(for state: CBManagerState) -> BluetoothUnavailability? {
        switch state {
        case .poweredOn: nil
        case .poweredOff: .poweredOff
        case .unauthorized: .unauthorized
        case .unsupported: .unsupported
        case .unknown, .resetting: nil
        @unknown default: nil
        }
    }
}

// MARK: - CBCentralManagerDelegate

// manager 以 queue: nil 建立，回呼保證在主執行緒——`@preconcurrency` 的
// 安全不變式，與兩個 BLE 端點相同。
extension BluetoothAvailability: @preconcurrency CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let value = Self.unavailability(for: central.state)
        SideBellLog.transport.info("availability: 藍牙狀態 \(central.state.rawValue)")
        current = value
        onChange?(value)
    }
}
