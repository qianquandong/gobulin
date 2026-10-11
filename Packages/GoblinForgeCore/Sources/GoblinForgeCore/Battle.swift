import Foundation

/// 一场战斗的固定条件。与模拟器比对时：waves = STAGES[stage]，growthStage = stage，seed = seed × 1000 + stage。
public struct BattleSetup: Codable, Equatable, Sendable {
    public var waves: [Wave]
    /// 敌人属性按哪一关成长（`enemy_stats(kind, stage)`）
    public var growthStage: Int
    public var heroHP: Int
    public var seed: UInt64
    public var normalTimeLimit: Double
    public var bossTimeLimit: Double

    public init(waves: [Wave], growthStage: Int, heroHP: Int, seed: UInt64,
                normalTimeLimit: Double = 90, bossTimeLimit: Double = 120) {
        self.waves = waves
        self.growthStage = growthStage
        self.heroHP = heroHP
        self.seed = seed
        self.normalTimeLimit = normalTimeLimit
        self.bossTimeLimit = bossTimeLimit
    }

    /// 正式关卡（与 `simulate(stage, wpn, hero_hp, seed)` 相同的输入）
    public static func stage(_ stage: Int, heroHP: Int, seed: Int) -> BattleSetup {
        BattleSetup(waves: StageTable.waves(stage), growthStage: stage, heroHP: heroHP,
                    seed: UInt64(seed * 1000 + stage))
    }
}

/// 战斗统计（模拟器的 log 字典）。失败主因判定与波次小结也用它。
public struct BattleLog: Codable, Equatable, Sendable {
    public var blockedByGuard = 0
    public var armorAbsorbed = 0
    public var dealt = 0
    public var burn = 0
    public var hits = 0
    public var swings = 0
    public var maxEngaged = 0
    public var taken = 0
    public var triggers = 0
    /// 一次挥砍实际命中的目标数之和（“Hits/swing” 徽章用；不影响规则）
    public var targetsHit = 0
}

/// 场上的一个敌人。字段与模拟器 `Unit` 一一对应；UI 只读。
public final class BattleUnit {
    public let id: Int
    public let kind: EnemyKind
    public let maxHP: Int
    public let maxGuard: Int
    public let armor: Int
    public let damage: Int
    public let attackInterval: Double
    public let speed: Double
    public let radius: Double
    public let regen: Double
    public internal(set) var hp: Int
    public internal(set) var guardPips: Int
    public internal(set) var x: Double
    public internal(set) var y: Double
    var attackTimer: Double?
    var regenTimer: Double
    var lastHit = -99.0
    /// [剩余跳数, 每跳伤害, 下一跳时刻]
    var burns: [(ticks: Int, perTick: Int, next: Double)] = []
    public internal(set) var chillUntil = 0.0
    var summonTimer: Double
    var slamTimer: Double
    public internal(set) var telegraph: Double?

    init(id: Int, stats: EnemyStats, angleDegrees: Double) {
        self.id = id
        kind = stats.kind
        hp = stats.hp
        maxHP = stats.hp
        guardPips = stats.guardPips
        maxGuard = stats.guardPips
        armor = stats.armor
        damage = stats.damage
        attackInterval = stats.attackInterval
        speed = stats.speed
        radius = stats.radius
        regen = stats.regen
        let a = PyMath.radians(angleDegrees)
        x = Battle.spawnDistance * cos(a)
        y = Battle.spawnDistance * sin(a)
        regenTimer = stats.regen
        summonTimer = stats.kind.base.summon?.every ?? 0
        slamTimer = stats.kind.base.slam?.every ?? 0
    }

    public var distance: Double { PyMath.hypot(x, y) }
    /// 从英雄碰撞圆边缘到敌人碰撞圆边缘的距离（u）
    public var edge: Double { distance - radius - Battle.heroRadius }
    public var isBurning: Bool { !burns.isEmpty }
    public var isAttacking: Bool { attackTimer != nil }
}

/// 战斗中发生的、表现层需要的事件。规则不读取这些事件。
public enum BattleEvent: Equatable, Sendable {
    public enum HitKind: String, Codable, Sendable {
        /// 白色：普通；灰色：被护甲削减超过 50%；Blocked：护盾挡下；橙色：灼烧；黄色：电击
        case normal, armored, blocked, burn, spark
    }

