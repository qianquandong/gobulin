import Foundation

/// 提示策略（PRD 0.4、5.8 测试模式覆盖规则）
public enum HintPolicy: String, Codable, Sendable {
    /// 首分钟：可提示 Blade 与 Deliver
    case guided
    /// 学习题：可显示主因与方向，不锁定区域、不教具体配方
    case directional
    /// 迁移题与自由继续：关闭推荐、方向、区域呼吸、配方与教学对白，只保留真实特性与失败主因
    case none

    public static func of(_ kind: CaseKind) -> HintPolicy {
        switch kind {
        case .demo: return .guided
        case .learning: return .directional
        case .transfer: return .none
        }
    }

    /// 是否允许显示“方向”类帮助（失败报告第 2 行、Good vs 标签、区域提示）
    public var allowsDirection: Bool { self != .none }
}

/// 一次 M0 试玩的流程（PRD 0.4）：首分钟 → 3 个学习题 → 2 个迁移题（题序交替）→ 事后解释 → 可选自由继续。
/// 纯逻辑：时间由调用方传入（自原型开始的秒数），日志写到 LogSink。原型不保存进度；重启从当前块重来并标记技术中断。
public final class PrototypeRun {
    public enum Step: Equatable, Sendable {
        case playing(caseID: String)
        /// 两道迁移题之后：主持人口头提问 prototype_reason，App 不显示答案
        case interview
        /// 自由继续（最多 3 分钟），轮流重玩迁移题，结果单列
        case freePlay(caseID: String)
        case finished
    }

    /// 迁移题的结束原因
    public enum TransferExit: String, Sendable { case won, attemptsExhausted = "attempts_exhausted", timeUp = "time_up", hostSkip = "host_skip" }

    public static let freePlaySeconds = 180.0

    public let config: PrototypeConfig
    public let participantID: String
    public let orderIndex: Int
    public private(set) var step: Step = .finished
    public private(set) var attempt = 0
    /// 当前场景内是否显示过任何提示（迁移题必须为 false）
    public private(set) var hintExposedInCase = false
    /// 当前场景内玩家是否改锻或换装过
    public private(set) var changedEquipmentInCase = false
    /// 首分钟：是否已用新形态命中 ≥ 3 个目标
    public private(set) var demoGoalReached = false
    private let sink: LogSink
    private var caseStartedAt = 0.0
    private var freePlayStartedAt: Double?
    private var multiHitLogged = false
    private var sequence: [String] = []
    private var index = 0
    private var freePlayIndex = 0

    public init(config: PrototypeConfig, participantID: String, orderIndex: Int, sink: LogSink) {
        self.config = config
        self.participantID = participantID
        self.orderIndex = orderIndex
        self.sink = sink
        let order = config.transferOrders[orderIndex % config.transferOrders.count]
        sequence = [config.demo?.id].compactMap { $0 } + config.learning.map(\.id) + order
    }

    public var currentCase: PrototypeCase? {
        switch step {
        case let .playing(id), let .freePlay(id): return config.case(id)
        default: return nil
        }
    }

    public var hintPolicy: HintPolicy {
        if case .freePlay = step { return .none }
        return currentCase.map { HintPolicy.of($0.kind) } ?? .none
    }

    public var caseNumber: Int { index + 1 }
    public var caseCount: Int { sequence.count }
    public var transferOrderLabel: String { config.transferOrders[orderIndex % config.transferOrders.count].joined(separator: " > ") }

    // MARK: 日志

    private func event(_ name: LogEvent.Name, at time: Double) -> LogEvent {
        var e = LogEvent(event: name, participantID: participantID, configVersion: config.configVersion,
                         elapsedMs: Int((time * 1000).rounded()))
        if let c = currentCase {
            e.caseID = step.isFreePlay ? "free:\(c.id)" : c.id
            e.seed = attempt > 0 ? c.seed(attempt: attempt) : nil
            e.hintPolicy = hintPolicy.rawValue
        }
        return e
    }

    private func write(_ e: LogEvent) { sink.write(e) }

    // MARK: 流程

