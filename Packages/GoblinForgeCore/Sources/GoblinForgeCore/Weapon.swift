/// 攻击形态（PRD 4.6.2）。Bp 区间决定形态。
public enum Form: String, Codable, CaseIterable, Sendable {
    case needle, broad, great

    public struct Spec: Sendable {
        public let bladeRange: ClosedRange<Int>
        public let multiplier: Double
        public let baseInterval: Double
        /// 扇形角度（度）；Needle 为 0（单体刺击），Great 为 360
        public let arc: Double
        /// 范围（u），从英雄碰撞圆边缘量到敌人碰撞圆边缘
        public let range: Double
        public let maxTargets: Int
    }

    public var spec: Spec {
        switch self {
        case .needle: return Spec(bladeRange: 0...3, multiplier: 1.00, baseInterval: 1.00, arc: 0, range: 1.6, maxTargets: 1)
        case .broad: return Spec(bladeRange: 4...7, multiplier: 0.90, baseInterval: 1.35, arc: 150, range: 2.0, maxTargets: 6)
        case .great: return Spec(bladeRange: 8...12, multiplier: 1.40, baseInterval: 2.30, arc: 360, range: 2.4, maxTargets: 10)
        }
    }

    public static func of(blade: Int) -> Form {
        precondition((0...Rules.bladeCap).contains(blade), "blade \(blade) out of range")
        return Form.allCases.first { $0.spec.bladeRange.contains(blade) }!
    }

    /// strings.md：form_needle_noun（武器名）与 form_needle（形态标签）
    public var nounStringID: String { "form_\(rawValue)_noun" }
    public var labelStringID: String { "form_\(rawValue)" }
}

/// 符文元素。M0 只开放 Ember（PRD 0.2）；Frost / Spark 的规则已移植，供模拟器比对与后续里程碑。
public enum Rune: String, Codable, CaseIterable, Sendable {
    case ember, frost, spark

    public var stringID: String { "rune_\(rawValue)" }
}

/// 交付出的武器：生成时计算并写入属性（PRD 4.12），之后不回溯重算。
public struct Weapon: Codable, Equatable, Hashable, Sendable {
    public let md: Int
    public let blade: Int
    public let hilt: Int
    public let rune: Rune?
    public let runePoints: Int
    public let temper: Int
    public let form: Form
    /// 每击伤害 H
    public let hitDamage: Int
    /// 攻击间隔 I（s，两位小数）
    public let interval: Double
    /// 前摇 W（s，两位小数）；命中帧在前摇结束时
    public let windup: Double
    /// 每 N 次挥砍触发一次符文；无符文为 nil
    public let runeEvery: Int?

    public init(md: Int, blade: Int, hilt: Int, runePoints: Int = 0, rune: Rune? = nil, temper: Int = 0) {
        precondition((0...Rules.bladeCap).contains(blade) && (0...Rules.hiltCap).contains(hilt)
                     && (0...Rules.runeCap).contains(runePoints), "allocation out of range")
        precondition((runePoints == 0) == (rune == nil), "rune points require a rune element")
        let form = Form.of(blade: blade)
        let spec = form.spec
        self.md = md
        self.blade = blade
        self.hilt = hilt
        self.rune = rune
        self.runePoints = runePoints
        self.temper = temper
        self.form = form
        // 与 balance_sim.weapon() 相同的计算顺序，保证浮点结果逐位一致
        hitDamage = rhu(Double(md) * (1 + Rules.bladeStep * Double(blade)) * spec.multiplier
                        * (1 + Rules.temperStep * Double(min(temper, Rules.temperCap))))
        interval = pyRound2(spec.baseInterval * (1 - Rules.hiltStep * Double(hilt)))
        windup = pyRound2(min(0.6, max(0.15, 0.35 * interval)))
        runeEvery = runePoints > 0 ? 6 - runePoints : nil
    }

    public var spec: Form.Spec { form.spec }
    public var metal: Metal { Rules.metal(forMD: md) }

    /// Ember 每跳灼烧：ceil(1.5 × H / 3)，与模拟器 `math.ceil(H * EMBER_RATIO / 3)` 同序
    public var burnPerTick: Int { pyCeil(Double(hitDamage) * Rules.emberRatio / 3) }

    /// 与模拟器 label 相同的写法，用于日志与差分报告，例如 “Broad B4/H6/R0”
    public var label: String {
        let formName = form.rawValue.prefix(1).uppercased() + form.rawValue.dropFirst()
        let runeName = rune.map { " " + $0.rawValue.prefix(1).uppercased() + $0.rawValue.dropFirst() } ?? ""
        return "\(formName) B\(blade)/H\(hilt)/R\(runePoints)\(runeName)"
    }

    /// 克制标签（PRD 5.9），由属性自动推导；M0 迁移题必须隐藏
    public var goodVs: [Trait] {
        var traits: [Trait] = []
        if form != .needle || rune == .spark { traits.append(.swarm) }
        if form == .great || rune == .ember { traits.append(.armor) }
        if interval <= 1.5 || rune == .spark { traits.append(.guard) }
        return traits
    }

    public var weakVs: [Trait] {
        interval > 1.5 && rune != .spark ? [.guard] : []
    }
}

/// 敌人特性（PRD 5.6）
public enum Trait: String, Codable, CaseIterable, Sendable {
    case swarm, armor, `guard`

    public var stringID: String { "trait_\(rawValue)" }
}
