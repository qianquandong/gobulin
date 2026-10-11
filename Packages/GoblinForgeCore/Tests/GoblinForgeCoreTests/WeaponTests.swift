import XCTest
@testable import GoblinForgeCore

/// M0-01 / QA T-01：武器公式与 balance_sim.weapon() 逐项一致；PRD 4.9 算例与形态边界。
final class WeaponTests: XCTestCase {
    private func weapon(from row: [String: Any]) -> Weapon {
        Weapon(md: row.int("md")!, blade: row.int("bp")!, hilt: row.int("hp")!, runePoints: row.int("rp")!,
               rune: row.string("rune").flatMap(Rune.init(rawValue:)), temper: row.int("temper")!)
    }

    private func assertMatches(_ row: [String: Any], file: StaticString = #filePath, line: UInt = #line) {
        let w = weapon(from: row)
        let label = row.string("label")!
        XCTAssertEqual(w.form.rawValue, row.string("form"), label, file: file, line: line)
        XCTAssertEqual(w.hitDamage, row.int("H"), label, file: file, line: line)
        // Python 以最短 repr 输出浮点，解析回来是同一个 double：要求逐位相等
        XCTAssertEqual(w.interval, row.double("I"), label, file: file, line: line)
        XCTAssertEqual(w.windup, row.double("W"), label, file: file, line: line)
        XCTAssertEqual(w.runeEvery, row.int("every"), label, file: file, line: line)
        if w.rune == .ember { XCTAssertEqual(w.burnPerTick, row.int("burn"), label, file: file, line: line) }
        XCTAssertEqual(w.label, label, file: file, line: line)
    }

    func testEveryReferenceWeaponMatchesSimulator() {
        let rows = Reference.rows("weapons")
        XCTAssertGreaterThan(rows.count, 3000)
        for row in rows { assertMatches(row) }
    }

    func testWorkedExamplesE1toE7() {
        let examples = Reference.rows("examples")
        XCTAssertEqual(examples.count, 7)
        for row in examples { assertMatches(row) }
        // 与 PRD 4.9 文字中的数值对照（不只依赖生成的夹具）
        let e1 = Weapon(md: 10, blade: 2, hilt: 2, temper: 1)
        XCTAssertEqual([e1.hitDamage], [12]); XCTAssertEqual(e1.interval, 0.86); XCTAssertEqual(e1.windup, 0.30)
        let e2 = Weapon(md: 10, blade: 4, hilt: 3, temper: 2)
        XCTAssertEqual(e2.form, .broad); XCTAssertEqual(e2.hitDamage, 13); XCTAssertEqual(e2.interval, 1.07)
        let e3 = Weapon(md: 12, blade: 3, hilt: 1, runePoints: 3, rune: .ember, temper: 2)
        XCTAssertEqual(e3.hitDamage, 16); XCTAssertEqual(e3.runeEvery, 3); XCTAssertEqual(e3.burnPerTick, 8)
        let e4 = Weapon(md: 12, blade: 8, hilt: 0, temper: 3)
        XCTAssertEqual(e4.form, .great); XCTAssertEqual(e4.hitDamage, 31); XCTAssertEqual(e4.windup, 0.60)
        let e5 = Weapon(md: 20, blade: 3, hilt: 4, runePoints: 3, rune: .ember, temper: 5)
        XCTAssertEqual(e5.hitDamage, 27); XCTAssertEqual(e5.interval, 0.72); XCTAssertEqual(e5.burnPerTick, 14)
    }

    func testFormBoundaries() {
        XCTAssertEqual(Form.of(blade: 3), .needle)
        XCTAssertEqual(Form.of(blade: 4), .broad)
        XCTAssertEqual(Form.of(blade: 7), .broad)
        XCTAssertEqual(Form.of(blade: 8), .great)
        XCTAssertEqual(Form.of(blade: 12), .great)
        // 4.7.2：跨阈值时单体 DPS 下降、覆盖上升
        let needle = Weapon(md: 20, blade: 3, hilt: 3, temper: 3)
        let broad = Weapon(md: 20, blade: 4, hilt: 3, temper: 3)
        XCTAssertLessThan(Double(broad.hitDamage) / broad.interval, Double(needle.hitDamage) / needle.interval)
        XCTAssertGreaterThan(broad.spec.maxTargets, needle.spec.maxTargets)
    }

    func testTemperIsCappedAtTen() {
        XCTAssertEqual(Weapon(md: 20, blade: 3, hilt: 4, temper: 10).hitDamage,
                       Weapon(md: 20, blade: 3, hilt: 4, temper: 25).hitDamage)
    }

    func testPythonRoundingIsReproduced() {
        // Python round() 对精确二进制值取偶：这些值的 ×100 舍入会给出不同结果
        XCTAssertEqual(pyRound2(1.35 * (1 - 0.07 * 3)), 1.07)
        XCTAssertEqual(pyRound2(0.125), 0.12)
        XCTAssertEqual(pyRound2(0.375), 0.38)
        XCTAssertEqual(rhu(12.5), 13)
        XCTAssertEqual(rhu(12.49), 12)
    }

    func testTagsFollowPRD59() {
        XCTAssertEqual(Weapon(md: 20, blade: 4, hilt: 6, temper: 3).goodVs, [.swarm, .guard])
        XCTAssertEqual(Weapon(md: 20, blade: 8, hilt: 2, temper: 3).goodVs, [.swarm, .armor])
        XCTAssertEqual(Weapon(md: 20, blade: 8, hilt: 2, temper: 3).weakVs, [.guard])
        XCTAssertEqual(Weapon(md: 20, blade: 3, hilt: 4, runePoints: 3, rune: .ember, temper: 3).goodVs, [.armor, .guard])
    }

    func testMetalName() {
        XCTAssertEqual(Weapon(md: 10, blade: 2, hilt: 2).metal, .copper)
        XCTAssertEqual(Weapon(md: 20, blade: 2, hilt: 2).metal, .iron)
        XCTAssertEqual(Weapon(md: 28, blade: 2, hilt: 2).metal, .steel)
    }
}
