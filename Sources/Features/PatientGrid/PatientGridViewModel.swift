import Foundation

/// 患者端主畫面。
///
/// 這是整個產品最核心的畫面：患者唯一能主動使用的介面，也是他在無法言語、
/// 無法移動時唯一的求助管道。
@Observable
final class PatientGridViewModel {
    var state: State = .init()

    @ObservationIgnored private let store: GridItemStore
    @ObservationIgnored private let delivery: CallDelivery
    @ObservationIgnored private let announcer: CallAnnouncer
    @ObservationIgnored private let feedback: CallFeedback
    @ObservationIgnored private let callCenter: CallCenter
    @ObservationIgnored var onRoute: (@MainActor (Router) -> Void)?

    init(
        store: GridItemStore,
        delivery: CallDelivery,
        announcer: CallAnnouncer,
        feedback: CallFeedback,
        callCenter: CallCenter
    ) {
        self.store = store
        self.delivery = delivery
        self.announcer = announcer
        self.feedback = feedback
        self.callCenter = callCenter
    }

    func doAction(_ action: Action) async {
        switch action {
        case .onAppear:
            await handleOnAppear()

        case .onDisappear:
            handleOnDisappear()

        case let .trigger(itemID):
            await handleTrigger(itemID)

        case .openSettings:
            onRoute?(.openSettings)
        }
    }
}

// MARK: - ViewAction

private extension PatientGridViewModel {
    func handleOnAppear() async {
        loadItems()
        syncFromSources()
        feedback.prepare()

        // 狀態變化的來源有二：連線（來自 CallCenter）與呼叫結果（來自
        // CallDelivery）。兩者都在核心層，畫面只是鏡射它們。
        callCenter.onEvent = { [weak self] _ in
            self?.syncFromSources()
        }
        delivery.onOutcome = { [weak self] outcome, _ in
            self?.handleOutcome(outcome)
        }
    }

    func handleOnDisappear() {
        callCenter.onEvent = nil
        delivery.onOutcome = nil
    }

    func handleTrigger(_ itemID: UUID) async {
        guard let item = state.items.first(where: { $0.id == itemID }) else { return }

        // 先播報再送出：患者需要立刻確認自己按到了什麼，而送出可能要等
        // 連線。播報不該被傳輸的延遲拖住。
        announcer.announce(item.title)

        await delivery.send(
            gridItemID: item.id,
            title: item.title,
            commandCode: item.commandCode,
            isUrgent: item.isUrgent
        )
        syncFromSources()
    }
}

// MARK: - 私有

private extension PatientGridViewModel {
    func loadItems() {
        do {
            try store.seedDefaultsIfNeeded()
            state.items = try store.allItems().map {
                GridItem(
                    id: $0.id,
                    title: $0.title,
                    commandCode: $0.commandCode,
                    isUrgent: $0.isUrgent
                )
            }
        } catch {
            // 一片空白的格子對患者而言是「我的求助按鈕全部消失了」，
            // 比當場崩潰更危險——他會以為系統還能用。
            assertionFailure("格子讀取失敗：\(error)")
        }
    }

    func syncFromSources() {
        state.connectionState = callCenter.connectionState
        state.callStates = state.items.reduce(into: [:]) { result, item in
            result[item.id] = delivery.state(ofGridItem: item.id)
        }
    }

    func handleOutcome(_ outcome: CallState) {
        switch outcome {
        case .acknowledged:
            feedback.acknowledged()
        case .unanswered:
            feedback.unanswered()
        case .waiting:
            break
        }
        syncFromSources()
    }
}
