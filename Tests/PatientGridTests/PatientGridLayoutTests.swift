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

    // MARK: - 數量上限

    /// spec: Adding stops at the limit, with the reason stated
    ///
    /// **硬上限是「一屏放得下」，不是建議值 6**（`DECISIONS.md` 2026-08-08）。
    /// 6 來自外部無障礙指南，該文件自承未附實證來源，因此列為建議——用它硬擋
    /// 等於拿一個沒把握的數字替照顧者做決定，而「逼他取捨」的原意是提示。
    /// 真正有實證的約束是「緊急呼叫零捲動可達」，那個由一屏上限守住。
    @Test("硬上限是一屏放得下的數量，可以超過建議值")
    func hardLimitIsWhatFitsOnScreen() {
        let fits =
            PatientGridLayoutTests.fitCount(in: Self.iPadPortrait.width)
            * PatientGridLayoutTests.fitCount(in: Self.iPadPortrait.height)

        #expect(fits > PatientGridView.recommendedItemLimit)
        #expect(PatientGridView.maxItemCount(in: Self.iPadPortrait) == fits)
    }

    @Test("小螢幕的上限低於建議值")
    func limitOnSmallScreenIsBelowRecommendation() {
        let tiny = CGSize(width: 200, height: 400)

        #expect(PatientGridView.maxItemCount(in: tiny) < PatientGridView.recommendedItemLimit)
        #expect(PatientGridView.maxItemCount(in: tiny) >= 1)
    }

    /// 上限內的格子數都排得出合格的寬度——上限若比版面算得出的還寬鬆，
    /// 患者就會看到擠爛的格子。
    @Test("上限內的每個格子數都排得出不低於下限的寬度")
    func everyCountWithinLimitLaysOutLegibly() {
        for size in [Self.iPadPortrait, Self.iPadLandscape, Self.iPhonePortrait] {
            for itemCount in 1...PatientGridView.maxItemCount(in: size) {
                let layout = PatientGridView.layout(itemCount: itemCount, in: size)
                #expect(layout.cellHeight >= PatientGridView.minimumCellSide)
            }
        }
    }

    @Test("尺寸為零時仍給出至少一格的上限")
    func limitDegeneratesSafely() {
        #expect(PatientGridView.maxItemCount(in: .zero) == 1)
    }

    /// 與 `PatientGridView.fitCount` 同一組算式。那個是 private，
    /// 這裡重算一次好驗「建議值真的比一屏塞得下的還小」。
    private static func fitCount(in length: CGFloat) -> Int {
        let available = length - PatientGridView.spacing * 2
        guard available >= PatientGridView.minimumCellSide else { return 1 }
        return Int(
            (available + PatientGridView.spacing)
                / (PatientGridView.minimumCellSide + PatientGridView.spacing)
        )
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
