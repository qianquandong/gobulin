import GoblinForgeCore
import QuartzCore
import SwiftUI

/// 战场上随 20 Hz 逻辑变化的状态，按约 10 Hz 发布；只有 HUD / 接缝条 / 武器架冷却观察它，
/// 锻造台不随它重算（避免按钮在点击过程中被重建）。
@MainActor
final class LiveStatus: ObservableObject {
    @Published var heroHP = 0
    @Published var heroMaxHP = 0
    @Published var wave = 1
    @Published var totalWaves = 1
    @Published var timeLeft: Int?
    @Published var swapCooldown = 0.0
    @Published var equippedIndex: Int?
    @Published var waveTrait: Trait?
    @Published var waveCount = 0
    @Published var attempt = 0
    @Published var maxAttempts = 0
    #if DEBUG
    /// UI 测试探针（只在 Debug 构建）；放在 10 Hz 对象里，避免整棵视图随它重算
    @Published var debugProbe = ""
    #endif
}

/// 覆盖在战场或锻造台上的卡片
enum Card: Equatable {
    case victory
    case defeat(cause: DefeatCause, showTip: Bool, canRetry: Bool)
    case timeUp
    case demoComplete
    case confirmUnused(count: Int)
    case confirmReset
    case rackFull(Weapon)
}

/// M0 原型总控：流程（PrototypeRun）、20 Hz 战斗、锻造、武器架、日志与主持人操作。
@MainActor
final class PrototypeController: ObservableObject {
    enum Screen: Equatable { case setup, play, interview, done }

    struct Floating: Equatable {
        let id: String
        let serial: Int
    }

    let config: PrototypeConfig
    let live = LiveStatus()
    let feedback = Feedback()

    @Published private(set) var screen: Screen = .setup
    @Published private(set) var forge: ForgeSession
    @Published private(set) var rack: [Weapon?] = [nil, nil, nil]
    @Published var card: Card?
    /// 锻造台浮字（`forge_zone_max`、`forge_form_broad` …）
    @Published private(set) var floating: Floating?
    /// 铁匠气泡（只在允许提示的场景出现）
    @Published private(set) var bubble: String?
    /// 交付卡片的行（`change_*`）
    @Published private(set) var deliverLines: [String] = []
    @Published var showHostMenu = false
    @Published private(set) var resumableCase: String?
    @Published private(set) var caseID = ""
    @Published private(set) var caseKind: CaseKind = .demo
    @Published var participantID = ""
    @Published var orderIndex = 0

    private(set) var run: PrototypeRun?
    private(set) var battle: Battle?
    private(set) var logURL: URL?
    private var sink: LogSink?
    private let clockStart = CACurrentMediaTime()
    private var accumulator = 0.0
    private var lastPublish = -1.0
    private var deliveredThisCase = false
    private var initialWeapon: Weapon?
    /// 冷却中交付的武器：冷却结束后自动装备
    private var pendingAutoEquip: Weapon?
    /// 战斗结束后在武器架上选中或新交付的武器：下一次尝试使用
    private var nextAttemptWeapon: Weapon?
    /// 迁移题时间到：停止推进战斗，等待主持人进入下一题
    private var halted = false
    private var floatingSerial = 0
    private var tagsLogged = false
    /// 交付后前 3 次攻击加强轮廓（PRD 8.6 ④）
    private(set) var emphasizedSwingsLeft = 0
    private var multiHitsThisAttempt = 0
    private var swingsThisAttempt = 0
    private var interactiveLogged = false

    /// 场景订阅：新战斗开始（清空节点）与战斗事件（画轮廓、数字）
    var onBattleReset: (@MainActor () -> Void)?
    var onEvents: (@MainActor ([BattleEvent]) -> Void)?

    init(config: PrototypeConfig) {
        self.config = config
        forge = ForgeSession(config: config.demo?.forgeConfig ?? ForgeConfig(md: 10, budget: 7))
        resumableCase = SessionStore.activeCase
        participantID = SessionStore.participant ?? ""
        orderIndex = SessionStore.order
    }

