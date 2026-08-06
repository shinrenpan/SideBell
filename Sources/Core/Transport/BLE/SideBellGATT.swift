import CoreBluetooth
import Foundation

/// SideBell 的 GATT 定義：服務、特徵、權限與狀態還原識別碼。
///
/// 全部集中在此。這些常數一旦兩端不一致就會連不上，而症狀看起來像
/// 「藍牙壞了」——集中在一處讓兩端不可能各寫各的。
///
/// 識別碼以 uuidgen 產生一次後固定，不得再變動：改動等同於與所有
/// 已安裝版本斷開相容性。
nonisolated enum SideBellGATT {
    static let serviceUUIDString = "10432E7C-D0B6-4DD5-9B32-AD41DDB580CB"
    /// 患者端送出呼叫的通道（Notify）。
    static let callMessageUUIDString = "6A02851B-19DE-46C7-97C8-0AF05E3E24F9"
    /// 照顧者端回寫確認的通道（Write）。
    static let ackUUIDString = "D6E95B2B-DD5F-43BC-9867-C0F5F6A512EC"
    /// 患者裝置暱稱（Read），供多裝置識別。
    static let deviceInfoUUIDString = "4BAD7815-E2DA-4FE2-9C6E-6DE600C121B4"

    /// 狀態還原識別碼。系統據此在 App 被終止後把 BLE 狀態交還給我們。
    static let centralRestorationIdentifier = "com.shinrenpan.sidebell.central"
    static let peripheralRestorationIdentifier = "com.shinrenpan.sidebell.peripheral"

    // CBUUID 未標記為 Sendable，因此以 computed property 每次建立新實例，
    // 而非用 nonisolated(unsafe) 開逃生口。建立成本可忽略——一次連線只用幾次。
    static var serviceUUID: CBUUID { CBUUID(string: serviceUUIDString) }
    static var callMessageUUID: CBUUID { CBUUID(string: callMessageUUIDString) }
    static var ackUUID: CBUUID { CBUUID(string: ackUUIDString) }
    static var deviceInfoUUID: CBUUID { CBUUID(string: deviceInfoUUIDString) }
}

extension SideBellGATT {
    /// 建立患者端要發佈的服務。
    ///
    /// 三個特徵全部要求加密：首次連線觸發系統配對，bonding 後全程
    /// link-layer 加密，未配對裝置的讀寫在 GATT 層即被拒絕。
    /// 代價只是首次設定多一步，換得呼叫內容不可被鄰近裝置竊聽或偽造確認。
    /// - Parameter nickname: 患者自訂暱稱。未設定時傳 nil——照顧者端會改用
    ///   `CBPeripheral.name`（系統設定裡的裝置名稱，例如「Joe iPad mini 7」），
    ///   那比機型名稱有意義得多，不該被覆蓋。
    static func makeService(nickname: String?) -> CBMutableService {
        let service = CBMutableService(type: serviceUUID, primary: true)

        let callMessage = CBMutableCharacteristic(
            type: callMessageUUID,
            properties: [.notify],
            value: nil,
            permissions: [.readEncryptionRequired]
        )

        let ack = CBMutableCharacteristic(
            type: ackUUID,
            properties: [.write],
            value: nil,
            permissions: [.writeEncryptionRequired]
        )

        // 靜態值：暱稱在本次啟動期間不變，交由系統直接回應讀取請求。
        // 未設定暱稱時寫入空值，照顧者端據此保留 CBPeripheral.name。
        let deviceInfo = CBMutableCharacteristic(
            type: deviceInfoUUID,
            properties: [.read],
            value: Data((nickname ?? "").utf8),
            permissions: [.readEncryptionRequired]
        )

        service.characteristics = [callMessage, ack, deviceInfo]
        return service
    }
}
