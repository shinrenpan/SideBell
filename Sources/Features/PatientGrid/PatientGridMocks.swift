#if DEBUG
import Foundation

extension PatientGridViewModel.GridItem {
    static let mock: Self = .init(
        id: UUID(),
        title: "喝水",
        commandCode: "WATER",
        isUrgent: false
    )

    /// spec 2.1 的四個核心格子，供 Preview 與版面檢視使用。
    static let mocks: [Self] = [
        .init(id: UUID(), title: "喝水", commandCode: "WATER", isUrgent: false),
        .init(id: UUID(), title: "翻身", commandCode: "TURN", isUrgent: false),
        .init(id: UUID(), title: "洗手間", commandCode: "TOILET", isUrgent: false),
        .init(
            id: UUID(),
            title: "不舒服",
            commandCode: "PAIN",
            isUrgent: true
        ),
    ]
}
#endif