    static func loadBundledConfig() -> PrototypeConfig {
        let url = Bundle.main.url(forResource: "m0_cases", withExtension: "json")!
        return try! PrototypeConfig.load(from: Data(contentsOf: url))
    }

    var now: Double { CACurrentMediaTime() - clockStart }
    var currentCase: PrototypeCase? { run?.currentCase }
    var hintPolicy: HintPolicy { run?.hintPolicy ?? .none }
    var equippedWeapon: Weapon? { nextAttemptWeapon ?? battle?.weapon }

    // MARK: 主持人

    /// 开始本场。`resume` 为 true 时从中断的测试块重新开始，并记录技术中断。
    func startSession(resume: Bool = false) {
        let id = participantID.trimmingCharacters(in: .whitespaces)
        guard !id.isEmpty else { return }
        let url = LogFiles.url(for: id, existing: resume ? SessionStore.logFile : nil)
        logURL = url
        let sink = FileLogSink(url: url)
        self.sink = sink
        let run = PrototypeRun(config: config, participantID: id, orderIndex: orderIndex, sink: sink)
        self.run = run
        SessionStore.begin(participant: id, order: orderIndex, logFile: url.lastPathComponent)
        run.start(at: now, resumedFrom: resume ? resumableCase : nil)
        resumableCase = nil
        screen = .play
        startCase()
    }

    #if DEBUG
    /// UI 测试：替换场景的起始武器（B/H/R），让失败路径可确定地复现
    var debugStartWeapon: (b: Int, h: Int, r: Int)?

    /// UI 测试：直接进入某个场景（不经主持人页、不记技术中断）
    func debugStart(caseID: String, participant: String) {
        participantID = participant
        startSession()
        guard let run else { return }
        while run.currentCase?.id != caseID, case .playing = run.step { run.advance(at: now) }
        startCase()
    }
    #endif

    func hostSkip() {
        guard let run else { return }
        run.hostSkip(at: now)
        showHostMenu = false
        afterAdvance()
    }

    /// 结束页 → 下一位参与者
    func backToSetup() {
        run = nil
        battle = nil
        logURL = nil
        sink = nil
        participantID = ""
        interactiveLogged = false
        resumableCase = nil
        screen = .setup
    }

    func endSession(reason: String = "host_ended") {
        run?.end(reason: reason, at: now)
        SessionStore.clear()
        showHostMenu = false
        battle = nil
        card = nil
        screen = .done
    }

    // MARK: 场景与尝试

    private func startCase() {
        guard let run, let c = run.currentCase else { return }
        caseID = c.id
        caseKind = c.kind
        if case .playing = run.step { SessionStore.activeCase = c.id }
        var initial = c.initialRack.map { $0.weapon(md: c.md) }
        #if DEBUG
        if let w = debugStartWeapon {
            initial[0] = Weapon(md: c.md, blade: w.b, hilt: w.h, runePoints: w.r, rune: w.r > 0 ? c.runes.first : nil,
                                temper: min(Rules.temperBaseline, w.b + w.h + w.r))
        }
        #endif
        rack = (0..<3).map { $0 < initial.count ? initial[$0] : nil }
        initialWeapon = initial.first
        battle = nil
        nextAttemptWeapon = nil
        pendingAutoEquip = nil
        deliveredThisCase = false
        tagsLogged = false
        forge = ForgeSession(config: c.forgeConfig)
        deliverLines = []
        bubble = nil
        card = nil
        beginAttempt()
        if c.kind == .demo {
            showHint("tut_07")
            after(2.5) { [weak self] in
                guard let self, self.caseKind == .demo, !self.deliveredThisCase else { return }
                self.showHint("tut_08")
            }
        }
    }

    private func beginAttempt() {
        guard let run, let setup = run.beginAttempt(at: now),
              let weapon = nextAttemptWeapon ?? battle?.weapon ?? rack.compactMap({ $0 }).first else { return }
        nextAttemptWeapon = nil
        halted = false
        battle = Battle(setup: setup, weapon: weapon)
        accumulator = 0
        multiHitsThisAttempt = 0
        swingsThisAttempt = 0
        onBattleReset?()
        publishLive(force: true)
        if !interactiveLogged {
            interactiveLogged = true
            run.firstInteractive(at: now, coldStartMs: AppLaunch.millisecondsSinceProcessStart())
        }
    }

