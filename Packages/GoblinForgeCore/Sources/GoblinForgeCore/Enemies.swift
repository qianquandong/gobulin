import Foundation

/// 敌人种类（PRD 5.6 / 5.7）。Boss 规则也移植，供与模拟器的全关卡比对；M0 原型只用 3 类普通敌人。
public enum EnemyKind: String, Codable, CaseIterable, Sendable {
    case mushling, sprite, shellback
    case queen, ironhide, thornwarden
    case wardenElite = "warden_elite"

    public struct Base: Sendable {
        public let hp: Int, armor: Int, guardPips: Int
        public let regen: Double
        public let damage: Int
        public let attackInterval: Double
        public let speed: Double
        public let radius: Double
        /// (召唤种类, 数量, 间隔 s)
        public let summon: (kind: EnemyKind, count: Int, every: Double)?
        /// (间隔 s, 预警 s, 伤害)
        public let slam: (every: Double, telegraph: Double, damage: Int)?
    }

    public var base: Base {
        switch self {
        case .mushling: return Base(hp: 14, armor: 0, guardPips: 0, regen: 0, damage: 3, attackInterval: 1.5, speed: 1.1, radius: 0.35, summon: nil, slam: nil)
        case .sprite: return Base(hp: 16, armor: 0, guardPips: 3, regen: 1.5, damage: 3, attackInterval: 1.6, speed: 1.6, radius: 0.30, summon: nil, slam: nil)
        case .shellback: return Base(hp: 60, armor: 7, guardPips: 0, regen: 0, damage: 7, attackInterval: 2.4, speed: 0.7, radius: 0.50, summon: nil, slam: nil)
        case .queen: return Base(hp: 300, armor: 0, guardPips: 0, regen: 0, damage: 5, attackInterval: 2.2, speed: 0.8, radius: 0.9, summon: (.mushling, 3, 8.0), slam: nil)
        case .ironhide: return Base(hp: 500, armor: 20, guardPips: 0, regen: 0, damage: 6, attackInterval: 2.5, speed: 0.8, radius: 1.0, summon: nil, slam: (12.0, 1.5, 24))
        case .thornwarden: return Base(hp: 750, armor: 0, guardPips: 6, regen: 1.2, damage: 6, attackInterval: 2.0, speed: 0.8, radius: 0.9, summon: (.sprite, 2, 15.0), slam: nil)
        case .wardenElite: return Base(hp: 850, armor: 26, guardPips: 4, regen: 1.2, damage: 8, attackInterval: 2.2, speed: 0.8, radius: 1.0, summon: (.sprite, 2, 14.0), slam: (14.0, 1.5, 30))
        }
    }

    public var isBoss: Bool {
        switch self {
        case .queen, .ironhide, .thornwarden, .wardenElite: return true
        default: return false
        }
    }

    /// 主要特性（波次图标与 M0 学习题）
    public var trait: Trait? {
        switch self {
        case .mushling: return .swarm
        case .sprite: return .guard
        case .shellback: return .armor
        default: return nil
        }
    }

    /// strings.md：enemy_mushling / enemy_sprite / enemy_shellback；Boss 用 boss_*
    public var stringID: String {
        switch self {
        case .mushling, .sprite, .shellback: return "enemy_\(rawValue)"
        case .queen: return "boss_queen"
        case .ironhide: return "boss_ironhide"
        case .thornwarden: return "boss_thornwarden"
        case .wardenElite: return "boss_ironthorn"
        }
    }
}

/// 某关卡的敌人属性（`enemy_stats(kind, stage)`）：HP/护甲/伤害按关卡成长，Boss 用自身关卡的固定值。
public struct EnemyStats: Equatable, Sendable {
    public let kind: EnemyKind
    public let hp: Int, armor: Int, guardPips: Int
    public let regen: Double
    public let damage: Int
    public let attackInterval: Double
    public let speed: Double
    public let radius: Double

    public static let hpGrowth = 1.085
    public static let damageGrowth = 1.03
    public static let armorGrowth = 1.065

    public init(kind: EnemyKind, stage: Int) {
        let base = kind.base
        let k = kind.isBoss ? 1.0 : Foundation.pow(EnemyStats.hpGrowth, Double(stage - 1))
        let d = kind.isBoss ? 1.0 : Foundation.pow(EnemyStats.damageGrowth, Double(stage - 1))
        let ka = kind.isBoss ? 1.0 : Foundation.pow(EnemyStats.armorGrowth, Double(stage - 1))
        self.kind = kind
        hp = rhu(Double(base.hp) * k)
        armor = rhu(Double(base.armor) * ka)
        guardPips = base.guardPips
        regen = base.regen
        damage = rhu(Double(base.damage) * d)
        attackInterval = base.attackInterval
        speed = base.speed
        radius = base.radius
    }
}

