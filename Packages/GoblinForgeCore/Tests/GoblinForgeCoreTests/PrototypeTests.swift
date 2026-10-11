import Foundation
import XCTest
@testable import GoblinForgeCore

/// M0-03 / M0-05：原型流程、提示开关、日志字段；M0-04：客户端战斗与校准工具逐场一致。
final class PrototypeTests: XCTestCase {
    static let config: PrototypeConfig = {
        try! PrototypeConfig.load(from: Data(contentsOf: repoFile("config/prototype/m0_cases.json")))
    }()

    private func run(order: Int = 0) -> (PrototypeRun, MemoryLogSink) {
        let sink = MemoryLogSink()
        let run = PrototypeRun(config: Self.config, participantID: "P01", orderIndex: order, sink: sink)
        run.start(at: 0)
        return (run, sink)
    }

    private let needle = Weapon(md: 20, blade: 3, hilt: 6, temper: 3)
    private let great = Weapon(md: 20, blade: 8, hilt: 2, temper: 3)

    func testConfigLoadsAndFollowsPRD03() {
        let c = Self.config
        XCTAssertEqual(c.demo?.md, 10)
        XCTAssertEqual(c.demo?.budget, 7)
        XCTAssertEqual(c.demo?.heroHP, 100)
        XCTAssertEqual(c.demo?.initialRack.first?.weapon(md: 10).form, .needle)
        XCTAssertEqual(c.learning.map(\.trait), [.swarm, .armor, .guard])
        for t in c.cases where t.kind != .demo {
            XCTAssertEqual([t.md, t.budget, t.heroHP], [20, 10, 164], t.id)
        }
        for t in c.cases where t.kind == .transfer {
            XCTAssertEqual(t.initialRack.first?.weapon(md: 20), needle, "transfers start from Needle B3/H6")
            XCTAssertEqual(t.maxAttempts, 3)
            XCTAssertEqual(t.maxSeconds, 180)
        }
    }

    func testSequenceAlternatesTransferOrder() {
        for order in 0...1 {
            let (run, _) = run(order: order)
            var ids: [String] = []
            while case let .playing(id) = run.step {
                ids.append(id)
                run.advance(at: 1)
            }
            XCTAssertEqual(ids.prefix(4), ["demo", "learn_swarm", "learn_armor", "learn_guard"])
            XCTAssertEqual(Array(ids.suffix(2)), Self.config.transferOrders[order])
            XCTAssertEqual(run.step, .interview)
        }
    }

    func testHintPolicyPerCase() {
        let (run, _) = run()
        XCTAssertEqual(run.hintPolicy, .guided)
        run.advance(at: 1)
        XCTAssertEqual(run.hintPolicy, .directional)
        while run.currentCase?.kind != .transfer { run.advance(at: 1) }
        XCTAssertEqual(run.hintPolicy, .none)
        XCTAssertFalse(run.hintPolicy.allowsDirection)
    }

    private func toFirstTransfer(_ run: PrototypeRun) {
        while run.currentCase?.kind != .transfer { run.advance(at: 1) }
    }

    func testTransferEndsAfterThreeAttempts() {
        let (run, sink) = run()
        toFirstTransfer(run)
        for i in 1...3 {
            XCTAssertNotNil(run.beginAttempt(at: 10 + Double(i)))
            let after = run.battleEnded(outcome: .defeat(.outmatched), weapon: needle, initialWeapon: needle,
                                        battleSeconds: 5, heroHP: 0, at: 20 + Double(i))
            XCTAssertEqual(after, i < 3 ? .retryAvailable : .caseFinished)
        }
        let result = sink.events.last { $0.event == .transferResult }!
        XCTAssertEqual(result.exitReason, "attempts_exhausted")
        XCTAssertEqual(result.attempts, 3)
        XCTAssertEqual(result.success, false)
    }

    func testTransferTimeLimit() {
        let (run, sink) = run()
        toFirstTransfer(run)
        _ = run.beginAttempt(at: 100)
        XCTAssertEqual(run.transferTimeRemaining(at: 160)!, 180 - 159, accuracy: 1e-9)
        let after = run.battleEnded(outcome: .defeat(.timeout), weapon: needle, initialWeapon: needle,
                                    battleSeconds: 90, heroHP: 10, at: 1 + 180)
        XCTAssertEqual(after, .caseFinished)
        XCTAssertEqual(sink.events.last?.exitReason, "time_up")
    }

    func testWinCountsAsTransferOnlyAfterOwnChangeWithoutHints() {
        // 初始武器侥幸赢：不算迁移成功
        do {
            let (run, sink) = run()
            toFirstTransfer(run)
            _ = run.beginAttempt(at: 10)
            _ = run.battleEnded(outcome: .victory, weapon: needle, initialWeapon: needle, battleSeconds: 12, heroHP: 90, at: 22)
            XCTAssertEqual(sink.events.last?.detail?["counts_as_transfer"], "false")
        }
        // 自主改锻后获胜：算
        do {
            let (run, sink) = run()
            toFirstTransfer(run)
            _ = run.beginAttempt(at: 10)
            run.forgeCompleted(great, unusedStrikes: 0, at: 12)
            _ = run.battleEnded(outcome: .victory, weapon: great, initialWeapon: needle, battleSeconds: 12, heroHP: 90, at: 24)
            let result = sink.events.last!
            XCTAssertEqual(result.event, .transferResult)
            XCTAssertEqual(result.detail?["counts_as_transfer"], "true")
            XCTAssertEqual(result.hintExposed, false)
        }
        // 提示泄漏：记录为 leak，且不算独立完成
        do {
            let (run, sink) = run()
            toFirstTransfer(run)
            _ = run.beginAttempt(at: 10)
            run.hintShown("defeat_tip_wider", at: 11)
            XCTAssertEqual(sink.events.last?.detail?["leak"], "true")
            run.forgeCompleted(great, unusedStrikes: 0, at: 12)
            _ = run.battleEnded(outcome: .victory, weapon: great, initialWeapon: needle, battleSeconds: 12, heroHP: 90, at: 24)
            XCTAssertEqual(sink.events.last?.hintExposed, true)
            XCTAssertEqual(sink.events.last?.detail?["counts_as_transfer"], "false")
        }
    }