    func retry() {
        card = nil
        beginAttempt()
    }

    func next() {
        card = nil
        run?.advance(at: now)
        afterAdvance()
    }

    private func afterAdvance() {
        guard let run else { return }
        switch run.step {
        case .playing, .freePlay:
            startCase()
        case .interview:
            battle = nil
            SessionStore.activeCase = nil
            screen = .interview
        case .finished:
            endSession(reason: "finished")
        }
    }

    func freePlayChoice(continuePlaying: Bool) {
        guard let run else { return }
        run.freePlayChoice(continuePlaying: continuePlaying, at: now)
        if continuePlaying {
            screen = .play
            startCase()
        } else {
            endSession(reason: "finished")
        }
    }

    // MARK: 每帧（由 BattleScene 调用）

    func frame(delta: Double) {
        guard screen == .play, let battle, let run, !halted else { return }
        if let remaining = run.transferTimeRemaining(at: now), remaining <= 0, !battle.isFinished {
            run.transferTimedOut(at: now)
            halted = true
            card = .timeUp
            return
        }
        if let remaining = run.freePlayRemaining(at: now), remaining <= 0 {
            endSession(reason: "free_play_time")
            return
        }
        if let pending = pendingAutoEquip, battle.swapCooldownLeft <= 0, !battle.isFinished {
            pendingAutoEquip = nil
            if battle.requestSwap(to: pending) { run.weaponSwapped(to: pending, at: now) }
        }
        if !battle.isFinished {
            accumulator += min(delta, 0.25)
            while accumulator >= Battle.dt && !battle.isFinished {
                battle.step()
                accumulator -= Battle.dt
                handle(battle.drainEvents())
            }
        }
        publishLive(force: false)
    }

    /// 渲染插值系数（0…1）
    var interpolation: Double { min(1, accumulator / Battle.dt) }

    private func handle(_ events: [BattleEvent]) {
        guard let run, let battle else { return }
        for event in events {
            switch event {
            case let .swing(_, _, targets, _):
                swingsThisAttempt += 1
                if targets.count >= 3 {
                    multiHitsThisAttempt += 1
                    let wasReached = run.demoGoalReached
                    run.multiHit(count: targets.count, weapon: battle.weapon, deliveredThisCase: deliveredThisCase, at: now)
                    if !wasReached && run.demoGoalReached {
                        showHint("tut_10")
                        after(1.2) { [weak self] in
                            if self?.card == nil { self?.card = .demoComplete }
                        }
                    }
                }
                if emphasizedSwingsLeft > 0 { emphasizedSwingsLeft -= 1 }
            case .swapFinished:
                feedback.swap()
            case let .finished(outcome):
                battleFinished(outcome)
            default:
                break
            }
        }
        onEvents?(events)
    }

    private func battleFinished(_ outcome: BattleOutcome) {
        guard let run, let battle, let initialWeapon else { return }
        let after = run.battleEnded(outcome: outcome, weapon: battle.weapon, initialWeapon: initialWeapon,
                                    battleSeconds: battle.t, heroHP: max(0, battle.heroHP), at: now)
        publishLive(force: true)
        switch outcome {
        case .victory:
            feedback.success()
            card = .victory
        case let .defeat(cause):
            feedback.reject()
            let showTip = hintPolicy.allowsDirection
            if showTip { run.hintShown(Self.tipID(for: cause), at: now) }
            card = .defeat(cause: cause, showTip: showTip, canRetry: after == .retryAvailable)
        }
    }

    // MARK: 锻造

    func selectRune(_ rune: Rune?) {
        if forge.selectRune(rune) { feedback.select() }
    }

