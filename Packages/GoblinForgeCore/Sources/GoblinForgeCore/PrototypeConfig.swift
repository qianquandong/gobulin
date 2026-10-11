import Foundation

/// M0 原型场景配置（config/prototype/m0_cases.json，与 tools/prototype_cases.py 共用）。
/// 数值归 Codex 校准与冻结；客户端只读取，不在代码里写死场景。
public struct PrototypeConfig: Decodable, Equatable, Sendable {
    public let configVersion: String
    public let status: String
    public let transferOrders: [[String]]
    public let cases: [PrototypeCase]

    enum CodingKeys: String, CodingKey {
        case configVersion = "config_version", status, transferOrders = "transfer_orders", cases
    }

    public static func load(from data: Data) throws -> PrototypeConfig {
        try JSONDecoder().decode(PrototypeConfig.self, from: data)
    }

    public func `case`(_ id: String) -> PrototypeCase? { cases.first { $0.id == id } }
    public var demo: PrototypeCase? { cases.first { $0.kind == .demo } }
    public var learning: [PrototypeCase] { cases.filter { $0.kind == .learning } }
}

public enum CaseKind: String, Codable, Sendable {
    /// 首分钟演示：可提示 Blade 与 Deliver，英雄不会战败
    case demo
    /// 单特性学习：可显示主因与方向，不教具体配方
    case learning
    /// 无提示迁移：关闭全部答案提示，只保留真实特性与失败主因
    case transfer
}

/// 武器配置（初始武器架、登记的答案）
public struct WeaponSpec: Codable, Equatable, Sendable {
    public let label: String?
    public let b: Int
    public let h: Int
    public let r: Int
    public let rune: Rune?

    enum CodingKeys: String, CodingKey { case label, b, h, r, rune }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        label = try c.decodeIfPresent(String.self, forKey: .label)
        b = try c.decode(Int.self, forKey: .b)
        h = try c.decode(Int.self, forKey: .h)
        r = try c.decodeIfPresent(Int.self, forKey: .r) ?? 0
        rune = try c.decodeIfPresent(Rune.self, forKey: .rune)
    }

    /// 与锻造台相同的 Temper 规则：min(3, 点数总和)
    public func weapon(md: Int) -> Weapon {
        Weapon(md: md, blade: b, hilt: h, runePoints: r, rune: r > 0 ? rune : nil,
               temper: min(Rules.temperBaseline, b + h + r))
    }
}

public struct PrototypeCase: Decodable, Equatable, Sendable {
    public let id: String
    public let kind: CaseKind
    /// 该场景展示的主要特性（学习题的方向提示用；迁移题不显示）
    public let trait: Trait
    public let md: Int
    public let budget: Int
    public let heroHP: Int
    public let growthStage: Int
    public let runes: [Rune]
    public let initialRack: [WeaponSpec]
    public let waves: [Wave]
    public let loopWaves: Bool
    public let heroMinHP: Int?
    /// 第 k 次尝试使用 attemptSeeds[k-1]（超出后循环）；战斗种子 = seed × 1000 + growthStage
    public let attemptSeeds: [Int]
    /// 0 = 不限
    public let maxAttempts: Int
    public let maxSeconds: Double
    public let answers: [WeaponSpec]

    enum CodingKeys: String, CodingKey {
        case id, kind, trait, md, budget, heroHP = "hero_hp", growthStage = "growth_stage", runes
        case initialRack = "initial_rack", waves, loopWaves = "loop_waves", heroMinHP = "hero_min_hp"
        case attemptSeeds = "attempt_seeds", maxAttempts = "max_attempts", maxSeconds = "max_seconds", answers
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        kind = try c.decode(CaseKind.self, forKey: .kind)
        trait = try c.decode(Trait.self, forKey: .trait)
        md = try c.decode(Int.self, forKey: .md)
        budget = try c.decode(Int.self, forKey: .budget)
        heroHP = try c.decode(Int.self, forKey: .heroHP)
        growthStage = try c.decode(Int.self, forKey: .growthStage)
        runes = try c.decode([Rune].self, forKey: .runes)
        initialRack = try c.decode([WeaponSpec].self, forKey: .initialRack)
        // 波次写作 [["mushling", 4, "A"], ...]
        let raw = try c.decode([[[RawGroupItem]]].self, forKey: .waves)
        waves = try raw.map { wave in try wave.map { try WaveGroup(raw: $0) } }
        loopWaves = try c.decodeIfPresent(Bool.self, forKey: .loopWaves) ?? false
        heroMinHP = try c.decodeIfPresent(Int.self, forKey: .heroMinHP)
        attemptSeeds = try c.decode([Int].self, forKey: .attemptSeeds)
        maxAttempts = try c.decodeIfPresent(Int.self, forKey: .maxAttempts) ?? 0
        maxSeconds = try c.decodeIfPresent(Double.self, forKey: .maxSeconds) ?? 0
        answers = try c.decodeIfPresent([WeaponSpec].self, forKey: .answers) ?? []
    }

    public var forgeConfig: ForgeConfig { ForgeConfig(md: md, budget: budget, availableRunes: runes) }

    /// 第 attempt 次尝试（从 1 开始）的战斗设置
    public func battleSetup(attempt: Int) -> BattleSetup {
        battleSetup(seed: seed(attempt: attempt))
    }

    /// 指定配置种子的战斗设置（校准与比对用）
    public func battleSetup(seed: Int) -> BattleSetup {
        BattleSetup(waves: waves, growthStage: growthStage, heroHP: heroHP,
                    seed: UInt64(seed * 1000 + growthStage), heroMinHP: heroMinHP, loopWaves: loopWaves)
    }

    public func seed(attempt: Int) -> Int { attemptSeeds[(max(attempt, 1) - 1) % attemptSeeds.count] }

    public var totalEnemies: Int { waves.reduce(0) { $0 + $1.reduce(0) { $0 + $1.count } } }
}

/// JSON 里的 ["mushling", 4, "A"] 元素
enum RawGroupItem: Decodable {
    case text(String), number(Int)
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let n = try? c.decode(Int.self) { self = .number(n) } else { self = .text(try c.decode(String.self)) }
    }
}

extension WaveGroup {
    init(raw: [RawGroupItem]) throws {
        guard raw.count == 3, case let .text(kind) = raw[0], case let .number(count) = raw[1],
              case let .text(side) = raw[2], let k = EnemyKind(rawValue: kind), let s = SpawnSide(rawValue: side) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "bad wave group \(raw)"))
        }
        self.init(k, count, s)
    }
}