    /// 开始试玩（主持人确认参与者编号与题序后）。`resumedFrom` 非空表示重启后从该块重新开始（技术中断）。
    public func start(at time: Double, resumedFrom caseID: String? = nil) {
        var e = event(.prototypeStart, at: time)
        e.detail = ["transfer_order": transferOrderLabel]
        write(e)
        if let caseID, let i = sequence.firstIndex(of: caseID) {
            index = i
            step = .playing(caseID: caseID)
            var interrupt = event(.technicalInterrupt, at: time)
            interrupt.detail = ["restart_block": caseID]
            write(interrupt)
        } else {
            index = 0
            step = .playing(caseID: sequence[0])
        }
        beginCase(at: time)
    }

    private func beginCase(at time: Double) {
        attempt = 0
        hintExposedInCase = false
        changedEquipmentInCase = false
        multiHitLogged = false
        demoGoalReached = false
        caseStartedAt = time
    }

    /// 开始一次尝试（进入场景或 Retry），返回战斗设置
    public func beginAttempt(at time: Double) -> BattleSetup? {
        guard let c = currentCase else { return nil }
        attempt += 1
        multiHitLogged = false
        var e = event(.caseStart, at: time)
        e.attempts = attempt
        write(e)
        return c.battleSetup(attempt: attempt)
    }

    /// 首个可交互画面（首分钟计时起点，PRD 0.5）
    public func firstInteractive(at time: Double, coldStartMs: Int) {
        var e = event(.firstInteractive, at: time)
        e.detail = ["cold_start_ms": String(coldStartMs)]
        write(e)
    }

    public func forgeCompleted(_ weapon: Weapon, unusedStrikes: Int, at time: Double) {
        changedEquipmentInCase = true
        var e = event(.forgeComplete, at: time)
        e.equip(weapon)
        e.detail = ["unused_strikes": String(unusedStrikes), "attempt": String(attempt)]
        write(e)
    }

    public func forgeCancelled(strikes: Int, at time: Double) {
        var e = event(.forgeCancel, at: time)
        e.detail = ["strikes": String(strikes)]
        write(e)
    }

    public func weaponSwapped(to weapon: Weapon, at time: Double) {
        changedEquipmentInCase = true
        var e = event(.weaponSwap, at: time)
        e.equip(weapon)
        write(e)
    }

    /// 显示了一条提示。迁移题不应调用；若调用，照常记录并标记为泄漏（不静默吞掉）。
    public func hintShown(_ hintID: String, at time: Double) {
        hintExposedInCase = true
        var e = event(.hintShown, at: time)
        e.detail = ["hint_id": hintID]
        if hintPolicy == .none { e.detail?["leak"] = "true" }
        write(e)
    }

    /// 一次挥砍命中 ≥ 3 个目标（每次尝试只记第一次）。首分钟目标：用新交付的非 Needle 形态命中 ≥ 3。
    public func multiHit(count: Int, weapon: Weapon, deliveredThisCase: Bool, at time: Double) {
        guard count >= 3 else { return }
        if case .playing = step, currentCase?.kind == .demo, deliveredThisCase, weapon.form != .needle {
            demoGoalReached = true
        }
        guard !multiHitLogged else { return }
        multiHitLogged = true
        var e = event(.multiHit, at: time)
        e.equip(weapon)
        e.detail = ["targets": String(count), "delivered_this_case": String(deliveredThisCase)]
        write(e)
    }

    public enum AfterBattle: Equatable, Sendable {
        /// 可以 Retry（或继续改锻）
        case retryAvailable
        /// 本题结束，进入下一步
        case caseFinished
    }

    /// 一次尝试结束。迁移题按 3 次 / 3 分钟上限判定是否结束本题。
    public func battleEnded(outcome: BattleOutcome, weapon: Weapon, initialWeapon: Weapon, battleSeconds: Double,
                            heroHP: Int, at time: Double) -> AfterBattle {
        guard let c = currentCase else { return .caseFinished }
        let won = outcome == .victory
        var e = event(.stageEnd, at: time)
        e.attempts = attempt
        e.success = won
        e.equip(weapon)
        e.detail = ["battle_s": String(format: "%.1f", battleSeconds), "hero_hp": String(heroHP)]
        if case let .defeat(cause) = outcome { e.detail?["defeat_cause"] = cause.code }
        write(e)
        if step.isFreePlay { return .retryAvailable }
        switch c.kind {
        case .demo:
            return .retryAvailable
        case .learning:
            return won ? .caseFinished : .retryAvailable
        case .transfer:
            let timeUsed = time - caseStartedAt
            if won {
                logTransferResult(exit: .won, won: true, wonWithInitial: weapon == initialWeapon, at: time)
                return .caseFinished
            }
            if c.maxAttempts > 0 && attempt >= c.maxAttempts {
                logTransferResult(exit: .attemptsExhausted, won: false, wonWithInitial: false, at: time)
                return .caseFinished
            }
            if c.maxSeconds > 0 && timeUsed >= c.maxSeconds {
                logTransferResult(exit: .timeUp, won: false, wonWithInitial: false, at: time)
                return .caseFinished
            }
            return .retryAvailable
        }
    }