    case waveStarted(index: Int)
    case spawned(unitID: Int)
    case windup(aim: Double, form: Form)
    /// 命中帧：按逻辑形状画一次轮廓（PRD 5.3）；targetIDs 为实际命中的目标
    case swing(aim: Double, form: Form, targetIDs: [Int], runeTriggered: Bool)
    case whiff
    case damage(unitID: Int, amount: Int, kind: HitKind)
    case died(unitID: Int)
    case heroHit(amount: Int)
    case swapStarted
    case swapFinished
    case waveCleared(index: Int)
    case finished(BattleOutcome)
}

/// 失败主因（PRD 5.8，按顺序取第一个满足的）
public enum DefeatCause: Equatable, Codable, Sendable {
    case guardBlocked(percent: Int)
    case armorSoaked(percent: Int)
    case swarmed(count: Int)
    case timeout
    case outmatched
}

public enum BattleOutcome: Equatable, Codable, Sendable {
    case victory
    case defeat(DefeatCause)
}

/// 20 Hz 固定步长的战斗（PRD 5.1–5.5），逐行对应 tools/balance_sim.py 的 `simulate()` 与 `resolve()`。
/// 唯一新增的是战斗中手动换装（PRD 5.4）；不请求换装时，结果与模拟器完全一致。
public final class Battle {
    public static let dt = 0.05
    public static let spawnGap = 0.35
    public static let waveGap = 1.0
    public static let waveHeal = 0.20
    public static let spawnDistance = 6.5
    public static let heroRadius = 0.5
    public static let enemyReach = 0.25
    public static let maxAttackers = 6
    public static let swapDuration = 0.5
    public static let swapCooldown = 3.0
    /// 波次间隔的表现时长（逻辑时间一次性 +1.0 s，与模拟器相同；表现层停 20 个步长）
    public static let breakTicks = 20

    public enum HeroState: Equatable, Sendable { case ready, windup, recover, swapping }

    public let setup: BattleSetup
    public private(set) var weapon: Weapon
    public private(set) var t = 0.0
    public private(set) var heroHP: Int
    public private(set) var waveIndex = 0
    public private(set) var units: [BattleUnit] = []
    public private(set) var log = BattleLog()
    public private(set) var heroState: HeroState = .ready
    public private(set) var aim = 0.0
    public private(set) var outcome: BattleOutcome?
    public private(set) var runeCharge = 0
    /// 剩余的表现间隔步数（> 0 时 step() 不推进逻辑）
    public private(set) var breakTicksLeft = 0
    /// 上一次开始换装的逻辑时刻
    public private(set) var lastSwapAt: Double?

    private var rng: PyRandom
    private var queue: [(EnemyKind, SpawnSide)] = []
    private var spawnTimer = 0.0
    private var timer = 0.0
    private var bossStart: Double?
    private var pendingSwap: Weapon?
    private var nextUnitID = 0
    private var events: [BattleEvent] = []
    private var waveStarted = false

    public init(setup: BattleSetup, weapon: Weapon) {
        self.setup = setup
        self.weapon = weapon
        heroHP = setup.heroHP
        rng = PyRandom(seed: setup.seed)
    }

    public var isFinished: Bool { outcome != nil }
    public var totalWaves: Int { setup.waves.count }
    public var isBossStage: Bool { setup.waves.contains { $0.contains { $0.kind.isBoss } } }
    public var queuedCount: Int { queue.count }
    public var engagedCount: Int { units.filter { $0.isAttacking }.count }

    /// 取出并清空表现事件
    public func drainEvents() -> [BattleEvent] {
        defer { events.removeAll() }
        return events
    }

    // MARK: 换装（PRD 5.4）

    /// 冷却剩余秒数（0 = 可换）
    public var swapCooldownLeft: Double {
        guard let lastSwapAt else { return 0 }
        return max(0, Battle.swapCooldown - (t - lastSwapAt))
    }

    /// 请求换装。前摇中：等这次命中帧结算后开始；收招/空闲：立即开始，耗时 0.5 s，期间不攻击。
    /// 波次间隔中：在下一波开始时生效（与模拟器按波换装相同），符文充能清零。
    @discardableResult
    public func requestSwap(to newWeapon: Weapon) -> Bool {
        guard !isFinished, newWeapon != (pendingSwap ?? weapon), swapCooldownLeft <= 0 else { return false }
        lastSwapAt = t
        pendingSwap = newWeapon
        if breakTicksLeft > 0 || !waveStarted {
            applyPendingSwapInstantly()
        } else if heroState != .windup {
            beginSwap()
        }
        return true
    }