/// 刷怪方向（PRD 5.1）：L = 左 180° ± 35°，R = 右 0° ± 35°，T = 上 90° ± 35°，A = 任意角度
public enum SpawnSide: String, Codable, Sendable {
    case left = "L", right = "R", top = "T", around = "A"
}

/// 一波中的一组敌人
public struct WaveGroup: Codable, Equatable, Sendable {
    public let kind: EnemyKind
    public let count: Int
    public let side: SpawnSide

    public init(_ kind: EnemyKind, _ count: Int, _ side: SpawnSide) {
        self.kind = kind
        self.count = count
        self.side = side
    }
}

public typealias Wave = [WaveGroup]

/// 正式关卡 1–20 的波次（`STAGES`）。M0 不开放正式关卡，只用于与模拟器的全量比对。
public enum StageTable {
    public static func waves(_ stage: Int) -> [Wave] {
        func w(_ groups: (EnemyKind, Int, SpawnSide)...) -> Wave { groups.map { WaveGroup($0.0, $0.1, $0.2) } }
        switch stage {
        case 1: return [w((.mushling, 2, .right)), w((.mushling, 3, .around)), w((.mushling, 3, .around))]
        case 2: return [w((.mushling, 3, .around)), w((.mushling, 4, .around)), w((.mushling, 4, .around))]
        case 3: return [w((.mushling, 3, .around)), w((.mushling, 5, .left), (.mushling, 5, .right)), w((.mushling, 5, .around))]
        case 4: return [w((.mushling, 4, .around)), w((.sprite, 2, .top)), w((.mushling, 3, .around), (.sprite, 2, .top))]
        case 5: return [w((.mushling, 4, .around)), w((.sprite, 2, .top), (.mushling, 3, .around)), w((.queen, 1, .top))]
        case 6: return [w((.mushling, 4, .around)), w((.shellback, 1, .right), (.mushling, 3, .left)), w((.shellback, 2, .around))]
        case 7: return [w((.shellback, 2, .around)), w((.mushling, 7, .around)), w((.shellback, 1, .right), (.mushling, 4, .around))]
        case 8: return [w((.sprite, 3, .around)), w((.shellback, 1, .right), (.sprite, 2, .top)), w((.mushling, 8, .around))]
        case 9: return [w((.mushling, 7, .around)), w((.shellback, 2, .around)), w((.sprite, 3, .around), (.shellback, 1, .right))]
        case 10: return [w((.shellback, 2, .around), (.mushling, 3, .around)), w((.sprite, 3, .around)), w((.ironhide, 1, .top))]
        case 11: return [w((.sprite, 4, .around)), w((.mushling, 8, .around)), w((.sprite, 3, .around), (.mushling, 4, .around))]
        case 12: return [w((.sprite, 4, .around)), w((.shellback, 2, .around)), w((.sprite, 3, .around), (.shellback, 1, .top))]
        case 13: return [w((.mushling, 9, .around)), w((.sprite, 4, .around)), w((.mushling, 5, .around), (.sprite, 3, .around))]
        case 14: return [w((.shellback, 3, .around)), w((.sprite, 4, .around)), w((.shellback, 2, .around), (.sprite, 2, .around))]
        case 15: return [w((.sprite, 4, .around)), w((.mushling, 8, .around)), w((.thornwarden, 1, .top))]
        case 16: return [w((.shellback, 3, .around)), w((.mushling, 10, .around)), w((.shellback, 2, .around), (.mushling, 4, .around))]
        case 17: return [w((.sprite, 4, .around)), w((.shellback, 3, .around)), w((.sprite, 3, .around), (.shellback, 1, .around))]
        case 18: return [w((.mushling, 10, .around)), w((.shellback, 4, .around)), w((.mushling, 6, .around), (.shellback, 2, .around))]
        case 19: return [w((.sprite, 4, .around)), w((.mushling, 8, .around), (.sprite, 2, .top)), w((.shellback, 2, .around), (.sprite, 2, .around))]
        case 20: return [w((.shellback, 3, .around), (.mushling, 5, .around)), w((.sprite, 5, .around)), w((.wardenElite, 1, .top))]
        default: return []
        }
    }
}
