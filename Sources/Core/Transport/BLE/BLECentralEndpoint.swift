import CoreBluetooth
import Foundation

/// 照顧者端：掃描、連線、訂閱呼叫通道、回寫確認。
///
/// 只在照顧者角色下建立。連線以集合管理而非單一對端——把「一位照顧者
/// 顧多位患者」的可能性留在結構裡，1.0 的 UI 只呈現一位。
final class BLECentralEndpoint: NSObject {
    /// 一個已知的患者端。
    private struct Peer {
        let peripheral: CBPeripheral
        var name: String
        var ackCharacteristic: CBCharacteristic?
        /// 是否已成功訂閱呼叫通道。
        ///
        /// 連線狀態以此為準，**不以 link 層的 `.connected` 為準**：BLE 的連線
        /// 與 GATT 服務是兩層，對端釋放服務後 link 可能仍在，此時呼叫其實
        /// 送不到。顯示「已連線」卻收不到呼叫，是比顯示「未連線」更危險的
        /// 假安全感——spec 2.1 那盞綠燈的語意必須是「呼叫真的送得到」。
        var isSubscribed = false
    }

    private let onEvent: (TransportEvent) -> Void

    private var manager: CBCentralManager?
    /// 必須持有 CBPeripheral 的強參考，否則系統會將其釋放並斷線。
    private var peers: [UUID: Peer] = [:]
    /// 呼叫識別碼對應來源患者，確認才知道要寫回哪一端。
    private var callOrigins: [UUID: UUID] = [:]
    /// 連續探索不到服務的次數。
    ///
    /// 「連上但沒有 SideBell 服務」的真實意義是：對端在範圍內、連得上，
    /// 但它不是患者端（被設成照顧者角色了）。這種狀態重試一萬次也不會好，
    /// 要好得有人去把那台裝置改回患者角色。因此連續失敗數次後就停止自動
    /// 重試，避免無止境空轉耗電。
    ///
    /// 注意這與「範圍外斷線」完全不同——後者必須永不放棄地自動重連，
    /// 那是照護產品的安全底線（見 spec 3.1）。
    private var noServiceAttempts: [UUID: Int] = [:]
    private var noServiceCooldownUntil: [UUID: Date] = [:]
    /// 冷卻結束時主動喚醒用。
    ///
    /// 冷卻的檢查點在 `didDiscover`，但那個回呼要掃描**發現**對端才會觸發，
    /// 而掃描設了 allowDuplicates: false——同一台裝置在一次掃描期間只回報
    /// 一次。冷卻期間沒有斷線、就不會重啟掃描、就不會有新的發現事件，
    /// 於是冷卻到期也沒有人來叫醒它。這個排程就是那個叫醒的人。
    private var cooldownWakeTask: Task<Void, Never>?
    private static let maxNoServiceAttempts = 3
    /// 達到上限後的冷卻時間。
    ///
    /// 刻意**不是「永久放棄」**：只要對端回來就必須連上，那是 spec 3.1 的
    /// 底線，不能為了省電而放棄。實測顯示三次嘗試在五秒內就用完，而使用者
    /// 重開一次 App 遠不止五秒——永久放棄等於「患者端重開機後照顧者端
    /// 再也連不上」。冷卻只是把空轉降頻，不是關掉重連。
    private static let noServiceCooldown: TimeInterval = 10

    /// 因「連上但沒有 SideBell 服務」而主動斷開的對端。
    ///
    /// 這些對端**不掛連線意圖**，改為等待它重新廣播。實測顯示：對端正在
    /// 重建服務時，掛著的連線意圖會在一秒多內自行完成，接著又探索不到
    /// 服務、又斷線——形成每 1.2 秒一次的連線循環。對端若長時間不恢復
    /// （例如切換成照顧者角色），這個循環會整夜空轉耗電。
    private var awaitingRediscovery: Set<UUID> = []
    private var wantsScanning = false

    init(onEvent: @escaping (TransportEvent) -> Void) {
        self.onEvent = onEvent
        super.init()
    }
}

// MARK: - 生命週期

