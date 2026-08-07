import CoreBluetooth
import Foundation

/// 患者端：發佈 SideBell 服務、廣播、以通知送出呼叫、接收確認寫入。
///
/// 只在患者角色下建立。照顧者角色不會有這個型別的實例。
final class BLEPeripheralEndpoint: NSObject {
    /// 患者自訂暱稱。nil 表示未設定，照顧者端會改用系統裝置名稱。
    private let nickname: String?
    private let onEvent: (TransportEvent) -> Void

    private var manager: CBPeripheralManager?
    private var callMessageCharacteristic: CBMutableCharacteristic?
    /// 已訂閱呼叫通道的照顧者。多位照顧者輪班時會有多筆——這是 spec 要的天然行為。
    private var subscribedCentrals: Set<UUID> = []
    /// 佇列滿時尚未送出的封包。
    ///
    /// `updateValue` 回傳 false 代表傳輸佇列已滿，若忽略這個回傳值，
    /// 呼叫會靜默消失而患者端顯示「已送出」——本產品最致命的失敗模式。
    private var pendingFrames: [Data] = []
    private var wantsAdvertising = false

    init(nickname: String?, onEvent: @escaping (TransportEvent) -> Void) {
        self.nickname = nickname
        self.onEvent = onEvent
        super.init()
    }
}

// MARK: - 生命週期

extension BLEPeripheralEndpoint {
    func start() {
        SideBellLog.transport.info("peripheral: start 被呼叫")
        wantsAdvertising = true
        guard manager == nil else {
            // manager 已存在（先前 stop 過）：服務在 stop 時被移除，要重新發佈。
            publishServiceIfNeeded()
            startAdvertisingIfReady()
            return
        }
        // 帶還原識別碼：系統因記憶體壓力終止 App 後，可由 BLE 事件在背景復活。
        manager = CBPeripheralManager(
            delegate: self,
            queue: nil,
            options: [
                CBPeripheralManagerOptionRestoreIdentifierKey:
                    SideBellGATT.peripheralRestorationIdentifier
            ]
        )
    }

    /// 停止廣播，但**不釋放 manager**。
    ///
    /// manager 帶著還原識別碼，其狀態由系統保管——那正是 App 被終止後能
    /// 復活的原因。把 manager 設為 nil 只是丟掉我們這邊的物件參考，系統
    /// 那份廣播狀態不會消失，而緊接在後的釋放還會打斷 stopAdvertising。
    /// 實測後果：切換角色後仍持續廣播服務 UUID，對端連上卻找不到服務，
    /// 形成長達十餘秒的連線循環。
    func stop() {
        SideBellLog.transport.info("peripheral: stop 被呼叫")
        wantsAdvertising = false
        manager?.stopAdvertising()
        manager?.removeAllServices()
        callMessageCharacteristic = nil
        subscribedCentrals.removeAll()
        pendingFrames.removeAll()
        emitConnectionState()
    }

    /// 送出一則已編碼的呼叫。
    ///
    /// 入列後立即嘗試送出；佇列滿時保留在 `pendingFrames`，
    /// 由 `peripheralManagerIsReadyToUpdateSubscribers` 續送。
    func send(_ frame: Data) throws {
        guard wantsAdvertising, callMessageCharacteristic != nil else {
            throw TransportError.notStarted
        }
        guard !subscribedCentrals.isEmpty else {
            throw TransportError.notConnected
        }
        pendingFrames.append(frame)
        flushPendingFrames()
    }
}

// MARK: - 私有