    /// 迁移题的计时上限（从进入本题算起）。到时由流程调用。
    public func transferTimeRemaining(at time: Double) -> Double? {
        guard case .playing = step, let c = currentCase, c.kind == .transfer, c.maxSeconds > 0 else { return nil }
        return max(0, c.maxSeconds - (time - caseStartedAt))
    }

    public func transferTimedOut(at time: Double) {
        logTransferResult(exit: .timeUp, won: false, wonWithInitial: false, at: time)
    }

    private func logTransferResult(exit: TransferExit, won: Bool, wonWithInitial: Bool, at time: Double) {
        var e = event(.transferResult, at: time)
        e.attempts = attempt
        e.success = won
        e.hintExposed = hintExposedInCase
        e.exitReason = exit.rawValue
        // PRD 0.5：首次自由改锻/换装后通关才算迁移成功；初始武器侥幸赢不算；有提示曝光则不算独立完成
        let counts = won && changedEquipmentInCase && !wonWithInitial && !hintExposedInCase
        e.detail = ["changed_equipment": String(changedEquipmentInCase), "won_with_initial": String(wonWithInitial),
                    "counts_as_transfer": String(counts)]
        write(e)
    }

    /// 主持人跳过当前题（如学习阶段超时，PRD 0.4：可直接载入迁移配置收集诊断，不计主指标）
    public func hostSkip(at time: Double) {
        guard let c = currentCase else { return }
        if c.kind == .transfer {
            logTransferResult(exit: .hostSkip, won: false, wonWithInitial: false, at: time)
        } else {
            var e = event(.stageEnd, at: time)
            e.attempts = attempt
            e.success = false
            e.exitReason = "host_skip"
            write(e)
        }
        advance(at: time)
    }

    /// 进入下一题（或事后解释）
    public func advance(at time: Double) {
        if case .freePlay = step {
            freePlayIndex += 1
            let transfers = config.transferOrders[orderIndex % config.transferOrders.count]
            step = .freePlay(caseID: transfers[freePlayIndex % transfers.count])
            beginCase(at: time)
            return
        }
        index += 1
        if index < sequence.count {
            step = .playing(caseID: sequence[index])
            beginCase(at: time)
        } else {
            step = .interview
        }
    }

    /// 事后解释之后：参与者选择结束或自由继续（主持人只说一次中性邀请 prototype_continue）
    public func freePlayChoice(continuePlaying: Bool, at time: Double) {
        guard step == .interview else { return }
        var e = event(.freePlayChoice, at: time)
        e.detail = ["choice": continuePlaying ? "continue" : "finish"]
        write(e)
        if continuePlaying {
            freePlayStartedAt = time
            freePlayIndex = 0
            let transfers = config.transferOrders[orderIndex % config.transferOrders.count]
            step = .freePlay(caseID: transfers[0])
            beginCase(at: time)
        } else {
            end(reason: "finished", at: time)
        }
    }

    public func freePlayRemaining(at time: Double) -> Double? {
        guard let freePlayStartedAt, step.isFreePlay else { return nil }
        return max(0, PrototypeRun.freePlaySeconds - (time - freePlayStartedAt))
    }

    public func end(reason: String, at time: Double) {
        guard step != .finished else { return }
        var e = event(.prototypeEnd, at: time)
        e.exitReason = reason
        write(e)
        step = .finished
    }
}

extension PrototypeRun.Step {
    var isFreePlay: Bool { if case .freePlay = self { return true } else { return false } }
}

extension DefeatCause {
    /// 日志代码
    public var code: String {
        switch self {
        case .guardBlocked: return "guard"
        case .armorSoaked: return "armor"
        case .swarmed: return "swarm"
        case .timeout: return "timeout"
        case .outmatched: return "outmatched"
        }
    }
}