extension BLECentralEndpoint {
    func start() {
        wantsScanning = true
        guard manager == nil else {
            startScanningIfReady()
            return
        }
        manager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [
                CBCentralManagerOptionRestoreIdentifierKey:
                    SideBellGATT.centralRestorationIdentifier
            ]
        )
    }

    /// 停止掃描與連線，但**不釋放 manager**。
    ///
    /// 與 peripheral 端同理：manager 帶著還原識別碼，狀態由系統保管，
    /// 釋放物件不會停止系統層的行為，只會讓我們失去控制權。
    func stop() {
        SideBellLog.transport.info("central: stop 被呼叫")
        wantsScanning = false
        manager?.stopScan()
        for peer in peers.values {
            manager?.cancelPeripheralConnection(peer.peripheral)
        }
        peers.removeAll()
        callOrigins.removeAll()
        awaitingRediscovery.removeAll()
        noServiceAttempts.removeAll()
        noServiceCooldownUntil.removeAll()
        cooldownWakeTask?.cancel()
        cooldownWakeTask = nil
        emitConnectionState()
    }

    /// 回寫確認。優先送給已知來源，來源未知時送給所有已連線的患者端。
    ///
    /// 為什麼需要 fallback：`callOrigins` 住在傳輸層，`stop()` 時會清空；
    /// 而畫面上的呼叫清單住在 CallCenter，將來還會持久化到資料庫。兩者
    /// 生命週期不同，因此「清單裡看得到、傳輸層卻不記得它從哪來」是常態
    /// ——照顧者端每次重啟 App 後都會如此。若此時直接拒絕，歷史清單裡的
    /// 呼叫就永遠按不了「已收到」，患者端會一直停在「等待中」。
    ///
    /// 廣播是安全的：患者端收到不認識的呼叫識別碼會靜默丟棄，而識別碼是
    /// 隨機 UUID，不洩漏任何內容。
    func ack(_ callID: UUID) throws {
        guard wantsScanning else { throw TransportError.notStarted }

        let payload = CallMessageCodec.encodeAck(callID)

        if let peerID = callOrigins[callID],
           let peer = peers[peerID],
           let characteristic = peer.ackCharacteristic,
           peer.peripheral.state == .connected,
           peer.isSubscribed {
            write(payload, to: peer, characteristic: characteristic)
            return
        }

        let targets = peers.values.filter {
            $0.isSubscribed && $0.ackCharacteristic != nil && $0.peripheral.state == .connected
        }
        guard !targets.isEmpty else { throw TransportError.notConnected }

        SideBellLog.transport.info("central: 確認的來源未知，廣播給 \(targets.count) 個已連線對端")
        for peer in targets {
            guard let characteristic = peer.ackCharacteristic else { continue }
            write(payload, to: peer, characteristic: characteristic)
        }
    }
}

// MARK: - 私有

private extension BLECentralEndpoint {
    /// 用 withResponse：寫入被拒（未配對）時會有 error 回呼，
    /// 不會像 withoutResponse 那樣靜默消失。
    private func write(_ payload: Data, to peer: Peer, characteristic: CBCharacteristic) {
        peer.peripheral.writeValue(payload, for: characteristic, type: .withResponse)
    }