    private func applyPendingSwapInstantly() {
        guard let next = pendingSwap else { return }
        weapon = next
        pendingSwap = nil
        runeCharge = 0
        events.append(.swapFinished)
    }

    private func beginSwap() {
        heroState = .swapping
        timer = Battle.swapDuration
        runeCharge = 0
        events.append(.swapStarted)
    }

    // MARK: 推进

    /// 推进一个逻辑步长（0.05 s）。波次间隔期间只消耗表现步数。
    public func step() {
        guard !isFinished else { return }
        if breakTicksLeft > 0 {
            breakTicksLeft -= 1
            return
        }
        if !waveStarted { startWave() }
        tick()
        if isFinished { return }
        if queue.isEmpty && units.isEmpty {
            events.append(.waveCleared(index: waveIndex))
            t += Battle.waveGap
            waveIndex += 1
            waveStarted = false
            if waveIndex >= setup.waves.count {
                finish(.victory)
            } else {
                breakTicksLeft = Battle.breakTicks
            }
        }
    }

    /// 无表现间隔地跑完整场（模拟器比对、场景校准用）
    public func runToEnd() -> BattleOutcome {
        while !isFinished {
            breakTicksLeft = 0
            step()
        }
        return outcome!
    }

    private func startWave() {
        waveStarted = true
        applyPendingSwapInstantly()
        let wave = setup.waves[waveIndex]
        if wave.contains(where: { $0.kind.isBoss }) {
            heroHP = setup.heroHP           // Boss Gate：回满
            bossStart = t
        } else if waveIndex > 0 {
            heroHP = min(setup.heroHP, heroHP + PyMath.roundEven(Double(setup.heroHP) * Battle.waveHeal))
        }
        queue = []
        for group in wave {
            queue += Array(repeating: (group.kind, group.side), count: group.count)
        }
        rng.shuffle(&queue)
        spawnTimer = 0
        events.append(.waveStarted(index: waveIndex))
    }

    private func sideAngle(_ side: SpawnSide) -> Double {
        switch side {
        case .around: return rng.uniform(0, 360)
        case .right: return 0 + rng.uniform(-35, 35)
        case .top: return 90 + rng.uniform(-35, 35)
        case .left: return 180 + rng.uniform(-35, 35)
        }
    }

    private func makeUnit(_ kind: EnemyKind, angle: Double) -> BattleUnit {
        defer { nextUnitID += 1 }
        return BattleUnit(id: nextUnitID, stats: EnemyStats(kind: kind, stage: setup.growthStage), angleDegrees: angle)
    }

    private func tick() {
        let dt = Battle.dt
        // 刷怪
        spawnTimer -= dt
        if !queue.isEmpty && spawnTimer <= 0 {
            let (kind, side) = queue.removeLast()
            let unit = makeUnit(kind, angle: sideAngle(side))
            units.append(unit)
            events.append(.spawned(unitID: unit.id))
            spawnTimer = Battle.spawnGap
        }
        // 敌人行动（遍历中追加的召唤物在同一步也会行动，与 Python 列表迭代相同）
        var engaged = 0
        var i = 0
        while i < units.count {
            let e = units[i]
            i += 1
            let slow = e.chillUntil > t ? Rules.frostSlow : 1.0
            if e.edge > Battle.enemyReach {
                let step = e.speed * slow * dt
                let d = e.distance
                e.x -= e.x / d * step
                e.y -= e.y / d * step
            } else if engaged >= Battle.maxAttackers && e.attackTimer == nil {
                // 在近战圈外排队，仍可被英雄攻击范围覆盖
            } else {
                engaged += 1
                if e.attackTimer == nil { e.attackTimer = e.attackInterval * 0.5 }
                e.attackTimer! -= dt * slow
                if e.attackTimer! <= 0 {
                    heroHP -= e.damage
                    log.taken += e.damage
                    e.attackTimer = e.attackInterval
                    events.append(.heroHit(amount: e.damage))
                }
            }
            // 护盾回复：`regen` 秒未被击中后，每 `regen` 秒 +1
            if e.maxGuard > 0 && e.guardPips < e.maxGuard && t - e.lastHit >= e.regen {
                e.regenTimer -= dt
                if e.regenTimer <= 0 {
                    e.guardPips += 1
                    e.regenTimer = e.regen
                }
            }
            if let summon = e.kind.base.summon {
                e.summonTimer -= dt * slow
                if e.summonTimer <= 0 {
                    let bossAngle = PyMath.degrees(atan2(e.y, e.x))
                    for _ in 0..<summon.count {
                        let u = makeUnit(summon.kind, angle: bossAngle + rng.uniform(-25, 25))
                        let k = (e.distance + 0.8) / Battle.spawnDistance
                        u.x = u.x * k
                        u.y = u.y * k
                        units.append(u)
                        events.append(.spawned(unitID: u.id))
                    }
                    e.summonTimer = summon.every
                }
            }
            if let slam = e.kind.base.slam {
                if e.telegraph == nil {
                    e.slamTimer -= dt * slow
                    if e.slamTimer <= 0 { e.telegraph = slam.telegraph }
                } else {
                    e.telegraph! -= dt
                    if e.telegraph! <= 0 {
                        heroHP -= slam.damage
                        log.taken += slam.damage
                        e.telegraph = nil
                        e.slamTimer = slam.every
                        events.append(.heroHit(amount: slam.damage))
                    }
                }
            }
            // 灼烧跳（不算命中：无视护甲护盾，不触发符文）
            for b in e.burns.indices where t >= e.burns[b].next {
                e.hp -= e.burns[b].perTick
                log.burn += e.burns[b].perTick
                events.append(.damage(unitID: e.id, amount: e.burns[b].perTick, kind: .burn))
                e.burns[b].ticks -= 1
                e.burns[b].next += 1.0
            }
            e.burns.removeAll { $0.ticks <= 0 }
        }
        log.maxEngaged = max(log.maxEngaged, engaged)
        heroAct()
        for e in units where e.hp <= 0 { events.append(.died(unitID: e.id)) }
        units.removeAll { $0.hp <= 0 }
        t += dt
        if heroHP <= 0 {
            finish(.defeat(defeatCause(timedOut: false)))
            return
        }
        if bossStart == nil ? t >= setup.normalTimeLimit : t - bossStart! >= setup.bossTimeLimit {
            finish(.defeat(defeatCause(timedOut: true)))
        }
    }