private extension BLEPeripheralEndpoint {
    func startAdvertisingIfReady() {
        guard wantsAdvertising, let manager, manager.state == .poweredOn else { return }

        // 刻意不檢查 `manager.isAdvertising`。覆蓋安裝後，系統會把上一版
        // App 的 BLE 狀態交還給新版，其中包含「你正在廣播」——但那個廣播
        // 屬於已被替換掉的實例，實際上不會被任何人掃到。信任該旗標會讓
        // 我們跳過啟動，症狀是「顯示廣播中，卻沒有人連得上」。
        // 先停再開，代價是幾毫秒。
        manager.stopAdvertising()
        SideBellLog.transport.info("peripheral: 開始廣播")
        manager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [SideBellGATT.serviceUUID]
        ])
        emitConnectionState()
    }

    func publishServiceIfNeeded() {
        guard wantsAdvertising, let manager, manager.state == .poweredOn,
              callMessageCharacteristic == nil
        else { return }

        SideBellLog.transport.info("peripheral: 加入服務")
        let service = SideBellGATT.makeService(nickname: nickname)
        callMessageCharacteristic = service.characteristics?
            .compactMap { $0 as? CBMutableCharacteristic }
            .first { $0.uuid == SideBellGATT.callMessageUUID }
        manager.add(service)
    }

    func flushPendingFrames() {
        guard let manager, let characteristic = callMessageCharacteristic else { return }

        while let frame = pendingFrames.first {
            let didSend = manager.updateValue(frame, for: characteristic, onSubscribedCentrals: nil)
            guard didSend else { break }  // 佇列滿，等系統通知可續送
            pendingFrames.removeFirst()
        }
    }

    func emitConnectionState() {
        if let manager, let reason = BluetoothAvailability.unavailability(for: manager.state) {
            onEvent(.connectionStateChanged(.unavailable(reason)))
            return
        }

        let state: ConnectionState
        if subscribedCentrals.isEmpty {
            // manager 不再被釋放，因此以「是否想廣播」判斷，而非 manager 是否存在。
            state = wantsAdvertising ? .searching : .idle
        } else {
            state = .connected(peerCount: subscribedCentrals.count)
        }
        onEvent(.connectionStateChanged(state))
    }
}

// MARK: - CBPeripheralManagerDelegate

// manager 以 queue: nil 建立，所有回呼因此保證在主執行緒——這是
// `@preconcurrency` 的安全不變式。待 CoreBluetooth 的 delegate 協定標注
// @MainActor 後即可移除此標記。
extension BLEPeripheralEndpoint: @preconcurrency CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            SideBellLog.transport.info("peripheral: manager poweredOn")
            publishServiceIfNeeded()
            startAdvertisingIfReady()
        default:
            subscribedCentrals.removeAll()
            emitConnectionState()
        }
    }

    /// 系統終止 App 後由 BLE 事件復活時，先交還既有狀態再呼叫 didUpdateState。
    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        willRestoreState dict: [String: Any]
    ) {
        let services = dict[CBPeripheralManagerRestoredStateServicesKey] as? [CBMutableService]
        callMessageCharacteristic = services?
            .compactMap { $0.characteristics?.compactMap { $0 as? CBMutableCharacteristic } }
            .flatMap { $0 }
            .first { $0.uuid == SideBellGATT.callMessageUUID }

        // 還原後服務已在系統中，不可重複 add；後續 didUpdateState 只需恢復廣播。
        wantsAdvertising = true

        if let subscribed = callMessageCharacteristic?.subscribedCentrals {
            subscribedCentrals = Set(subscribed.map(\.identifier))
        }
        emitConnectionState()
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        SideBellLog.transport.info(
            "peripheral: 服務已加入 error=\(error?.localizedDescription ?? "無", privacy: .public)"
        )
        guard error == nil else {
            callMessageCharacteristic = nil
            return
        }
        startAdvertisingIfReady()
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didSubscribeTo characteristic: CBCharacteristic
    ) {
        guard characteristic.uuid == SideBellGATT.callMessageUUID else { return }
        SideBellLog.transport.info("peripheral: 對端已訂閱")
        subscribedCentrals.insert(central.identifier)
        emitConnectionState()
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didUnsubscribeFrom characteristic: CBCharacteristic
    ) {
        guard characteristic.uuid == SideBellGATT.callMessageUUID else { return }
        subscribedCentrals.remove(central.identifier)
        emitConnectionState()
    }

    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        flushPendingFrames()
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didReceiveWrite requests: [CBATTRequest]
    ) {
        for request in requests where request.characteristic.uuid == SideBellGATT.ackUUID {
            guard let data = request.value else { continue }
            do {
                let callID = try CallMessageCodec.decodeAck(data)
                onEvent(.ackReceived(callID: callID))
            } catch {
                // 畸形確認封包：丟棄，不中斷連線。
                continue
            }
        }
        if let first = requests.first {
            peripheral.respond(to: first, withResult: .success)
        }
    }
}
