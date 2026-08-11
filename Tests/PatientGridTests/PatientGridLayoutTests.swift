import SwiftUI
import Testing

@testable import SideBell

/// 格子版面必須填滿螢幕，而不是「一列塞得下幾個就幾個」。
///
/// 這組測試守的是 2026-08-09 實機發現的缺陷：原本用
/// `GridItem(.adaptive(minimum: 150))`，iPad mini 直向因此排成 4×1，
/// 每格僅約 156pt 寬，四格擠在螢幕上緣、下方三分之二全空——而 spec 要的是
/// `The grid fills the screen with large targets`。對眼控患者是雙重損失：
/// 目標小，且全部集中在抬眼最費力的視野上緣。
@Suite("患者格子版面")
struct PatientGridLayoutTests {
    /// iPad mini 7 的點尺寸，扣掉導覽列的概值。
    private static let iPadPortrait = CGSize(width: 744, height: 1080)
    private static let iPadLandscape = CGSize(width: 1133, height: 690)
    /// iPhone 15 Pro 直向。
    private static let iPhonePortrait = CGSize(width: 393, height: 760)

    @Test("四格在 iPad 直向不排成單列")
    func fourItemsDoNotCollapseIntoOneRowOnPad() {
        let layout = PatientGridView.layout(itemCount: 4, in: Self.iPadPortrait)

        // 4×1 正是缺陷當時的樣子——每格被壓到約 156pt 寬。
        #expect(layout.columns.count == 2)
    }

    @Test("四格在 iPad 橫向不排成單列")
    func fourItemsDoNotCollapseIntoOneRowOnPadLandscape() {
        let layout = PatientGridView.layout(itemCount: 4, in: Self.iPadLandscape)

        #expect(layout.columns.count < 4)
    }

    /// spec: The grid fills the screen with large targets
    @Test("格子高度填滿可用空間，不是停在下限")
    func cellHeightFillsAvailableSpace() {
        let layout = PatientGridView.layout(itemCount: 4, in: Self.iPadPortrait)
        let rowCount = 2
        let expected =
            (Self.iPadPortrait.height - PatientGridView.spacing * 2
                - PatientGridView.spacing * CGFloat(rowCount - 1)) / CGFloat(rowCount)

        #expect(layout.cellHeight > PatientGridView.minimumCellSide * 2)
        #expect(abs(layout.cellHeight - expected) < 1)
    }

    @Test("任何排列的格子寬度都不低於下限")
    func cellWidthNeverDropsBelowMinimum() {
        for size in [Self.iPadPortrait, Self.iPadLandscape, Self.iPhonePortrait] {
            for itemCount in 1...8 {
                let layout = PatientGridView.layout(itemCount: itemCount, in: size)
                let columnCount = CGFloat(layout.columns.count)
                let cellWidth =
                    (size.width - PatientGridView.spacing * 2
                        - PatientGridView.spacing * (columnCount - 1)) / columnCount

                #expect(
                    cellWidth >= PatientGridView.minimumCellSide,
                    "\(itemCount) 格在 \(size) 下算出 \(cellWidth)pt 寬"
                )
            }
        }
    }

    @Test("iPhone 直向的欄數少於 iPad 直向")
    func phoneUsesFewerColumnsThanPad() {
        let phone = PatientGridView.layout(itemCount: 4, in: Self.iPhonePortrait)
        let pad = PatientGridView.layout(itemCount: 6, in: Self.iPadLandscape)

        #expect(phone.columns.count <= pad.columns.count)
    }

    @Test("沒有格子或尺寸為零時不崩潰")
    func degeneratesSafely() {
        #expect(PatientGridView.layout(itemCount: 0, in: Self.iPadPortrait).columns.count == 1)
        #expect(PatientGridView.layout(itemCount: 4, in: .zero).columns.count == 1)
    }
}
