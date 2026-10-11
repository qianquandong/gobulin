import XCTest
@testable import GoblinForgeCore

/// M0-02：战斗规则单例（护甲、护盾、灼烧、换装时点），独立于模拟器比对。
final class BattleRuleTests: XCTestCase {
    private func setup(_ waves: [Wave], hp: Int = 164) -> BattleSetup {
        BattleSetup(waves: waves, growthStage: 8, heroHP: hp, seed: 1)
    }

    private func run(_ battle: Battle, until condition: () -> Bool, limit: Int = 4000) {
        var steps = 0
        while !condition() && !battle.isFinished && steps < limit {
            battle.step()
            steps += 1
        }
    }

    func testArmorAlwaysLetsTwentyPercentThrough() {
        // PRD 5.5 D2：E2 Broad（H 13）打 Armor 10 的 Shellback，每击 3
        let shellback = EnemyStats(kind: .shellback, stage: 6)
        XCTAssertEqual(shellback.armor, 10)
        let battle = Battle(setup: BattleSetup(waves: [[WaveGroup(.shellback, 1, .right)]], growthStage: 6, heroHP: 100, seed: 3),
                            weapon: Weapon(md: 10, blade: 4, hilt: 3, temper: 2))
        run(battle) { battle.log.swings > 0 }
        XCTAssertEqual(battle.log.dealt, 3)
        XCTAssertEqual(battle.log.armorAbsorbed, 10)
    }

    func testGuardBlocksWholeHitsAndRegrowsForSlowWeapons() {
        // PRD 5.5 D4：间隔 > 1.5 s 的 Great 永远打不破 Sprite 的护盾
        let great = Weapon(md: 20, blade: 8, hilt: 2, temper: 3)
        let battle = Battle(setup: setup([[WaveGroup(.sprite, 1, .top)]]), weapon: great)
        run(battle) { battle.log.swings >= 6 }
        XCTAssertEqual(battle.log.dealt, 0)
        XCTAssertEqual(battle.log.blockedByGuard, battle.log.hits)
        // 快速 Needle：三击打掉护盾后开始造成伤害
        let needle = Battle(setup: setup([[WaveGroup(.sprite, 1, .top)]]), weapon: Weapon(md: 20, blade: 3, hilt: 6, temper: 3))
        run(needle) { needle.log.swings >= 4 }
        XCTAssertEqual(needle.log.blockedByGuard, 3)
        XCTAssertGreaterThan(needle.log.dealt, 0)
    }

    func testEmberBurnIgnoresArmorAndDoesNotStack() {
        // Needle + Ember 对第 20 关的 Shellback（HP 283，护甲 23）：物理每击只剩 20% 下限，
        // 灼烧每跳 ceil(1.5H/3) 不受护甲影响；同一目标只保留一个灼烧（新灼烧刷新而不叠加）
        let ember = Weapon(md: 20, blade: 3, hilt: 4, runePoints: 3, rune: .ember, temper: 3)
        let battle = Battle(setup: BattleSetup(waves: [[WaveGroup(.shellback, 1, .right)]], growthStage: 20,
                                               heroHP: 400, seed: 1), weapon: ember)
        XCTAssertEqual(EnemyStats(kind: .shellback, stage: 20).armor, 23)
        run(battle) { battle.log.triggers >= 2 }
        XCTAssertEqual(battle.log.triggers, 2)
        XCTAssertEqual(battle.units.first?.burns.count, 1, "a second Ember refreshes instead of stacking")
        XCTAssertEqual(battle.log.dealt, battle.log.swings * 6, "physical hits are floored at 20% of 27")
        run(battle) { battle.isFinished }
        XCTAssertGreaterThan(battle.log.burn, 0)
        XCTAssertEqual(battle.log.burn % ember.burnPerTick, 0, "burn ignores armor: whole per-tick amounts")
    }

    func testSwapDuringWindupResolvesOldAttackFirst() {
        let needle = Weapon(md: 20, blade: 3, hilt: 6, temper: 3)
        let broad = Weapon(md: 20, blade: 4, hilt: 6, temper: 3)
        let battle = Battle(setup: setup([[WaveGroup(.mushling, 4, .right)]]), weapon: needle)
        run(battle) { battle.heroState == .windup }
        _ = battle.drainEvents()
        XCTAssertTrue(battle.requestSwap(to: broad))
        XCTAssertEqual(battle.weapon, needle, "the windup in progress keeps the old weapon")
        run(battle) { battle.heroState != .windup }
        let events = battle.drainEvents()
        let swingIndex = events.firstIndex { if case .swing(_, .needle, _, _) = $0 { return true }; return false }
        let swapIndex = events.firstIndex(of: .swapStarted)
        XCTAssertNotNil(swingIndex)
        XCTAssertNotNil(swapIndex)
        XCTAssertLessThan(swingIndex!, swapIndex!, "old swing resolves before the swap starts")
        XCTAssertEqual(battle.heroState, .swapping)
        // 0.5 s 后换成新形态，期间不攻击
        let swingsBefore = battle.log.swings
        run(battle) { battle.heroState != .swapping }
        XCTAssertEqual(battle.weapon, broad)
        XCTAssertEqual(battle.log.swings, swingsBefore)
        XCTAssertFalse(battle.requestSwap(to: needle), "3 s cooldown between swaps")
    }

    func testSwapAtWaveBreakAppliesAtNextWave() {
        let needle = Weapon(md: 20, blade: 3, hilt: 6, temper: 3)
        let great = Weapon(md: 20, blade: 8, hilt: 2, temper: 3)
        let battle = Battle(setup: setup([[WaveGroup(.mushling, 1, .right)], [WaveGroup(.shellback, 1, .left)]]), weapon: needle)
        run(battle) { battle.breakTicksLeft > 0 }
        XCTAssertTrue(battle.requestSwap(to: great))
        XCTAssertEqual(battle.weapon, great)
        XCTAssertEqual(battle.runeCharge, 0)
    }

    func testDefeatCausesFollowPRDOrder() {
        // Great 对纯 Sprite 波：护盾挡下全部命中 → guard 主因
        let battle = Battle(setup: setup([[WaveGroup(.sprite, 6, .around)]], hp: 40), weapon: Weapon(md: 20, blade: 8, hilt: 2, temper: 3))
        XCTAssertEqual(battle.runToEnd(), .defeat(.guardBlocked(percent: 100)))
    }

    func testRetryWithSameSeedIsReproducible() {
        let weapon = Weapon(md: 20, blade: 4, hilt: 6, temper: 3)
        let a = Battle(setup: .stage(8, heroHP: 164, seed: 4), weapon: weapon)
        let b = Battle(setup: .stage(8, heroHP: 164, seed: 4), weapon: weapon)
        XCTAssertEqual(a.runToEnd(), b.runToEnd())
        XCTAssertEqual(a.log, b.log)
    }
}
