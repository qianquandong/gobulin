import GoblinForgeCore
import SwiftUI

/// 3 格武器架（PRD 8.4、5.4）：单击换装；当前装备高亮；换装冷却；学习题可显示 Good vs 标签，迁移题不显示。
struct RackView: View {
    @ObservedObject var controller: PrototypeController
    @ObservedObject var live: LiveStatus

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { slot in
                slotView(slot)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Theme.wood.opacity(0.9))
        .onAppear(perform: logTags)
        .onChange(of: controller.rack) { _, _ in logTags() }
    }

    private var showTags: Bool { controller.hintPolicy.allowsDirection && controller.caseKind == .learning }

    private func logTags() {
        if showTags && controller.rack.contains(where: { $0.map { !$0.goodVs.isEmpty } ?? false }) {
            controller.noteTagsShown()
        }
    }

    @ViewBuilder
    private func slotView(_ slot: Int) -> some View {
        let weapon = controller.rack[slot]
        let equipped = live.equippedIndex == slot
        Button { controller.tapRack(slot) } label: {
            VStack(spacing: 2) {
                if let weapon {
                    Text(L10n.text(weapon.form.nounStringID))
                        .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    Text("\(weapon.hitDamage) · \(WeaponText.swing(weapon.interval))")
                        .font(.caption2.monospacedDigit())
                    if weapon.rune != nil {
                        Text(L10n.text(weapon.rune!.stringID)).font(.caption2.weight(.bold)).foregroundStyle(Theme.ember)
                    }
                    if showTags, let trait = weapon.goodVs.first {
                        Text(L10n.text("hint_suggested", ["trait": L10n.text(trait.stringID)]))
                            .font(.caption2).foregroundStyle(Theme.good)
                    }
                    if equipped {
                        Text(L10n.text("weapon_equipped")).font(.caption2.weight(.semibold)).foregroundStyle(Theme.copper)
                    } else if live.swapCooldown > 0 {
                        Text(L10n.text("swap_cooldown", ["seconds": String(Int(live.swapCooldown.rounded(.up)))]))
                            .font(.caption2).opacity(0.8)
                    }
                } else {
                    Text("—").font(.title3).opacity(0.4)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.vertical, 2)
            .background(equipped ? Theme.outline.opacity(0.85) : Theme.outline.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(equipped ? Theme.copper : .clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .disabled(weapon == nil)
        .accessibilityIdentifier("rack.\(slot)")
        .accessibilityValue(equipped ? "equipped" : "")
    }
}

/// 锻造台（PRD 4.4、8.3）：左侧铁砧三区域（每区 ≥ 64×64 pt，区间 8 pt 死区），右侧符文选择与 NOW→NEW 对比，
/// 底部 Undo / Reset / Cancel / Deliver（Deliver 在右下，单手）。按钮全部是普通 Button。
struct ForgePanel: View {
    @ObservedObject var controller: PrototypeController

    private var forge: ForgeSession { controller.forge }

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                anvil
                    .frame(width: 150)
                VStack(alignment: .leading, spacing: 6) {
                    if !forge.config.availableRunes.isEmpty { runeBar }
                    comparison
                    Spacer(minLength: 0)
                    Text(L10n.plural("forge_strikes_left", count: forge.remaining))
                        .font(.footnote.weight(.semibold).monospacedDigit())
                        .accessibilityIdentifier("forge.remaining")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            buttons
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(Theme.wood)
        .overlay(alignment: .top) { floatingText }
    }

    // MARK: 铁砧

    private var anvil: some View {
        VStack(spacing: 8) {
            zoneButton(.blade, height: 82)
            zoneButton(.rune, height: 64)
            zoneButton(.hilt, height: 64)
        }
    }

    private func zoneButton(_ zone: ForgeZone, height: CGFloat) -> some View {
        let disabledRune = zone == .rune && (forge.config.availableRunes.isEmpty || forge.rune == nil)
        return Button { controller.strike(zone) } label: {
            HStack(spacing: 6) {
                ZoneGlyph(zone: zone, points: forge.points(zone), form: forge.preview.form)
                    .frame(width: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.text(zone.stringID)).font(.system(.subheadline, design: .rounded).weight(.heavy))
                    Text(L10n.text("forge_zone_count", ["points": String(forge.points(zone)), "cap": String(zone.cap)]))
                        .font(.caption.monospacedDigit())
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, minHeight: max(64, height), maxHeight: max(64, height))
            .background(Theme.outline.opacity(disabledRune ? 0.25 : 0.55), in: RoundedRectangle(cornerRadius: 12))
            .opacity(disabledRune ? 0.6 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("forge.zone.\(zone.rawValue)")
        .accessibilityValue("\(forge.points(zone))")
    }

    private var runeBar: some View {
        HStack(spacing: 6) {
            runeChoice(nil, key: "forge_rune_none")
            ForEach(forge.config.availableRunes, id: \.self) { rune in
                runeChoice(rune, key: rune.stringID)
            }
        }
    }

    private func runeChoice(_ rune: Rune?, key: String) -> some View {
        Button { controller.selectRune(rune) } label: {
            Text(L10n.text(key)).frame(minWidth: 64, minHeight: 32).padding(.horizontal, 4)
        }
        .buttonStyle(ChoiceButtonStyle(selected: forge.rune == rune))
        .disabled(!forge.strikes.isEmpty && forge.rune != rune)
        .accessibilityIdentifier("forge.rune.\(rune?.rawValue ?? "none")")
    }

    // MARK: 对比

    private var comparison: some View {
        let now = controller.equippedWeapon
        let new = forge.preview
        return VStack(alignment: .leading, spacing: 3) {
            if let warn = forge.nextBladeChangesForm {
                Text(L10n.text("forge_form_change_warn", ["form": L10n.text(warn.nounStringID)]))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.ember)
                    .accessibilityIdentifier("forge.warn")
            }
            HStack {
                Text(L10n.text("stat_form")).font(.caption)
                Text(L10n.text(new.form.labelStringID)).font(.caption.weight(.heavy))
                    .accessibilityIdentifier("forge.form")
            }
            if !forge.strikes.isEmpty {
                HStack {
                    Spacer().frame(width: 58)
                    Text(L10n.text("forge_compare_now")).font(.caption2.weight(.bold)).frame(width: 64, alignment: .leading)
                    Text(L10n.text("forge_compare_new")).font(.caption2.weight(.bold))
                }
                ForEach(Array(ComparisonRow.rows(now: now, new: new).prefix(4).enumerated()), id: \.offset) { _, row in
                    rowView(row)
                }
            }
        }
    }

    private func rowView(_ row: ComparisonRow) -> some View {
        let (label, from, to) = Self.texts(row)
        let color: Color = row.isImprovement.map { $0 ? Theme.good : Theme.bad } ?? Theme.text
        return HStack(spacing: 4) {
            Text(label).font(.caption).frame(width: 58, alignment: .leading)
            Text(from).font(.caption.monospacedDigit()).frame(width: 64, alignment: .leading).opacity(0.8)
            Text(to).font(.caption.weight(.bold).monospacedDigit()).foregroundStyle(color)
            if let better = row.isImprovement { Text(better ? "▲" : "▼").font(.caption2).foregroundStyle(color) }
        }
    }

    static func texts(_ row: ComparisonRow) -> (String, String, String) {
        switch row {
        case let .form(from, to):
            return (L10n.text("stat_form"), L10n.text(from.labelStringID), L10n.text(to.labelStringID))
        case let .hits(from, to):
            return (L10n.text("stat_hits"), L10n.text("stat_hits_upto", ["count": String(from)]),
                    L10n.text("stat_hits_upto", ["count": String(to)]))
        case let .damage(from, to):
            return (L10n.text("stat_damage"), String(from), String(to))
        case let .swing(from, to):
            return (L10n.text("stat_swing"), WeaponText.swing(from), WeaponText.swing(to))
        case let .rune(_, fromEvery, toRune, toEvery):
            let toText = toRune != nil && toEvery != nil
                ? L10n.plural("forge_rune_every", count: toEvery!, ["effect": L10n.text("rune_effect_burn")]) : "-"
            let fromText = fromEvery.map { L10n.plural("forge_rune_every", count: $0, ["effect": L10n.text("rune_effect_burn")]) } ?? "-"
            return (L10n.text("stat_rune"), fromText, toText)
        }
    }

    // MARK: 按钮

    private var buttons: some View {
        HStack(spacing: 8) {
            Button { controller.undo() } label: { Text(L10n.text("btn_undo")).frame(maxWidth: .infinity, minHeight: 44) }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(forge.strikes.isEmpty)
                .accessibilityIdentifier("forge.undo")
            Button { controller.requestReset() } label: { Text(L10n.text("btn_reset")).frame(maxWidth: .infinity, minHeight: 44) }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(forge.strikes.isEmpty)
                .accessibilityIdentifier("forge.reset")
            Button { controller.cancelForge() } label: { Text(L10n.text("btn_cancel")).frame(maxWidth: .infinity, minHeight: 44) }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityIdentifier("forge.cancel")
            Button { controller.requestDeliver() } label: { Text(L10n.text("btn_deliver")).frame(maxWidth: .infinity, minHeight: 44) }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!forge.canDeliver)
                .accessibilityIdentifier("forge.deliver")
        }
    }

    // MARK: 浮字（Max、Broad!、Pick a rune…）

    @ViewBuilder
    private var floatingText: some View {
        if let floating = controller.floating {
            FloatingLabel(text: L10n.text(floating.id), serial: floating.serial)
                .accessibilityIdentifier("forge.float.\(floating.id)")
        }
    }
}

/// 短暂浮现后淡出的文字；serial 变化时重新播放
struct FloatingLabel: View {
    let text: String
    let serial: Int
    @State private var visible = true

    var body: some View {
        Text(text)
            .font(.system(.title3, design: .rounded).weight(.heavy))
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Theme.outline.opacity(0.85), in: Capsule())
            .opacity(visible ? 1 : 0)
            .offset(y: -18)
            .id(serial)
            .onAppear { flash() }
            .onChange(of: serial) { _, _ in flash() }
            .allowsHitTesting(false)
    }

    private func flash() {
        visible = true
        withAnimation(.easeOut(duration: 0.4).delay(0.8)) { visible = false }
    }
}

/// 区域图形占位：刀身随 Blade 点数变宽/变长，剑柄每点多一圈，符文宝石按点数变亮（PRD 8.6 ①）
struct ZoneGlyph: View {
    let zone: ForgeZone
    let points: Int
    let form: GoblinForgeCore.Form

    var body: some View {
        Canvas { context, size in
            let mid = size.width / 2
            switch zone {
            case .blade:
                let width = 6 + CGFloat(points) * 1.6
                let rect = CGRect(x: mid - width / 2, y: 4, width: width, height: size.height - 8)
                context.fill(Path(roundedRect: rect, cornerRadius: width / 2.5), with: .color(Theme.steel))
            case .rune:
                let r = 9.0
                let circle = Path(ellipseIn: CGRect(x: mid - r, y: size.height / 2 - r, width: r * 2, height: r * 2))
                context.fill(circle, with: .color(Theme.ember.opacity(0.25 + 0.15 * Double(points))))
                context.stroke(circle, with: .color(Theme.outline), lineWidth: 1.5)
            case .hilt:
                let rect = CGRect(x: mid - 4, y: 6, width: 8, height: size.height - 12)
                context.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(Theme.copper))
                for i in 0..<points {
                    let y = 10 + CGFloat(i) * (size.height - 20) / 6
                    context.stroke(Path(CGRect(x: mid - 7, y: y, width: 14, height: 2)), with: .color(Theme.outline), lineWidth: 1.5)
                }
            }
        }
        .accessibilityHidden(true)
    }
}
