/// 铁砧上的三个敲击区域（PRD 4.4.3）
public enum ForgeZone: String, Codable, CaseIterable, Sendable {
    case blade, hilt, rune

    public var cap: Int {
        switch self {
        case .blade: return Rules.bladeCap
        case .hilt: return Rules.hiltCap
        case .rune: return Rules.runeCap
        }
    }

    /// strings.md：forge_zone_blade …（BLADE / HILT / RUNE）
    public var stringID: String { "forge_zone_\(rawValue)" }
}

/// 一次锻造的固定条件。M0 原型：预算固定、Temper 固定为基准、无材料消耗（PRD 0.3）。
public struct ForgeConfig: Codable, Equatable, Sendable {
    public var md: Int
    public var budget: Int
    /// 可选的符文元素；空数组时 Rune 区域不可用
    public var availableRunes: [Rune]
    /// 节奏玩法关闭时的固定 Temper（PRD 4.5 Off 模式 = 基准 3）；上限仍为本次有效敲击数
    public var fixedTemper: Int

    public init(md: Int, budget: Int, availableRunes: [Rune] = [], fixedTemper: Int = Rules.temperBaseline) {
        self.md = md
        self.budget = budget
        self.availableRunes = availableRunes
        self.fixedTemper = fixedTemper
    }
}

/// 敲击的处理结果；只有 `.accepted` 改变状态并消耗预算。
public enum StrikeResult: Equatable, Sendable {
    /// 有效敲击；`newForm` 非空表示这一下跨过了形态阈值（播放 “Broad!” / “Greatsword!” 整形）
    case accepted(ForgeZone, newForm: Form?)
    /// 距上次有效敲击不足 0.15 s：静默丢弃，不惩罚
    case tooFast
    /// 区域已满：不消耗预算，显示 `forge_zone_max`
    case zoneMax(ForgeZone)
    /// 预算已用完
    case noBudget
    /// 未选符文元素时点 Rune 区：提示 `forge_rune_pick_hint`
    case runeNotSelected
}

/// 锻造会话（PRD 4.4 状态机：Setup → Striking ⇄ Ready）。Cancel 由持有者丢弃会话实现，无任何残留。
public struct ForgeSession: Codable, Equatable, Sendable {
    public enum Phase: String, Codable, Sendable { case setup, striking, ready }

    public let config: ForgeConfig
    public private(set) var phase: Phase = .setup
    /// 选定的元素；第一次敲击后锁定，只能 Reset 后再改
    public private(set) var rune: Rune?
    /// 有效敲击的顺序（Undo 按此回退）
    public private(set) var strikes: [ForgeZone] = []
    private var lastStrikeAt: Double?

    public init(config: ForgeConfig) {
        self.config = config
    }

    public var blade: Int { strikes.filter { $0 == .blade }.count }
    public var hilt: Int { strikes.filter { $0 == .hilt }.count }
    public var runePoints: Int { strikes.filter { $0 == .rune }.count }
    public var remaining: Int { config.budget - strikes.count }
    /// M0 隐藏节奏：Temper = min(固定值, 有效敲击数)（PRD 4.5 上限规则）
    public var temper: Int { min(config.fixedTemper, strikes.count, Rules.temperCap) }

    public func points(_ zone: ForgeZone) -> Int {
        switch zone {
        case .blade: return blade
        case .hilt: return hilt
        case .rune: return runePoints
        }
    }

    /// 当前分配交付后的武器（即时预览）。同一分配永远得到同一结果。
    public var preview: Weapon {
        Weapon(md: config.md, blade: blade, hilt: hilt, runePoints: runePoints,
               rune: runePoints > 0 ? rune : nil, temper: temper)
    }

    public var canDeliver: Bool { !strikes.isEmpty }

    /// 下一下 Blade 是否会改变形态（预览闪烁 `forge_form_change_warn`）
    public var nextBladeChangesForm: Form? {
        guard blade < Rules.bladeCap, remaining > 0 else { return nil }
        let next = Form.of(blade: blade + 1)
        return next != Form.of(blade: blade) ? next : nil
    }