    func strike(_ zone: ForgeZone) {
        switch forge.strike(zone, at: now) {
        case let .accepted(_, newForm):
            feedback.strike(heavy: newForm != nil)
            if let newForm {
                float(newForm == .broad ? "forge_form_broad" : newForm == .great ? "forge_form_great" : "forge_form_needle")
                if caseKind == .demo && newForm == .broad { showHint("tut_09") }
            }
            if forge.remaining == 0 && caseKind == .demo { showHint("tut_04") }
        case .zoneMax:
            feedback.reject()
            float("forge_zone_max")
        case .runeNotSelected:
            feedback.reject()
            float("forge_rune_pick_hint")
        case .noBudget, .tooFast:
            break
        }
    }

    func undo() {
        let formBefore = forge.preview.form
        guard forge.undo() != nil else { return }
        feedback.select()
        let formAfter = forge.preview.form
        if formAfter != formBefore {
            float(formAfter == .needle ? "forge_form_needle" : formAfter == .broad ? "forge_form_broad" : "forge_form_great")
        }
    }

    func requestReset() { if !forge.strikes.isEmpty { card = .confirmReset } }

    func confirmReset() {
        forge.reset()
        card = nil
    }

    func cancelForge() {
        if !forge.strikes.isEmpty { run?.forgeCancelled(strikes: forge.strikes.count, at: now) }
        forge = ForgeSession(config: forge.config)
        feedback.select()
    }

    /// Deliver：预算未用完先确认（`forge_unused_confirm`）
    func requestDeliver() {
        guard forge.canDeliver else { return }
        if forge.remaining > 0 { card = .confirmUnused(count: forge.remaining) } else { deliver() }
    }

    func deliver() {
        card = nil
        guard let weapon = forge.deliver() else { return }
        if let slot = rack.firstIndex(where: { $0 == nil }) {
            place(weapon, at: slot)
        } else {
            card = .rackFull(weapon)
        }
    }

    /// 武器架满：熔炼所选槽位后交付（原型不涉及材料）
    func smeltAndDeliver(slot: Int) {
        guard case let .rackFull(weapon)? = card else { return }
        card = nil
        place(weapon, at: slot)
    }

    func keepForging() { card = nil }

    private func place(_ weapon: Weapon, at slot: Int) {
        guard let run, let battle else { return }
        let previous = equippedWeapon ?? battle.weapon
        let unused = forge.remaining
        rack[slot] = weapon
        run.forgeCompleted(weapon, unusedStrikes: unused, at: now)
        deliveredThisCase = true
        emphasizedSwingsLeft = 3
        deliverLines = Self.changeLines(from: previous, to: weapon)
        after(2.0) { [weak self] in self?.deliverLines = [] }
        feedback.deliver()
        forge = ForgeSession(config: forge.config)
        // 自动装备（settings_auto_equip 默认 On）
        guard weapon != battle.weapon else { return }
        if battle.isFinished {
            nextAttemptWeapon = weapon
            run.weaponSwapped(to: weapon, at: now)
        } else if battle.requestSwap(to: weapon) {
            run.weaponSwapped(to: weapon, at: now)
        } else {
            pendingAutoEquip = weapon      // 冷却中：冷却结束后再换
        }
        publishLive(force: true)
    }

    // MARK: 武器架

    func tapRack(_ index: Int) {
        guard let run, let battle, let weapon = rack[index] else { return }
        if battle.isFinished || halted {
            guard weapon != equippedWeapon else { return }
            nextAttemptWeapon = weapon
            feedback.select()
            run.weaponSwapped(to: weapon, at: now)
        } else if battle.requestSwap(to: weapon) {
            feedback.select()
            run.weaponSwapped(to: weapon, at: now)
        } else {
            feedback.reject()
        }
        publishLive(force: true)
    }

    /// 学习题可在武器下显示 Good vs 标签（每题第一次显示时记一次提示曝光）；迁移题不显示
    func noteTagsShown() {
        guard hintPolicy.allowsDirection, !tagsLogged else { return }
        tagsLogged = true
        run?.hintShown("hint_suggested", at: now)
    }

    // MARK: 提示与浮字