    private func heroAct() {
        let dt = Battle.dt
        let inRange = units.filter { $0.edge <= weapon.spec.range }
        switch heroState {
        case .ready:
            guard let primary = Battle.nearest(inRange) else { return }
            aim = atan2(primary.y, primary.x)
            heroState = .windup
            timer = weapon.windup
            events.append(.windup(aim: aim, form: weapon.form))
        case .windup:
            timer -= dt
            if timer <= 0 {
                resolveSwing()
                heroState = .recover
                timer = weapon.interval - weapon.windup
                if pendingSwap != nil { beginSwap() }   // 前摇中请求的换装：命中帧结算后开始
            }
        case .recover:
            timer -= dt
            if timer <= 0 { heroState = .ready }
        case .swapping:
            timer -= dt
            if timer <= 0 {
                if let next = pendingSwap { weapon = next }
                pendingSwap = nil
                runeCharge = 0
                heroState = .ready
                events.append(.swapFinished)
            }
        }
    }

    /// `min(units, key=edge)`：取第一个最小者
    static func nearest(_ units: [BattleUnit]) -> BattleUnit? {
        var best: BattleUnit?
        for u in units where best == nil || u.edge < best!.edge { best = u }
        return best
    }

    /// Python `sorted(..., key=...)`：稳定排序
    static func stableSorted(_ units: [BattleUnit], by key: (BattleUnit) -> Double) -> [BattleUnit] {
        units.enumerated()
            .map { (offset: $0.offset, unit: $0.element, key: key($0.element)) }
            .sorted { $0.key != $1.key ? $0.key < $1.key : $0.offset < $1.offset }
            .map(\.unit)
    }

    // MARK: 命中帧（`resolve()`）

