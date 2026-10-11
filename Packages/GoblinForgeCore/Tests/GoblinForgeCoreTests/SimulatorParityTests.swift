import Foundation
import XCTest
@testable import GoblinForgeCore

/// M0-02 / QA T-02：20 Hz 战斗与 tools/balance_sim.py 逐场一致。
/// 参考值在 Linux（glibc）上生成。Linux 上要求逐位一致；Apple 平台的 libm 在 sin/cos 最后一位可能不同，
/// 随机数、hypot、武器、敌人属性仍要求逐位一致，战斗要求输赢与到达波次一致，细节差异逐条列出并设上限。
final class SimulatorParityTests: XCTestCase {
    #if os(Linux)
    static let sameLibm = true
    #else
    static let sameLibm = false
    #endif

    func testPythonRandomStreamsAreReproduced() {
        for row in Reference.rows("random") {
            let seed = UInt64(row.double("seed")!)
            var r = PyRandom(seed: seed)
            XCTAssertEqual((0..<5).map { _ in r.random() }, row.doubles("random"), "seed \(seed)")
            let uniform = (0..<5).map { _ in r.uniform(-35, 35) } + (0..<3).map { _ in r.uniform(0, 360) }
            XCTAssertEqual(uniform, row.doubles("uniform"), "seed \(seed)")
            var deck = Array(0..<12)
            r.shuffle(&deck)
            XCTAssertEqual(deck, row.ints("shuffle"), "seed \(seed)")
            let bits = [1, 5, 13, 32].map { Int(r.getrandbits($0)) }
            XCTAssertEqual(bits, row.ints("bits"), "seed \(seed)")
        }
    }

    func testHypotMatchesCPythonExactly() {
        let probes = (Reference.math["hypot"] as! [[Any]]).map { $0.map { $0 as! Double } }
        XCTAssertGreaterThan(probes.count, 400)
        for p in probes {
            XCTAssertEqual(PyMath.hypot(p[0], p[1]), p[2], "\(p[0]), \(p[1])")
        }
    }

    func testTrigMatchesReferencePlatform() {
        let probes = (Reference.math["trig"] as! [[Any]]).map { $0.map { $0 as! Double } }
        var differing = 0
        for p in probes {
            let a = PyMath.radians(p[0])
            let values = [cos(a), sin(a), atan2(p[4], p[3]), PyMath.degrees(atan2(p[4], p[3]))]
            for (value, expected) in zip(values, p[1...2] + p[5...6]) where value != expected {
                differing += 1
                // 不同 libm 最多差最后一位
                XCTAssertEqual(value, expected, accuracy: abs(expected).ulp * 1.0001, "deg \(p[0])")
            }
        }
        if Self.sameLibm { XCTAssertEqual(differing, 0, "glibc must match the Linux reference exactly") }
        print("trig probes differing from the Linux reference: \(differing)/\(probes.count * 4)")
    }

    func testEnemyStatsMatchSimulator() {
        for row in Reference.rows("enemies") {
            let kind = EnemyKind(rawValue: row.string("kind")!)!
            let stats = EnemyStats(kind: kind, stage: row.int("stage")!)
            XCTAssertEqual([stats.hp, stats.armor, stats.damage], [row.int("hp")!, row.int("armor")!, row.int("dmg")!],
                           "\(kind) stage \(row.int("stage")!)")
        }
    }

    func testEveryStageBuildAndSeedMatchesSimulator() {
        let rows = Reference.rows("battles")
        XCTAssertGreaterThan(rows.count, 400)
        var detailMismatches: [String] = []
        for row in rows {
            let weapon = Weapon(md: row.int("md")!, blade: row.int("bp")!, hilt: row.int("hp")!, runePoints: row.int("rp")!,
                                rune: row.string("rune").flatMap(Rune.init(rawValue:)), temper: row.int("temper")!)
            let stage = row.int("stage")!, seed = row.int("seed")!
            let battle = Battle(setup: .stage(stage, heroHP: row.int("hero")!, seed: seed), weapon: weapon)
            _ = battle.runToEnd()
            let s = battle.simulatorSummary
            let name = "S\(stage) seed \(seed) \(row.string("label")!)"
            // 输赢与到达波次：所有平台都必须一致
            XCTAssertEqual(s.win, row.bool("win"), name)
            XCTAssertEqual(s.wave, row.int("wave"), name)
            let log = battle.log
            let actual: [Double] = [s.t, Double(s.hp), Double(s.left), s.timeout ? 1 : 0,
                                    Double(log.blockedByGuard), Double(log.armorAbsorbed), Double(log.dealt), Double(log.burn),
                                    Double(log.hits), Double(log.swings), Double(log.maxEngaged), Double(log.taken),
                                    Double(log.triggers)]
            let expected: [Double] = [row.double("t")!, row.double("hero_hp")!, row.double("left")!,
                                      row.bool("timeout")! ? 1 : 0]
                + row.doubles("log")
            if actual != expected {
                detailMismatches.append("\(name): swift \(actual) python \(expected)")
            }
        }
        for line in detailMismatches { print("battle detail mismatch: \(line)") }
        if Self.sameLibm {
            XCTAssertEqual(detailMismatches, [], "Linux must reproduce the simulator exactly")
        } else {
            XCTAssertLessThanOrEqual(detailMismatches.count, rows.count / 100,
                                     "libm last-bit differences may change at most 1% of battle details")
        }
    }

    func testFrameRateDoesNotChangeTheResult() {
        // 逻辑只按 0.05 s 步进：表现层每帧调用几次 step() 不影响结果（QA T-02）
        let weapon = Weapon(md: 20, blade: 4, hilt: 6, temper: 3)
        let a = Battle(setup: .stage(9, heroHP: 164, seed: 1), weapon: weapon)
        _ = a.runToEnd()
        let b = Battle(setup: .stage(9, heroHP: 164, seed: 1), weapon: weapon)
        while !b.isFinished { b.step() }   // 包含 20 步的波次表现间隔
        XCTAssertEqual(a.simulatorSummary.t, b.simulatorSummary.t)
        XCTAssertEqual(a.log, b.log)
    }
}
