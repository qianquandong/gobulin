import GoblinForgeCore
import SpriteKit
import SwiftUI

/// 试玩主界面（PRD 8.1/8.2）：上方战场约 42–45%，接缝提示条，武器架，下方锻造台。
struct PlayView: View {
    @ObservedObject var controller: PrototypeController
    @State private var scene = BattleScene(size: CGSize(width: 390, height: 360))

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                BattlefieldView(controller: controller, live: controller.live, scene: scene)
                    .frame(height: proxy.size.height * (proxy.size.height < 700 ? 0.40 : 0.44))
                SeamTicker(live: controller.live)
                RackView(controller: controller, live: controller.live)
                ForgePanel(controller: controller)
            }
        }
        .onAppear {
            scene.controller = controller
            controller.onEvents = { [weak scene] events in scene?.handle(events) }
            controller.onBattleReset = { [weak scene] in scene?.resetBattle() }
        }
        .alert(L10n.plural("forge_unused_confirm", count: unusedCount), isPresented: binding(for: .unused)) {
            Button(L10n.text("btn_cancel"), role: .cancel) { controller.dialog = nil }
            Button(L10n.text("btn_finish")) { controller.deliver() }
        }
        .alert(L10n.text("forge_reset_confirm"), isPresented: binding(for: .reset)) {
            Button(L10n.text("btn_cancel"), role: .cancel) { controller.dialog = nil }
            Button(L10n.text("btn_reset"), role: .destructive) { controller.confirmReset() }
        }
        .confirmationDialog(L10n.text("rack_full_pick"), isPresented: binding(for: .rackFull), titleVisibility: .visible) {
            ForEach(0..<3, id: \.self) { slot in
                if let weapon = controller.rack[slot] {
                    Button(WeaponText.name(weapon)) { controller.smeltAndDeliver(slot: slot) }
                }
            }
            Button(L10n.text("btn_keep_forging"), role: .cancel) { controller.keepForging() }
        }
        .sheet(isPresented: $controller.showHostMenu) {
            HostMenuView(controller: controller)
        }
    }

    private enum Dialog { case unused, reset, rackFull }

    private var unusedCount: Int {
        if case let .confirmUnused(count)? = controller.dialog { return count }
        return 0
    }

    private func binding(for dialog: Dialog) -> Binding<Bool> {
        Binding(get: {
            switch (dialog, controller.dialog) {
            case (.unused, .confirmUnused?), (.reset, .confirmReset?), (.rackFull, .rackFull?): return true
            default: return false
            }
        }, set: { shown in
            if !shown, controller.dialog != nil {
                switch (dialog, controller.dialog) {
                case (.unused, .confirmUnused?), (.reset, .confirmReset?), (.rackFull, .rackFull?): controller.dialog = nil
                default: break
                }
            }
        })
    }
}

/// 战场 + HUD + 卡片 + 铁匠气泡 + 交付卡片
struct BattlefieldView: View {
    @ObservedObject var controller: PrototypeController
    @ObservedObject var live: LiveStatus
    let scene: BattleScene

    var body: some View {
        ZStack(alignment: .top) {
            SpriteView(scene: scene, preferredFramesPerSecond: 60)
                .accessibilityIdentifier("battlefield")
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HPBar(hp: live.heroHP, max: live.heroMaxHP)
                    Text(L10n.text("hud_wave", ["wave": String(live.wave), "total": String(live.totalWaves)]))
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .accessibilityIdentifier("hud.wave")
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    if controller.caseKind == .transfer && live.maxAttempts > 0 {
                        Text(L10n.text("proto_try", ["attempt": String(live.attempt), "max": String(live.maxAttempts)]))
                            .font(.caption.weight(.semibold).monospacedDigit())
                            .accessibilityIdentifier("hud.try")
                    }
                    if let left = live.timeLeft, left <= 15 {
                        Text(L10n.text("time_left", ["seconds": String(left)]))
                            .font(.caption.weight(.bold).monospacedDigit())
                            .foregroundStyle(Theme.bad)
                            .accessibilityIdentifier("hud.time")
                    }
                }
                // 主持人菜单：右上角长按 1.5 s（隐藏）
                Color.clear
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .onLongPressGesture(minimumDuration: 1.5) { controller.showHostMenu = true }
                    .accessibilityIdentifier("host.trigger")
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            if !controller.deliverLines.isEmpty {
                DeliverCard(lines: controller.deliverLines)
                    .padding(.top, 56)
                    .transition(.opacity)
            }
            VStack {
                Spacer()
                if let bubble = controller.bubble {
                    SmithBubble(text: L10n.text(bubble), id: bubble)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                }
            }
            if let card = controller.card {
                CardOverlay(controller: controller, card: card)
            }
        }
        .clipped()
    }
}

struct HPBar: View {
    let hp: Int
    let max: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(L10n.text("hud_hp", ["hp": String(hp), "max": String(max)]))
                .font(.caption.weight(.bold).monospacedDigit())
                .accessibilityIdentifier("hud.hp")
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.outline.opacity(0.6))
                    Capsule().fill(Theme.bad)
                        .frame(width: g.size.width * CGFloat(hp) / CGFloat(Swift.max(max, 1)))
                }
            }
            .frame(width: 120, height: 6)
        }
    }
}