    private func resolveSwing() {
        let w = weapon
        let inRange = units.filter { $0.edge <= w.spec.range && $0.hp > 0 }
        guard !inRange.isEmpty else {
            events.append(.whiff)   // 前摇期间目标死亡或离开
            return
        }
        var targets: [BattleUnit]
        switch w.form {
        case .needle:
            targets = [Battle.nearest(inRange)!]
        case .broad:
            let half = PyMath.radians(w.spec.arc / 2)
            let inArc = inRange.filter { e in
                let a = atan2(e.y, e.x) - aim
                return abs(PyMath.mod(a + Double.pi, 2 * Double.pi) - Double.pi) <= half
            }
            targets = Array(Battle.stableSorted(inArc) { $0.edge }.prefix(w.spec.maxTargets))
            if targets.isEmpty { targets = [Battle.nearest(inRange)!] }
        case .great:
            targets = Array(Battle.stableSorted(inRange) { $0.edge }.prefix(w.spec.maxTargets))
        }
        log.swings += 1
        log.targetsHit += targets.count
        var trigger = false
        if w.rune != nil, let every = w.runeEvery {
            runeCharge += 1
            if runeCharge >= every {
                trigger = true
                runeCharge = 0
                log.triggers += 1
            }
        }
        let raw = Double(w.hitDamage) * (trigger && w.rune == .frost ? 1 + Rules.frostBonus : 1)
        var damaged: [BattleUnit] = []
        for e in targets where applyHit(e, raw: raw, pierce: false) { damaged.append(e) }
        events.append(.swing(aim: aim, form: w.form, targetIDs: targets.map(\.id), runeTriggered: trigger))
        if trigger && !damaged.isEmpty {
            switch w.rune {
            case .ember?:
                let perTick = w.burnPerTick
                for e in damaged where e.burns.isEmpty || e.burns[0].perTick <= perTick {
                    e.burns = [(3, perTick, t + 1.0)]
                }
            case .frost?:
                for e in damaged { e.chillUntil = t + Rules.frostTime }
            default:
                break
            }
        }
        if trigger && w.rune == .spark {
            // Spark 在任何接触到目标的挥砍上触发，即使全部被挡
            let source = targets[0]
            let others = Array(Battle.stableSorted(units.filter { e in
                e !== source && e.hp > 0 && PyMath.hypot(e.x - source.x, e.y - source.y) <= Rules.runeChainRange
            }) { PyMath.hypot($0.x - source.x, $0.y - source.y) }.prefix(2))
            for e in [source] + others where e.hp > 0 {
                applyHit(e, raw: Double(w.hitDamage) * Rules.sparkRatio, pierce: true)
            }
        }
    }

    /// `apply_hit()`：先护盾（非贯穿被挡下返回 false），再护甲（至少 20%）
    @discardableResult
    private func applyHit(_ e: BattleUnit, raw: Double, pierce: Bool) -> Bool {
        log.hits += 1
        e.lastHit = t
        e.regenTimer = 0
        if e.guardPips > 0 {
            e.guardPips -= 1
            log.blockedByGuard += 1
            if !pierce {
                events.append(.damage(unitID: e.id, amount: 0, kind: .blocked))
                return false
            }
        }
        let r = rhu(raw)
        let dmg = max(r - e.armor, pyCeil(Double(r) * Rules.minDamageRatio))
        log.armorAbsorbed += r - dmg
        log.dealt += dmg
        e.hp -= dmg
        let kind: BattleEvent.HitKind = pierce ? .spark : (r - dmg) * 2 > r ? .armored : .normal
        events.append(.damage(unitID: e.id, amount: dmg, kind: kind))
        return true
    }

    // MARK: 结束

    private func finish(_ result: BattleOutcome) {
        outcome = result
        events.append(.finished(result))
    }

    /// 失败主因（PRD 5.8）：① 护盾挡下 ≥ 40% 命中；② 护甲吸收 ≥ 40% 伤害；③ 同时围攻 ≥ 5 且为 Needle；④ 超时；⑤ 其他
    public func defeatCause(timedOut: Bool) -> DefeatCause {
        if log.hits > 0, log.blockedByGuard * 100 >= log.hits * 40 {
            return .guardBlocked(percent: rhu(Double(log.blockedByGuard) * 100 / Double(log.hits)))
        }
        let rawTotal = log.dealt + log.armorAbsorbed
        if rawTotal > 0, log.armorAbsorbed * 100 >= rawTotal * 40 {
            return .armorSoaked(percent: rhu(Double(log.armorAbsorbed) * 100 / Double(rawTotal)))
        }
        if log.maxEngaged >= 5 && weapon.form == .needle { return .swarmed(count: log.maxEngaged) }
        return timedOut ? .timeout : .outmatched
    }

    /// 与模拟器返回值相同口径的结果（比对用）
    public var simulatorSummary: (win: Bool, t: Double, hp: Int, wave: Int, left: Int, timeout: Bool) {
        let win = outcome == .victory
        let timedOut: Bool
        if case .defeat(.timeout)? = outcome { timedOut = true } else { timedOut = false }
        let timeoutByLimit = !win && heroHP > 0
        return (win, PyMath.round1(t), win ? heroHP : max(heroHP, 0), win ? setup.waves.count : waveIndex + 1,
                win ? 0 : units.count + queue.count, timedOut || timeoutByLimit)
    }
}
