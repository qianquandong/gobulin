import XCTest
@testable import GoblinForgeCore

/// M0-01 / QA T-01：三区域输入、预算、上限、最小间隔、Undo/Reset/Cancel、元素锁定、预览与对比行。
final class ForgeSessionTests: XCTestCase {
    private let learning = ForgeConfig(md: 20, budget: 10, availableRunes: [.ember])

    private func strike(_ session: inout ForgeSession, _ zones: [ForgeZone], start: Double = 0) {
        for (i, zone) in zones.enumerated() {
            XCTAssertEqual(session.strike(zone, at: start + Double(i) * 0.2).isAccepted, true, "\(zone)")
        }
    }

    func testBudgetIsConsumedOnlyByAcceptedStrikes() {
        var s = ForgeSession(config: learning)
        strike(&s, Array(repeating: .hilt, count: 6))
        XCTAssertEqual(s.strike(.hilt, at: 10), .zoneMax(.hilt))
        XCTAssertEqual(s.remaining, 4)
        strike(&s, [.blade, .blade, .blade, .blade], start: 20)
        XCTAssertEqual(s.remaining, 0)
        XCTAssertEqual(s.phase, .ready)
        XCTAssertEqual(s.strike(.blade, at: 30), .noBudget)
    }

    func testStrikesFasterThanMinimumIntervalAreDropped() {
        var s = ForgeSession(config: learning)
        XCTAssertTrue(s.strike(.blade, at: 1.00).isAccepted)
        XCTAssertEqual(s.strike(.blade, at: 1.10), .tooFast)
        XCTAssertTrue(s.strike(.blade, at: 1.15).isAccepted)
        XCTAssertEqual(s.blade, 2)
    }

    func testBladeThresholdsReportFormChange() {
        var s = ForgeSession(config: ForgeConfig(md: 20, budget: 12))
        strike(&s, [.blade, .blade, .blade])
        XCTAssertEqual(s.nextBladeChangesForm, .broad)
        XCTAssertEqual(s.strike(.blade, at: 5), .accepted(.blade, newForm: .broad))
        strike(&s, [.blade, .blade, .blade], start: 6)
        XCTAssertEqual(s.nextBladeChangesForm, .great)
        XCTAssertEqual(s.strike(.blade, at: 9), .accepted(.blade, newForm: .great))
        XCTAssertNil(s.nextBladeChangesForm)
        // Undo 跨回阈值：预览回到 Broad
        s.undo()
        XCTAssertEqual(s.preview.form, .broad)
    }

    func testUndoResetAndCancelLeaveNoResidue() {
        var s = ForgeSession(config: learning)
        XCTAssertTrue(s.selectRune(.ember))
        strike(&s, [.blade, .rune, .hilt])
        XCTAssertEqual(s.temper, 3)
        XCTAssertEqual(s.undo(), .hilt)
        XCTAssertEqual(s.temper, 2, "undo returns the temper it brought")
        XCTAssertEqual(s.remaining, 8)
        s.reset()
        XCTAssertEqual(s, { var fresh = ForgeSession(config: learning); fresh.selectRune(.ember); return fresh }())
        // Cancel = 丢弃会话：新会话与从未锻造相同
        XCTAssertEqual(ForgeSession(config: learning).preview, Weapon(md: 20, blade: 0, hilt: 0))
    }

    func testRuneMustBePickedAndLocksAfterFirstStrike() {
        var s = ForgeSession(config: learning)
        XCTAssertEqual(s.strike(.rune, at: 0), .runeNotSelected)
        XCTAssertEqual(s.remaining, 10)
        XCTAssertFalse(s.selectRune(.frost), "Frost is not available in M0")
        XCTAssertTrue(s.selectRune(.ember))
        strike(&s, [.rune], start: 1)
        XCTAssertFalse(s.selectRune(nil), "element locks after the first strike")
        s.reset()
        XCTAssertTrue(s.selectRune(nil))
    }

    func testSameAllocationGivesSameWeaponRegardlessOfOrder() {
        var a = ForgeSession(config: learning)
        var b = ForgeSession(config: learning)
        a.selectRune(.ember); b.selectRune(.ember)
        strike(&a, [.blade, .blade, .blade, .hilt, .hilt, .hilt, .hilt, .rune, .rune, .rune])
        strike(&b, [.rune, .hilt, .blade, .rune, .hilt, .blade, .hilt, .rune, .blade, .hilt])
        XCTAssertEqual(a.deliver(), b.deliver())
        XCTAssertEqual(a.deliver(), Weapon(md: 20, blade: 3, hilt: 4, runePoints: 3, rune: .ember, temper: 3))
    }

    func testFinishReportsUnusedStrikes() {
        var s = ForgeSession(config: learning)
        XCTAssertEqual(s.finish(), 0, "nothing to finish before the first strike")
        XCTAssertNil(s.deliver())
        strike(&s, [.blade, .blade, .blade, .blade])
        XCTAssertEqual(s.finish(), 6)
        XCTAssertEqual(s.phase, .ready)
        XCTAssertEqual(s.deliver()?.form, .broad)
    }

    func testComparisonListsOnlyChangedRowsInPRDOrder() {
        let now = Weapon(md: 20, blade: 3, hilt: 6, temper: 3)
        let new = Weapon(md: 20, blade: 4, hilt: 6, temper: 3)
        let rows = ComparisonRow.rows(now: now, new: new)
        XCTAssertEqual(rows.first, .form(from: .needle, to: .broad))
        XCTAssertEqual(rows[1], .hits(from: 1, to: 6))
        XCTAssertEqual(rows[1].isImprovement, true)
        XCTAssertTrue(rows.contains(.swing(from: 0.58, to: 0.78)))
        XCTAssertEqual(ComparisonRow.rows(now: now, new: now), [])
    }
}

extension StrikeResult {
    var isAccepted: Bool {
        if case .accepted = self { return true }
        return false
    }
}
