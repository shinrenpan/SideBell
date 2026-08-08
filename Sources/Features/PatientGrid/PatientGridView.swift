import SwiftUI

/// 患者端主畫面：一整片大格子。
struct PatientGridView: View {
    @Bindable var viewModel: PatientGridViewModel

    var body: some View {
        ScrollView {
            LazyVGrid(columns: Self.columns, spacing: Self.spacing) {
                ForEach(viewModel.state.items) { item in
                    cell(item)
                }
            }
            .padding(Self.spacing)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                connectionIndicator
            }
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
            .frame(maxWidth: .infinity, minHeight: Self.minimumCellSide)
            .padding(16)
            .background(cellBackground(item), in: .rect(cornerRadius: 20))
        }
        .buttonStyle(.plain)
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
        Label(
            viewModel.state.isReachable ? "已連線" : "未連線",
            systemImage: viewModel.state.isReachable ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
        )
        .font(.headline)
        .foregroundStyle(viewModel.state.isReachable ? Color.green : Color.orange)
        .accessibilityLabel(
            viewModel.state.isReachable
                ? "目前可以送出呼叫"
                : "目前無法送出呼叫，照顧者不在範圍內"
        )
    }
}

// MARK: - 版面常數

private extension PatientGridView {
    /// spec 2.1：單格 ≥ 150pt、間距 ≥ 24pt。
    ///
    /// 欄數由可用寬度決定而非寫死——寫死會在手機直向產生窄到無法以眼控
    /// 命中的格子，在平板上又浪費空間，而本產品同時支援兩者。
    static let minimumCellSide: CGFloat = 150
    static let spacing: CGFloat = 24

    static var columns: [SwiftUI.GridItem] {
        [SwiftUI.GridItem(.adaptive(minimum: minimumCellSide), spacing: spacing)]
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
