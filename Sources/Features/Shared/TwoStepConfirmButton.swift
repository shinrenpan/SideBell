import SwiftUI

/// 需要連續兩次點擊才會執行的按鈕。
///
/// 用途是擋住患者端的誤觸：眼控（Dwell Control）要在時限內對兩個不同狀態
/// 各精準命中一次，機率極低；而對 VoiceOver 與手指使用者來說，兩次都只是
/// 普通的點擊。
///
/// 刻意不用長按——長按雖然眼控做不出來，但 VoiceOver 使用者也難以穩定
/// 執行。**可達性不等於可用性**：需要重試的操作，對每天使用的人就是障礙。
/// 兩步驟對所有輔助技術一視同仁。
struct TwoStepConfirmButton: View {
    let idleTitle: String
    let confirmTitle: String
    /// 待確認狀態的存續時間。夠短，讓誤觸一次後很快回到原狀；
    /// 夠長，讓使用者從容按下第二次。
    var timeout: Duration = .seconds(3)
    let action: () -> Void

    @State private var isAwaitingConfirmation = false
    @State private var resetTask: Task<Void, Never>?

    var body: some View {
        Button {
            handleTap()
        } label: {
            Text(isAwaitingConfirmation ? confirmTitle : idleTitle)
                .font(.subheadline)
                .foregroundStyle(isAwaitingConfirmation ? Color.orange : Color.secondary)
        }
        .accessibilityLabel(
            isAwaitingConfirmation
                ? String(localized: "\(confirmTitle) to continue")
                : idleTitle
        )
        .accessibilityHint(
            isAwaitingConfirmation
                ? Text("Cancels if you do not tap again within three seconds")
                : Text("Takes two taps to run, so it cannot be triggered by accident")
        )
        .onDisappear {
            resetTask?.cancel()
        }
    }
}

// MARK: - 私有

private extension TwoStepConfirmButton {
    func handleTap() {
        if isAwaitingConfirmation {
            reset()
            action()
        } else {
            enterConfirmationState()
        }
    }

    func enterConfirmationState() {
        isAwaitingConfirmation = true

        // 主動朗讀：視障使用者看不到標題換成確認文字，
        // 不通知的話會以為第一次點擊沒有作用。
        UIAccessibility.post(notification: .announcement, argument: String(localized: "Tap again to continue"))

        resetTask?.cancel()
        resetTask = Task {
            try? await Task.sleep(for: timeout)
            guard !Task.isCancelled else { return }
            isAwaitingConfirmation = false
        }
    }

    func reset() {
        resetTask?.cancel()
        resetTask = nil
        isAwaitingConfirmation = false
    }
}