    func testDemoGoalNeedsNewWiderFormHittingThree() {
        let (run, _) = run()
        let demoNeedle = Weapon(md: 10, blade: 2, hilt: 2, temper: 3)
        let broad = Weapon(md: 10, blade: 4, hilt: 3, temper: 3)
        _ = run.beginAttempt(at: 0)
        run.multiHit(count: 3, weapon: demoNeedle, deliveredThisCase: false, at: 5)
        XCTAssertFalse(run.demoGoalReached)
        run.multiHit(count: 2, weapon: broad, deliveredThisCase: true, at: 20)
        XCTAssertFalse(run.demoGoalReached)
        run.multiHit(count: 3, weapon: broad, deliveredThisCase: true, at: 25)
        XCTAssertTrue(run.demoGoalReached)
    }

    func testEventsCarryPRD05Fields() {
        let (run, sink) = run()
        run.firstInteractive(at: 0.4, coldStartMs: 1200)
        _ = run.beginAttempt(at: 0.5)
        run.forgeCompleted(Weapon(md: 10, blade: 4, hilt: 3, temper: 3), unusedStrikes: 0, at: 30.25)
        let forge = sink.events.last!
        let line = forge.jsonLine()
        for key in ["\"participant_id\":\"P01\"", "\"build_mode\":\"prototype\"", "\"config_version\":\"m0-draft-2026-10-11\"",
                    "\"case_id\":\"demo\"", "\"seed\":1", "\"elapsed_ms\":30250", "\"b\":4", "\"h\":3", "\"r\":0",
                    "\"form\":\"broad\"", "\"hint_policy\":\"guided\""] {
            XCTAssertTrue(line.contains(key), "\(key) missing in \(line)")
        }
        XCTAssertFalse(line.contains("\"rune\""), "absent fields are omitted")
        XCTAssertEqual(sink.events.first?.event, .prototypeStart)
    }

    func testInterviewThenFreePlayThenEnd() {
        let (run, sink) = run()
        while case .playing = run.step { run.advance(at: 1) }
        run.freePlayChoice(continuePlaying: true, at: 300)
        guard case .freePlay = run.step else { return XCTFail("expected free play") }
        XCTAssertEqual(run.hintPolicy, .none)
        XCTAssertEqual(run.freePlayRemaining(at: 360), 120)
        _ = run.beginAttempt(at: 301)
        run.forgeCompleted(great, unusedStrikes: 0, at: 302)
        XCTAssertTrue(sink.events.last!.caseID!.hasPrefix("free:"), "free play is logged separately")
        run.end(reason: "free_play_done", at: 480)
        XCTAssertEqual(run.step, .finished)
        XCTAssertEqual(sink.events.last?.event, .prototypeEnd)
    }

    func testRestartAfterCrashMarksTechnicalInterrupt() {
        let sink = MemoryLogSink()
        let run = PrototypeRun(config: Self.config, participantID: "P02", orderIndex: 1, sink: sink)
        run.start(at: 0, resumedFrom: "learn_armor")
        XCTAssertEqual(run.currentCase?.id, "learn_armor")
        XCTAssertEqual(run.attempt, 0)
        XCTAssertTrue(sink.events.contains { $0.event == .technicalInterrupt && $0.detail?["restart_block"] == "learn_armor" })
    }

    /// 客户端战斗 = 校准工具（tools/prototype_cases.py → balance_sim.simulate）
    func testCaseBattlesMatchCalibrationTool() {
        let data = try! Data(contentsOf: repoFile("tools/reference/prototype_reference.json"))
        struct File: Decodable {
            struct Row: Decodable {
                let `case`: String, b: Int, h: Int, r: Int, rune: Rune?, seed: Int, win: Bool, t: Double
                let hero_hp: Int, wave: Int
            }
            let config_version: String
            let results: [Row]
        }
        let file = try! JSONDecoder().decode(File.self, from: data)
        XCTAssertEqual(file.config_version, Self.config.configVersion, "regenerate with tools/prototype_cases.py --write-reference")
        var detail: [String] = []
        for row in file.results {
            let c = Self.config.case(row.case)!
            let w = Weapon(md: c.md, blade: row.b, hilt: row.h, runePoints: row.r, rune: row.r > 0 ? row.rune : nil,
                           temper: min(3, row.b + row.h + row.r))
            let battle = Battle(setup: c.battleSetup(seed: row.seed), weapon: w)
            let outcome = battle.runToEnd()
            let s = battle.simulatorSummary
            XCTAssertEqual(outcome == .victory, row.win, "\(row.case) \(w.label) seed \(row.seed)")
            if s.t != row.t || s.hp != row.hero_hp || s.wave != row.wave {
                detail.append("\(row.case) \(w.label) seed \(row.seed): swift \(s.t)s/\(s.hp) python \(row.t)s/\(row.hero_hp)")
            }
        }
        for d in detail { print("prototype detail mismatch: \(d)") }
        if SimulatorParityTests.sameLibm { XCTAssertEqual(detail, []) }
        else { XCTAssertLessThanOrEqual(detail.count, file.results.count / 50) }
    }
}