    private func showHint(_ id: String) {
        guard hintPolicy != .none else { return }
        bubble = id
        run?.hintShown(id, at: now)
        after(3.5) { [weak self] in
            if self?.bubble == id { self?.bubble = nil }
        }
    }

    private func float(_ id: String) {
        floatingSerial += 1
        floating = Floating(id: id, serial: floatingSerial)
    }

    static func tipID(for cause: DefeatCause) -> String {
        switch cause {
        case .guardBlocked: return "defeat_tip_guard"
        case .armorSoaked: return "defeat_tip_armor"
        case .swarmed: return "defeat_tip_wider"
        case .timeout: return "defeat_tip_damage"
        case .outmatched: return "defeat_tip_upgrade"
        }
    }

    /// 交付卡片（PRD 8.6 ③）：1–2 行，说明这把武器改变了什么
    static func changeLines(from old: Weapon, to new: Weapon) -> [String] {
        var lines: [String] = []
        if old.form != new.form {
            switch new.form {
            case .broad: lines.append(L10n.text("change_hits_more", ["count": String(new.spec.maxTargets)]))
            case .great: lines.append(L10n.text("change_hits_circle"))
            case .needle: lines.append(L10n.text("change_hits_single"))
            }
        }
        if new.interval > old.interval {
            lines.append(L10n.text("change_slower"))
        } else if new.interval < old.interval {
            lines.append(L10n.text("change_faster"))
        } else if new.hitDamage > old.hitDamage {
            lines.append(L10n.text("change_harder"))
        }
        if let every = new.runeEvery, new.rune != old.rune {
            let effect = L10n.text("rune_effect_burn")
            let runeLine = L10n.plural("forge_rune_every", count: every, ["effect": effect])
            lines.append(L10n.text("change_rune_new", ["rune_line": runeLine]))
        }
        return Array(lines.prefix(2))
    }

    // MARK: 发布

    private func publishLive(force: Bool) {
        guard let battle, let run else { return }
        let t = now
        guard force || t - lastPublish >= 0.1 else { return }
        lastPublish = t
        live.heroHP = max(0, battle.heroHP)
        live.heroMaxHP = battle.setup.heroHP
        live.wave = min(battle.waveIndex + 1, battle.totalWaves)
        live.totalWaves = battle.totalWaves
        live.swapCooldown = battle.swapCooldownLeft
        let equipped = equippedWeapon
        live.equippedIndex = rack.firstIndex { $0 != nil && $0 == equipped }
        live.attempt = run.attempt
        live.maxAttempts = run.currentCase?.maxAttempts ?? 0
        if let remaining = run.transferTimeRemaining(at: t) ?? run.freePlayRemaining(at: t) {
            live.timeLeft = Int(remaining.rounded(.up))
        } else {
            live.timeLeft = nil
        }
        let waves = run.currentCase?.waves ?? []
        let wave = waves.isEmpty ? [] : waves[min(battle.waveIndex, waves.count - 1)]
        // 接缝条只写主要特性及其数量（混合波次只计该特性的敌人，避免把 Shellback 算进 Swarm）
        let mainTrait = wave.max { $0.count < $1.count }?.kind.trait
        live.waveTrait = mainTrait
        live.waveCount = wave.filter { $0.kind.trait == mainTrait }.reduce(0) { $0 + $1.count }
        #if DEBUG
        live.debugProbe = "case=\(caseID) attempt=\(run.attempt) wave=\(live.wave) swings=\(swingsThisAttempt) "
            + "multi=\(multiHitsThisAttempt) goal=\(run.demoGoalReached ? 1 : 0) hp=\(live.heroHP) "
            + "form=\(battle.weapon.form.rawValue) done=\(battle.isFinished ? 1 : 0) "
            + "hints=\(run.hintExposedInCase ? 1 : 0)"
        #endif
    }
}

/// 在主 actor 上延迟执行（替代 DispatchQueue.main.asyncAfter，满足 Swift 6 编译器的隔离检查）
@MainActor
func after(_ seconds: Double, _ body: @escaping @MainActor () -> Void) {
    Task { @MainActor in
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        body()
    }
}
