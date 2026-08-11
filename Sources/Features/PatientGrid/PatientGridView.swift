import SwiftUI

/// 患者端主畫面：一整片大格子。
struct PatientGridView: View {
    @Bindable var viewModel: PatientGridViewModel

    var body: some View {
        // 版面由實際可用空間反推，不是由「一列塞得下幾個」決定。
        //
        // 原本用 GridItem(.adaptive(minimum:)) 的後果（2026-08-09 實測）：
        // 它會盡可能塞多欄，iPad mini 直向因此排成 4×1，每格僅約 156pt 寬，
        // 四格擠在螢幕上緣、下方三分之二全空——而 spec 要的是
        // 「The grid fills the screen with large targets」。對眼控患者是雙重
        // 損失：目標小，且全部集中在抬眼最費力的視野上緣。
        VStack(spacing: 0) {
            // 連線指示放在內容區而非導覽列。
            //
            // 技術背景（2026-08-09 實測）：iOS 26 的 toolbar 只給 `Button` 完整
            // 的膠囊樣式，非 Button 的 item 一律套「圖示按鈕」——標題被丟掉，
            // `Label` 與手排的 `HStack` 都蓋不過去。`.principal` 不受此限（實測
            // 可行），所以「放不進導覽列」不是這裡的理由。
            //
            // 真正的理由是**餘光可察覺**：連線狀態改變時沒有聲音也沒有震動，
            // 患者完全靠視覺被動發現。他的視線落在格子上，格子正上方這一列在
            // 餘光範圍內；導覽列正中央則需要主動抬眼確認，而他不會知道什麼時候
            // 該去確認。省下的約 50pt，對每格 500pt 高的格子只是 10% 的差別。
            //
            // 放在格子上方且不隨格子捲動，仍滿足「常駐可見」。
            connectionIndicator
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Self.spacing)
                .padding(.vertical, 12)

            GeometryReader { proxy in
                let layout = Self.layout(itemCount: viewModel.state.items.count, in: proxy.size)

                // ScrollView 只是安全網，不是設計意圖：**眼控患者實質上無法捲動**
                // （Dwell Control 只發出單擊）。格子數在上限內時，上面算出的高度
                // 剛好填滿可用空間，內容不會溢出，也就不會捲動。
                ScrollView {
                    LazyVGrid(columns: layout.columns, spacing: Self.spacing) {
                        ForEach(viewModel.state.items) { item in
                            cell(item)
                                .frame(height: layout.cellHeight)
                        }
                    }
                    .padding(Self.spacing)
                }
            }
        }
        .toolbar {
            // 設定入口需連續兩次點擊，擋住眼控誤觸——患者一旦離開這個畫面
            // 可能沒有能力自己回來。實際操作者是照顧者。
            ToolbarItem(placement: .topBarTrailing) {
                TwoStepConfirmButton(idleTitle: "設定", confirmTitle: "再按一次") {
                    Task { await viewModel.doAction(.openSettings) }
                }
            }
        }
        .task {
            await viewModel.doAction(.onAppear)
        }
        .onDisappear {
            Task { await viewModel.doAction(.onDisappear) }
        }
    }
}

// MARK: - 格子