    /// 选择元素（nil = No Rune）。只在第一次敲击前可改；之后要改只能 Reset。
    @discardableResult
    public mutating func selectRune(_ element: Rune?) -> Bool {
        guard strikes.isEmpty else { return false }
        if let element, !config.availableRunes.contains(element) { return false }
        rune = element
        return true
    }

    /// 在 `time`（单调时钟秒）敲击某区域。
    @discardableResult
    public mutating func strike(_ zone: ForgeZone, at time: Double) -> StrikeResult {
        if let last = lastStrikeAt, time - last < Rules.minStrikeInterval - 1e-9 { return .tooFast }
        guard remaining > 0 else { return .noBudget }
        if zone == .rune, rune == nil { return .runeNotSelected }
        guard points(zone) < zone.cap else { return .zoneMax(zone) }
        let formBefore = preview.form
        strikes.append(zone)
        lastStrikeAt = time
        phase = remaining == 0 ? .ready : .striking
        let formAfter = preview.form
        return .accepted(zone, newForm: formAfter != formBefore ? formAfter : nil)
    }

    /// 撤销最后一下：返还 1 下预算与它带来的 Temper；Ready 时回到 Striking。
    @discardableResult
    public mutating func undo() -> ForgeZone? {
        guard let last = strikes.popLast() else { return nil }
        phase = strikes.isEmpty ? .setup : .striking
        lastStrikeAt = nil
        return last
    }

    /// 清空全部敲击与 Temper（UI 先确认 `forge_reset_confirm`）；元素选择解锁。
    public mutating func reset() {
        strikes = []
        lastStrikeAt = nil
        phase = .setup
    }

    /// 预算未用完时提前完成（UI 先确认 `forge_unused_confirm`）。返回作废的敲击数。
    @discardableResult
    public mutating func finish() -> Int {
        guard canDeliver else { return 0 }
        phase = .ready
        return remaining
    }

    /// 交付：生成武器。会话随之结束（由持有者丢弃）。
    public func deliver() -> Weapon? {
        canDeliver ? preview : nil
    }
}

/// 对比面板的一行（PRD 8.3：只显示有变化的行，形态 > 命中数 > 伤害 > 间隔 > 符文）。
public enum ComparisonRow: Equatable, Sendable {
    case form(from: Form, to: Form)
    case hits(from: Int, to: Int)
    case damage(from: Int, to: Int)
    case swing(from: Double, to: Double)
    case rune(from: Rune?, fromEvery: Int?, to: Rune?, toEvery: Int?)

    /// 变好（绿 ▲）/ 变差（红 ▼）/ 无方向（形态、符文）
    public var isImprovement: Bool? {
        switch self {
        case let .hits(from, to): return to > from
        case let .damage(from, to): return to > from
        case let .swing(from, to): return to < from
        case .form, .rune: return nil
        }
    }

    public static func rows(now: Weapon?, new: Weapon) -> [ComparisonRow] {
        guard let now else {
            return [.form(from: new.form, to: new.form), .hits(from: 0, to: new.spec.maxTargets),
                    .damage(from: 0, to: new.hitDamage), .swing(from: 0, to: new.interval)]
        }
        var rows: [ComparisonRow] = []
        if now.form != new.form { rows.append(.form(from: now.form, to: new.form)) }
        if now.spec.maxTargets != new.spec.maxTargets {
            rows.append(.hits(from: now.spec.maxTargets, to: new.spec.maxTargets))
        }
        if now.hitDamage != new.hitDamage { rows.append(.damage(from: now.hitDamage, to: new.hitDamage)) }
        if now.interval != new.interval { rows.append(.swing(from: now.interval, to: new.interval)) }
        if now.rune != new.rune || now.runeEvery != new.runeEvery {
            rows.append(.rune(from: now.rune, fromEvery: now.runeEvery, to: new.rune, toEvery: new.runeEvery))
        }
        return rows
    }
}