    func startScanningIfReady() {
        // 同 peripheral 端：不信任 `manager.isScanning`，覆蓋安裝後它可能
        // 反映的是已被替換掉的舊實例。
        guard wantsScanning, let manager, manager.state == .poweredOn else { return }
        manager.stopScan()

        // 背景掃描必須指定服務識別碼（平台規則，非最佳實務）。
        // 前景走同一條路徑，避免出現「前景能連、背景連不上」的分歧。
        //
        // 訂閱成功後會停止掃描（見 stopScanningIfConnected），斷線時再重啟。
        SideBellLog.transport.info("central: 開始掃描")
        manager.scanForPeripherals(
            withServices: [SideBellGATT.serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        emitConnectionState()
    }

    /// 已有訂閱中的對端就停止掃描。
    ///
    /// spec 3.1 要求「維持長連線，不反覆掃描」。連上之後仍持續掃描，
    /// 唯一的用途是發現第二台患者裝置，而多患者介面在 1.0 不做——
    /// 等於讓照顧者的手機整天為一個用不到的功能耗電。
    ///
    /// 1.1 若要支援多患者，改的是這裡：把條件改為「已達目標患者數」，
    /// 而不是「已有任一連線」。
    func stopScanningIfConnected() {
        guard let manager, manager.isScanning else { return }
        guard peers.values.contains(where: { $0.isSubscribed }) else { return }
        SideBellLog.transport.info("central: 已連線，停止掃描")
        manager.stopScan()
    }

    /// 冷卻結束後主動重啟掃描，讓 `didDiscover` 有機會再次觸發。
    func scheduleCooldownWake() {
        cooldownWakeTask?.cancel()
        cooldownWakeTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Self.noServiceCooldown))
            guard !Task.isCancelled, let self else { return }
            SideBellLog.transport.info("central: 冷卻時間到，重啟掃描")
            restartScanning()
        }
    }

    /// 重啟掃描以重置 `allowDuplicates: false` 造成的去重狀態。
    /// 只在斷線時呼叫，不做週期性重啟——那會白白耗電。
    func restartScanning() {
        guard wantsScanning, let manager, manager.state == .poweredOn else { return }
        SideBellLog.transport.info("central: 重啟掃描")
        manager.stopScan()
        manager.scanForPeripherals(
            withServices: [SideBellGATT.serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }

    func emitConnectionState() {
        if let manager, let reason = BluetoothAvailability.unavailability(for: manager.state) {
            onEvent(.connectionStateChanged(.unavailable(reason)))
            return
        }

        let connectedCount = peers.values.count { $0.isSubscribed }
        let state: ConnectionState
        if connectedCount > 0 {
            state = .connected(peerCount: connectedCount)
        } else {
            // manager 不再被釋放，因此以「是否想掃描」判斷，而非 manager 是否存在。
            state = wantsScanning ? .searching : .idle
        }
        onEvent(.connectionStateChanged(state))
    }

    func handleReceivedCall(_ data: Data, from peripheral: CBPeripheral) {
        do {
            let message = try CallMessageCodec.decode(data)
            let name = peers[peripheral.identifier]?.name ?? Self.fallbackPeerName
            callOrigins[message.id] = peripheral.identifier
            onEvent(.callReceived(message, peerName: name))
        } catch {
            // 畸形封包：丟棄並保留連線。不得把部分解析結果當成有效呼叫。
        }
    }

    static let fallbackPeerName = "未命名裝置"
}

// MARK: - CBCentralManagerDelegate

// manager 以 queue: nil 建立，所有回呼因此保證在主執行緒——這是
// `@preconcurrency` 的安全不變式。待 CoreBluetooth 的 delegate 協定標注
// @MainActor 後即可移除此標記。
extension BLECentralEndpoint: @preconcurrency CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            SideBellLog.transport.info("central: manager poweredOn")
            startScanningIfReady()
        default:
            emitConnectionState()
        }
    }

    /// 系統終止 App 後由 BLE 事件復活時，先交還既有連線再呼叫 didUpdateState。
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        let restored = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] ?? []
        SideBellLog.transport.info("central: 狀態還原，交還 \(restored.count) 個對端")

        for peripheral in restored {
            peripheral.delegate = self
            peers[peripheral.identifier] = Peer(
                peripheral: peripheral,
                name: peripheral.name ?? Self.fallbackPeerName
            )

            if peripheral.state == .connected {
                // 還原的連線不保證帶著已探索的特徵，一律重新探索。
                // 探索完成後會在 didDiscoverCharacteristicsFor 恢復 isSubscribed
                // 與 ackCharacteristic——兩者都是還原後能正常運作的必要條件。
                SideBellLog.transport.info("central: 還原的對端仍連線中，重新探索服務")
                peripheral.discoverServices([SideBellGATT.serviceUUID])
            } else {
                central.connect(peripheral)
            }
        }
        wantsScanning = true
        emitConnectionState()
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        if peers[peripheral.identifier] == nil {
            peripheral.delegate = self
            // 廣播中的 local name 在患者端進背景後不會出現，
            // 真正的名稱靠連線後讀取 Device Info 特徵取得。
            peers[peripheral.identifier] = Peer(
                peripheral: peripheral,
                name: peripheral.name ?? Self.fallbackPeerName
            )
        }

        // 已知但未連線的對端重新出現在廣播中，代表它回來了——立即主動連線。
        //
        // 不能只依賴系統掛住的連線意圖：那個機制對背景復活很好用，但它的
        // 掃描週期由系統決定，實測恢復時間達 35–40 秒。前景明明已經看到對方，
        // 沒有理由乾等。connect 是幂等的，重複呼叫安全。
        // 掃描期間每次回報都會進來，量大且多為重複，用 debug 級別避免淹沒關鍵事件。
        SideBellLog.transport.debug("central: 發現對端 state=\(peripheral.state.rawValue)")

        // 已達上限：對端仍在廣播，但連上後拿不到服務。進入冷卻以免空轉，
        // 冷卻結束後重新給機會——對端可能只是重開機或換回患者角色。
        if let until = noServiceCooldownUntil[peripheral.identifier] {
            guard Date() >= until else { return }
            SideBellLog.transport.info("central: 冷卻結束，重新嘗試連線")
            noServiceCooldownUntil.removeValue(forKey: peripheral.identifier)
            noServiceAttempts.removeValue(forKey: peripheral.identifier)
        }

        if awaitingRediscovery.remove(peripheral.identifier) != nil {
            SideBellLog.transport.info("central: 對端已重新廣播")
        }
        if peripheral.state == .disconnected {
            SideBellLog.transport.info("central: 主動發出連線請求")
            central.connect(peripheral)
        } else if peripheral.state == .connected,
                  peers[peripheral.identifier]?.ackCharacteristic == nil {
            // App 被終止後重啟：系統層的 BLE 連線仍活著（帶還原識別碼的效果），
            // 所以掃描立刻看到一個已連線的對端。但我們這側是全新的狀態機——
            // 沒有特徵參考、沒有訂閱旗標。
            //
            // 不補這一步的後果：呼叫照樣收得到（系統層訂閱未失效，delegate 一設
            // 上 notify 就進來），但畫面顯示「掃描中」、確認寫不出去，患者端
            // 永遠停在「等待中」。
            //
            // 這條路徑不依賴 willRestoreState——實測顯示它不一定會被呼叫。
            SideBellLog.transport.info("central: 對端已在連線中但缺少特徵，補做服務探索")
            peripheral.discoverServices([SideBellGATT.serviceUUID])
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        SideBellLog.transport.info("central: 已連線，開始探索服務")
        peripheral.discoverServices([SideBellGATT.serviceUUID])
        emitConnectionState()
    }

    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        // 連線請求沒有逾時，系統會保留這個意圖直到成功。
        central.connect(peripheral)
        emitConnectionState()
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        SideBellLog.transport.info(
            "central: 斷線 error=\(error?.localizedDescription ?? "無", privacy: .public)"
        )
        peers[peripheral.identifier]?.ackCharacteristic = nil
        peers[peripheral.identifier]?.isSubscribed = false

        if error != nil {
            // 對端自己消失了（裝置關機、App 被終止、走出範圍）——iOS 會在
            // 這種情況帶錯誤，我們主動斷線時則不會。
            //
            // 這與「連上卻拿不到服務」是完全不同的失敗：後者重試再多次也
            // 不會好（對端根本不是患者端角色），前者只要對端回來就該重連。
            // 不清掉計數的話，患者端裝置重開機後照顧者端會因為舊帳而拒絕
            // 再連，症狀是「除非照顧者自己重開 App，否則永遠連不上」——
            // 而照顧者不會知道要這麼做。
            if noServiceAttempts.removeValue(forKey: peripheral.identifier) != nil {
                SideBellLog.transport.info("central: 對端消失，清除無服務重試計數")
            }
            noServiceCooldownUntil.removeValue(forKey: peripheral.identifier)
            awaitingRediscovery.remove(peripheral.identifier)
        }
        if awaitingRediscovery.contains(peripheral.identifier) {
            // 對端正在重建服務。掛連線意圖只會連回同一個沒有服務的狀態，
            // 等它重新廣播再說。
            SideBellLog.transport.info("central: 等待對端重新廣播，不掛連線意圖")
        } else {
            // 立即重新發出連線請求，不自行輪詢：iOS 的 connect 沒有逾時，
            // 系統會掛住這個意圖，裝置回到範圍內時自動完成。這是背景復活的依靠。
            central.connect(peripheral)
        }
        // 同時重啟掃描以重置去重狀態。掃描選項為 allowDuplicates: false，
        // 同一對端在單次掃描期間只回報一次；不重啟的話，對端重新廣播時
        // 不會產生發現回呼，前景就只能陪著系統的慢速週期一起等。
        restartScanning()
        emitConnectionState()
    }
}