private extension PatientGridView {
    func cell(_ item: PatientGridViewModel.GridItem) -> some View {
        let state = viewModel.state.callStates[item.id]

        // 單擊即送出。系統的 Dwell Control 只發出單擊，任何超出單擊的手勢
        // 都會讓產品的主要功能對目標使用者失效——所以這裡沒有確認步驟、
        // 沒有長按、沒有滑動。
        return Button {
            Task { await viewModel.doAction(.trigger(item.id)) }
        } label: {
            // 格子沒有圖示——理由見 GridItemModel.title。標題因此是格子唯一的
            // 識別，字級要大到能在掃視中認出；長標題以縮放而非截斷處理，
            // 截掉的字尾可能正是兩個格子的唯一差異（「換尿布」與「換藥」）。
            VStack(spacing: 16) {
                Text(item.title)
                    .font(.system(.largeTitle, weight: .bold))
                    .minimumScaleFactor(0.5)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                stateBadge(state)
            }
            // 先 padding 再撐滿：底色要填滿整格，而格子的高度由外層的版面
            // 計算給定。若在這裡設 minHeight，底色只會包住那個最小高度，
            // 格子會在算好的空間裡縮成一小塊。
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(cellBackground(item), in: .rect(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        // 熱區明確涵蓋整塊圓角矩形，含文字之間的空白。眼控游標落在格子內
        // 任何一點都必須算數——patient 無法像手指那樣精準地「點在字上」。
        .contentShape(.rect(cornerRadius: 20))
        // 眼控游標移入時的視覺回饋。沒有這個，患者凝視數秒的過程中畫面
        // 毫無變化，他無從得知系統是否認得他正在看這一格，只能盲等觸發。
        // 這段等待正是 Dwell Control 最需要安全感的時刻。
        .hoverEffect(.highlight)
        .accessibilityLabel(accessibilityLabel(item, state: state))
        .accessibilityHint("點一下送出呼叫")
    }

    /// 狀態以符號與文字表達，顏色只是輔助——只靠顏色會排除色覺障礙者。
    @ViewBuilder
    func stateBadge(_ state: CallState?) -> some View {
        if let state {
            Label(Self.stateText(state), systemImage: Self.stateSymbol(state))
                .font(.headline)
                .foregroundStyle(Self.stateColor(state))
        } else {
            // 佔位，避免有無狀態時格子高度跳動。
            Text(" ")
                .font(.headline)
        }
    }

    func cellBackground(_ item: PatientGridViewModel.GridItem) -> some ShapeStyle {
        item.isUrgent ? AnyShapeStyle(.red.opacity(0.14)) : AnyShapeStyle(.tint.opacity(0.12))
    }
}

// MARK: - 連線指示

private extension PatientGridView {
    /// 常駐於導覽列：這是患者判斷「系統現在能不能用」的唯一依據，
    /// 不能隨格子捲走。同樣不單靠顏色。
    var connectionIndicator: some View {
        // 刻意不用 Label：放進 toolbar 時系統會把它渲染成純圖示的圓形按鈕，
        // 標題被丟掉，`.labelStyle(.titleAndIcon)` 也蓋不回來（2026-08-09 實測，
        // 兩次都只剩一個符號）。符號要靠學習才知道意思，「未連線」三個字不用，
        // 而這是患者判斷系統能不能用的唯一依據——所以自己排版，不交給系統決定。
        HStack(spacing: 6) {
            Image(
                systemName: viewModel.state.isReachable
                    ? "checkmark.circle.fill"
                    : "exclamationmark.circle.fill"
            )
            Text(viewModel.state.isReachable ? "已連線" : "未連線")
        }
        .font(.headline)
        .foregroundStyle(viewModel.state.isReachable ? Color.green : Color.orange)
        .accessibilityLabel(
            viewModel.state.isReachable
                ? "目前可以送出呼叫"
                : "目前無法送出呼叫，照顧者不在範圍內"
        )
    }
}

// MARK: - 版面計算

// 刻意不是 private：版面算錯的症狀（格子擠在螢幕上緣、下方大片留白）
// 只有在實機上看得見，但演算法本身是純函式，可以用測試釘住。
extension PatientGridView {
    /// spec 2.1：單格 ≥ 150pt、間距 ≥ 24pt。
    ///
    /// 欄數由可用寬度決定而非寫死——寫死會在手機直向產生窄到無法以眼控
    /// 命中的格子，在平板上又浪費空間，而本產品同時支援兩者。
    static let minimumCellSide: CGFloat = 150
    static let spacing: CGFloat = 24

    /// 一組算好的排列：欄數，以及每格該有的高度。
    struct GridLayout {
        let columns: [SwiftUI.GridItem]
        let cellHeight: CGFloat
    }

    /// 從可用空間反推最佳排列。
    ///
    /// 評分用**格子的短邊**而非面積：眼控命中的難度由最窄的那一邊決定，
    /// 一個 600×150 的格子並不比 300×300 好按。
    ///
    /// 格子多到算出的高度低於下限時，取下限並讓內容溢出——那時該捲動，
    /// 但真正的解法是在編輯畫面擋住新增（見 DECISIONS.md）。
    static func layout(itemCount: Int, in size: CGSize) -> GridLayout {
        let fallback = GridLayout(
            columns: [SwiftUI.GridItem(.flexible(), spacing: spacing)],
            cellHeight: minimumCellSide
        )
        guard itemCount > 0, size.width > 0, size.height > 0 else { return fallback }

        let availableWidth = size.width - spacing * 2
        let availableHeight = size.height - spacing * 2

        var bestColumnCount = 0
        var bestShortSide: CGFloat = 0
        var bestCellHeight = minimumCellSide

        for columnCount in 1...itemCount {
            let rowCount = Int((Double(itemCount) / Double(columnCount)).rounded(.up))
            let cellWidth =
                (availableWidth - spacing * CGFloat(columnCount - 1)) / CGFloat(columnCount)
            let cellHeight =
                (availableHeight - spacing * CGFloat(rowCount - 1)) / CGFloat(rowCount)

            // 寬度不足下限的排列直接淘汰：寬度不像高度可以靠捲動補救。
            guard cellWidth >= minimumCellSide else { continue }

            let shortSide = min(cellWidth, cellHeight)
            guard shortSide > bestShortSide else { continue }
            bestColumnCount = columnCount
            bestShortSide = shortSide
            bestCellHeight = max(cellHeight, minimumCellSide)
        }

        guard bestColumnCount > 0 else { return fallback }
        return GridLayout(
            columns: Array(
                repeating: SwiftUI.GridItem(.flexible(), spacing: spacing),
                count: bestColumnCount
            ),
            cellHeight: bestCellHeight
        )
    }
}

// MARK: - 狀態呈現

private extension PatientGridView {
    static func stateText(_ state: CallState) -> String {
        switch state {
        case .waiting: "等待中"
        case .acknowledged: "已確認"
        case .unanswered: "無人回應"
        }
    }

    static func stateSymbol(_ state: CallState) -> String {
        switch state {
        case .waiting: "clock"
        case .acknowledged: "checkmark.circle.fill"
        case .unanswered: "xmark.circle.fill"
        }
    }

    static func stateColor(_ state: CallState) -> Color {
        switch state {
        case .waiting: .secondary
        case .acknowledged: .green
        case .unanswered: .orange
        }
    }

    func accessibilityLabel(_ item: PatientGridViewModel.GridItem, state: CallState?) -> String {
        guard let state else { return item.title }
        return "\(item.title)，\(Self.stateText(state))"
    }
}