/// 接缝提示条：下一波特性与数量（真实敌人信息，迁移题也保留）
struct SeamTicker: View {
    @ObservedObject var live: LiveStatus
    var body: some View {
        Text(text)
            .font(.system(.footnote, design: .rounded).weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 24)
            .background(Theme.outline)
            .accessibilityIdentifier("seam")
    }

    private var text: String {
        guard let trait = live.waveTrait else { return " " }
        return L10n.text("seam_next_wave", ["wave": String(live.wave), "trait": L10n.text(trait.stringID),
                                            "count": String(live.waveCount)])
    }
}

struct SmithBubble: View {
    let text: String
    let id: String
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(L10n.text("smith_name")).font(.caption.weight(.heavy)).foregroundStyle(Theme.copper)
            Text(text).font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.outline)
                .accessibilityIdentifier("bubble.\(id)")
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.text, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct DeliverCard: View {
    let lines: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(L10n.text("deliver_changed")).font(.caption.weight(.heavy))
            ForEach(lines, id: \.self) { Text($0).font(.caption) }
        }
        .padding(8)
        .background(Theme.outline.opacity(0.85), in: RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("deliver.card")
    }
}

/// 胜利 / 失败报告 / 时间到 / 首分钟完成
struct CardOverlay: View {
    @ObservedObject var controller: PrototypeController
    let card: Card

    var body: some View {
        switch card {
        case .victory:
            panel {
                Text(L10n.text("victory_title")).font(.system(.title, design: .rounded).weight(.heavy))
                    .accessibilityIdentifier("card.victory")
                nextButton
            }
        case let .defeat(cause, showTip, canRetry):
            panel {
                Text(L10n.text("defeat_title")).font(.system(.title2, design: .rounded).weight(.heavy))
                    .accessibilityIdentifier("card.defeat")
                Text(causeText(cause)).font(.subheadline.weight(.semibold)).multilineTextAlignment(.center)
                    .accessibilityIdentifier("card.cause")
                if showTip {
                    Text(L10n.text(PrototypeController.tipID(for: cause))).font(.subheadline).multilineTextAlignment(.center)
                        .accessibilityIdentifier("card.tip")
                }
                if canRetry {
                    Button { controller.retry() } label: { Text(L10n.text("btn_retry")).frame(minWidth: 120, minHeight: 44) }
                        .buttonStyle(PrimaryButtonStyle())
                        .accessibilityIdentifier("card.retry")
                } else {
                    nextButton
                }
            }
        case .timeUp:
            panel {
                Text(L10n.text("defeat_cause_timeout")).font(.system(.title3, design: .rounded).weight(.heavy))
                    .accessibilityIdentifier("card.timeup")
                nextButton
            }
        case .demoComplete:
            VStack {
                Spacer()
                nextButton.padding(.bottom, 64)
            }
        }
    }

    private var nextButton: some View {
        Button { controller.next() } label: { Text(L10n.text("proto_next")).frame(minWidth: 120, minHeight: 44) }
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityIdentifier("card.next")
    }

    private func panel<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 10, content: content)
            .padding(18)
            .frame(maxWidth: 320)
            .background(Theme.outline.opacity(0.92), in: RoundedRectangle(cornerRadius: 16))
            .padding(.top, 40)
    }

    private func causeText(_ cause: DefeatCause) -> String {
        switch cause {
        case let .guardBlocked(pct): return L10n.text("defeat_cause_guard", ["pct": String(pct)])
        case let .armorSoaked(pct): return L10n.text("defeat_cause_armor", ["pct": String(pct)])
        case let .swarmed(count): return L10n.text("defeat_cause_swarm", ["count": String(count)])
        case .timeout: return L10n.text("defeat_cause_timeout")
        case .outmatched: return L10n.text("defeat_cause_outmatched")
        }
    }
}

/// 武器名与数值的显示（只用 strings.md 的英文）
enum WeaponText {
    /// “{metal} {form}”，例如 Iron Broadsword
    static func name(_ w: Weapon) -> String {
        L10n.text("weapon_name_pattern", ["metal": L10n.text(w.metal.stringID), "form": L10n.text(w.form.nounStringID)])
    }

    static func swing(_ seconds: Double) -> String {
        L10n.text("stat_swing_value", ["seconds": String(format: "%.2f", seconds)])
    }

    static func hits(_ w: Weapon) -> String {
        L10n.text("stat_hits_upto", ["count": String(w.spec.maxTargets)])
    }

    static func rune(_ w: Weapon) -> String {
        guard let rune = w.rune, let every = w.runeEvery else { return "-" }
        let effect: String
        switch rune {
        case .ember: effect = L10n.text("rune_effect_burn")
        case .frost: effect = L10n.text("rune_effect_chill")
        case .spark: effect = L10n.text("rune_effect_shock")
        }
        return L10n.plural("forge_rune_every", count: every, ["effect": effect])
    }
}