// MARK: - CBPeripheralDelegate

extension BLECentralEndpoint: @preconcurrency CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let services = peripheral.services ?? []
        let sideBellServices = services.filter { $0.uuid == SideBellGATT.serviceUUID }

        guard error == nil, !sideBellServices.isEmpty else {
            // 連上了，但對端沒有 SideBell 服務——通常是對端正在重建自己的
            // peripheral manager（例如切換角色）。
            //
            // 這裡絕不能靜默返回。實測顯示：留著這條沒有服務的連線，會讓
            // central 誤以為自己「已連線」，因而忽略對端稍後恢復的廣播，
            // 一路卡到對端自行超時斷開為止——實測 66 秒。主動斷線，讓
            // 既有的重連路徑接手，實測可將恢復時間壓到 1 秒內。
            //
            // 不會造成連線風暴：對端不廣播就不會被重新連上。
            let attempts = (noServiceAttempts[peripheral.identifier] ?? 0) + 1
            noServiceAttempts[peripheral.identifier] = attempts
            if attempts >= Self.maxNoServiceAttempts {
                noServiceCooldownUntil[peripheral.identifier] =
                    Date().addingTimeInterval(Self.noServiceCooldown)
                scheduleCooldownWake()
                SideBellLog.transport.info(
                    "central: 對端連續 \(attempts) 次無 SideBell 服務，冷卻 \(Self.noServiceCooldown) 秒後再試"
                )
            } else {
                SideBellLog.transport.info(
                    "central: 對端無 SideBell 服務（第 \(attempts) 次），斷線並等待其重新廣播"
                )
            }
            awaitingRediscovery.insert(peripheral.identifier)
            manager?.cancelPeripheralConnection(peripheral)
            return
        }

        for service in sideBellServices {
            peripheral.discoverCharacteristics(
                [SideBellGATT.callMessageUUID, SideBellGATT.ackUUID, SideBellGATT.deviceInfoUUID],
                for: service
            )
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        guard error == nil else { return }

        for characteristic in service.characteristics ?? [] {
            switch characteristic.uuid {
            case SideBellGATT.callMessageUUID:
                if characteristic.isNotifying {
                    // 狀態還原情境：訂閱在 App 被終止前就存在，系統交還時它
                    // 仍是 notifying，因此 didUpdateNotificationStateFor 不會
                    // 再次觸發。不在這裡補上，isSubscribed 會永遠停在 false，
                    // 症狀是「收得到呼叫，但顯示未連線、且確認寫不出去」——
                    // 患者端會永遠停在「等待中」，失去唯一的回饋。
                    SideBellLog.transport.info("central: 還原既有訂閱")
                    peers[peripheral.identifier]?.isSubscribed = true
                    noServiceAttempts.removeValue(forKey: peripheral.identifier)
                } else {
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            case SideBellGATT.ackUUID:
                peers[peripheral.identifier]?.ackCharacteristic = characteristic
            case SideBellGATT.deviceInfoUUID:
                peripheral.readValue(for: characteristic)
            default:
                continue
            }
        }
        emitConnectionState()
    }

    /// 訂閱狀態改變。連線狀態的唯一真相來源。
    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard characteristic.uuid == SideBellGATT.callMessageUUID else { return }
        SideBellLog.transport.info("central: 訂閱狀態 notifying=\(characteristic.isNotifying)")
        peers[peripheral.identifier]?.isSubscribed = (error == nil && characteristic.isNotifying)
        if error == nil, characteristic.isNotifying {
            // 訂閱成功，重置計數與冷卻：下次中斷從頭算起。
            noServiceAttempts.removeValue(forKey: peripheral.identifier)
            noServiceCooldownUntil.removeValue(forKey: peripheral.identifier)
        }
        stopScanningIfConnected()
        emitConnectionState()
    }

    /// 對端的服務被移除或變更（例如患者端切換角色、釋放了 peripheral manager）。
    ///
    /// 沒有這個回呼，link 仍在但服務已消失時，我們會繼續顯示「已連線」。
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        guard invalidatedServices.contains(where: { $0.uuid == SideBellGATT.serviceUUID }) else {
            return
        }

        SideBellLog.transport.info("central: 對端服務失效")
        peers[peripheral.identifier]?.isSubscribed = false
        peers[peripheral.identifier]?.ackCharacteristic = nil
        emitConnectionState()

        // 斷線而非原地重新探索。
        //
        // 對端釋放服務時通常正在重建自己的 peripheral manager，此刻探索必然
        // 撲空，而撲空之後只能被動等系統再送一次服務變更通知——那段等待
        // 不受我們控制，實測上明顯拖慢恢復。斷線會走既有的重連路徑：
        // didDisconnect 立即重發連線請求，系統掛住意圖，對端一恢復廣播就自動接上。
        manager?.cancelPeripheralConnection(peripheral)
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard error == nil, let data = characteristic.value else { return }

        switch characteristic.uuid {
        case SideBellGATT.callMessageUUID:
            handleReceivedCall(data, from: peripheral)
        case SideBellGATT.deviceInfoUUID:
            // 只有患者確實設定過暱稱才覆蓋。空值代表未設定，此時
            // CBPeripheral.name（系統設定的裝置名稱，如「Joe iPad mini 7」）
            // 比任何 fallback 都有意義，不該被蓋掉。
            if let nickname = String(data: data, encoding: .utf8), !nickname.isEmpty {
                peers[peripheral.identifier]?.name = nickname
            }
        default:
            break
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        // 寫入失敗通常代表尚未完成配對。保留連線，由使用者完成系統配對後重試。
        guard error != nil, characteristic.uuid == SideBellGATT.ackUUID else { return }
        emitConnectionState()
    }
}
