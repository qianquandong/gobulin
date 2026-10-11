import GoblinForgeCore
import SpriteKit
import UIKit

/// 上半屏战场（PRD 5.1、5.3、8.6）。只读规则层状态与事件来画：位置、轮廓、数字；不参与判定。
/// 正式素材（char_pip、enemy_*、weapon_*、fx_form_outline_*）到位前用程序图形占位，节点名即资源 ID。
@MainActor
final class BattleScene: SKScene {
    weak var controller: PrototypeController?
    private let world = SKNode()
    private let hero = SKNode()
    private let weaponGlyph = SKShapeNode()
    private var unitNodes: [Int: UnitNode] = [:]
    private var lastTime: TimeInterval?
    private var renderedForm: Form?

    /// 1u 对应的点数：12u × 9u 的战场放进场景（PRD 5.1）
    private var unit: CGFloat { max(8, min(size.width / 12, size.height / 9)) }

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(hex: 0x466854)
        scaleMode = .resizeFill
        if world.parent == nil {
            addChild(world)
            buildHero()
        }
        layoutWorld()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        layoutWorld()
    }

    private func layoutWorld() {
        world.position = CGPoint(x: size.width / 2, y: size.height / 2)
        hero.setScale(unit / 32)
    }

    private func buildHero() {
        let body = SKShapeNode(circleOfRadius: 16)       // 碰撞半径 0.5u = 16pt（1u = 32pt 时）
        body.fillColor = UIColor(hex: 0xB87942)
        body.strokeColor = UIColor(hex: 0x252A28)
        body.lineWidth = 3
        body.name = "char_pip"
        hero.addChild(body)
        weaponGlyph.strokeColor = UIColor(hex: 0x252A28)
        weaponGlyph.lineWidth = 2
        weaponGlyph.fillColor = UIColor(hex: 0xD9E2DB)
        weaponGlyph.zPosition = 1
        hero.addChild(weaponGlyph)
        hero.zPosition = 5
        world.addChild(hero)
    }

    /// 新的一次尝试：清空敌人节点
    func resetBattle() {
        for node in unitNodes.values { node.removeFromParent() }
        unitNodes = [:]
        world.children.filter { $0.name == "fx" }.forEach { $0.removeFromParent() }
        renderedForm = nil
    }

    override func update(_ currentTime: TimeInterval) {
        let delta = lastTime.map { currentTime - $0 } ?? 0
        lastTime = currentTime
        controller?.frame(delta: delta)
        sync()
    }

    // MARK: 同步状态

    private func sync() {
        guard let battle = controller?.battle else { return }
        let u = unit
        if renderedForm != battle.weapon.form {
            renderedForm = battle.weapon.form
            weaponGlyph.path = Self.weaponPath(battle.weapon.form)
            weaponGlyph.name = "weapon_\(battle.weapon.form.rawValue)"
        }
        weaponGlyph.zRotation = CGFloat(battle.aim)
        var alive = Set<Int>()
        for e in battle.units {
            alive.insert(e.id)
            let node = unitNodes[e.id] ?? makeUnitNode(e)
            let target = CGPoint(x: e.x * u, y: e.y * u)
            // 20 Hz 逻辑位置之间做平滑（只影响画面）
            node.position = CGPoint(x: node.position.x + (target.x - node.position.x) * 0.5,
                                    y: node.position.y + (target.y - node.position.y) * 0.5)
            node.setScale(u / 32)
            node.update(hp: e.hp, maxHP: e.maxHP, guardPips: e.guardPips, burning: e.isBurning)
        }
        for (id, node) in unitNodes where !alive.contains(id) {
            unitNodes[id] = nil
            node.run(.sequence([.group([.fadeOut(withDuration: 0.25), .scale(by: 0.6, duration: 0.25)]), .removeFromParent()]))
        }
    }

    private func makeUnitNode(_ e: BattleUnit) -> UnitNode {
        let node = UnitNode(kind: e.kind, radius: e.radius * 32, armor: e.armor, guardPips: e.maxGuard)
        node.position = CGPoint(x: e.x * unit, y: e.y * unit)
        node.zPosition = 3
        world.addChild(node)
        unitNodes[e.id] = node
        return node
    }

    // MARK: 事件

    func handle(_ events: [BattleEvent]) {
        guard let battle = controller?.battle else { return }
        for event in events {
            switch event {
            case let .swing(aim, form, targets, _):
                let emphasized = (controller?.emphasizedSwingsLeft ?? 0) > 0
                drawOutline(form: form, aim: aim, range: battle.weapon.spec.range, emphasized: emphasized)
                if targets.count >= 3 { showHitCount(targets.count) }
            case .whiff:
                break
            case let .damage(id, amount, kind):
                guard let node = unitNodes[id] else { continue }
                floatNumber(amount: amount, kind: kind, at: node.position)
            case .heroHit:
                hero.removeAction(forKey: "hurt")
                hero.run(.sequence([.colorize(with: .red, colorBlendFactor: 0.6, duration: 0.05),
                                    .wait(forDuration: 0.08), .colorize(withColorBlendFactor: 0, duration: 0.1)]),
                         withKey: "hurt")
                (hero.children.first as? SKShapeNode)?.run(.sequence([.scale(to: 0.92, duration: 0.05), .scale(to: 1, duration: 0.08)]))
            default:
                break
            }
        }
    }

    /// 命中帧按逻辑形状画一次轮廓（Needle 细线、Broad 150° 扇形、Great 圆环）；“减少特效”也不能关掉
    private func drawOutline(form: Form, aim: Double, range: Double, emphasized: Bool) {
        let u = unit
        let radius = CGFloat(Battle.heroRadius + range) * u
        let node: SKShapeNode
        switch form {
        case .needle:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0.5 * u * cos(aim), y: 0.5 * u * sin(aim)))
            path.addLine(to: CGPoint(x: radius * cos(aim), y: radius * sin(aim)))
            node = SKShapeNode(path: path)
            node.lineWidth = emphasized ? 6 : 3
            node.name = "fx"
        case .broad:
            let path = CGMutablePath()
            path.move(to: .zero)
            path.addArc(center: .zero, radius: radius, startAngle: CGFloat(aim) - .pi * 75 / 180,
                        endAngle: CGFloat(aim) + .pi * 75 / 180, clockwise: false)
            path.closeSubpath()
            node = SKShapeNode(path: path)
            node.fillColor = UIColor(hex: 0xD9E2DB, alpha: emphasized ? 0.35 : 0.2)
            node.lineWidth = emphasized ? 4 : 2
        case .great:
            node = SKShapeNode(circleOfRadius: radius)
            node.fillColor = UIColor(hex: 0xD9E2DB, alpha: emphasized ? 0.25 : 0.12)
            node.lineWidth = emphasized ? 6 : 3
        }
        node.name = "fx"
        node.strokeColor = UIColor(hex: 0xF3E8D1, alpha: emphasized ? 1 : 0.8)
        node.zPosition = 2
        world.addChild(node)
        let hold = emphasized ? 0.3 : 0.15   // PRD 8.6 ④：新武器前 3 击轮廓持续 0.3 s
        node.run(.sequence([.wait(forDuration: hold), .fadeOut(withDuration: 0.1), .removeFromParent()]))
    }

    private func floatNumber(amount: Int, kind: BattleEvent.HitKind, at position: CGPoint) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        switch kind {
        case .blocked:
            label.text = L10n.text("combat_blocked")
            label.fontColor = UIColor(hex: 0x6FA8FF)
        case .armored:
            label.text = "\(amount)"
            label.fontColor = UIColor(hex: 0xA7A9A6)
        case .burn:
            label.text = "\(amount)"
            label.fontColor = UIColor(hex: 0xF07F2E)
        case .spark:
            label.text = "\(amount)"
            label.fontColor = UIColor(hex: 0xF4D35E)
        case .normal:
            label.text = "\(amount)"
            label.fontColor = .white
        }
        label.fontSize = kind == .blocked ? 14 : 16
        label.position = CGPoint(x: position.x, y: position.y + 0.5 * unit)
        label.zPosition = 6
        label.name = "fx"
        world.addChild(label)
        label.run(.sequence([.group([.moveBy(x: 0, y: 0.6 * unit, duration: 0.6), .fadeOut(withDuration: 0.6)]), .removeFromParent()]))
    }

    /// 一次命中 ≥ 3 个目标时弹出 ×N（N ≥ 5 字号放大，PRD 8.6 ⑤）
    private func showHitCount(_ count: Int) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = L10n.text("combat_hit_count", ["count": String(count)])
        label.fontSize = count >= 5 ? 34 : 26
        label.fontColor = UIColor(hex: 0xF3E8D1)
        label.position = CGPoint(x: 0, y: 2.6 * unit)
        label.zPosition = 7
        label.name = "fx"
        world.addChild(label)
        label.setScale(0.6)
        label.run(.sequence([.scale(to: 1.1, duration: 0.12), .scale(to: 1, duration: 0.08), .wait(forDuration: 0.5),
                             .fadeOut(withDuration: 0.2), .removeFromParent()]))
    }

    static func weaponPath(_ form: Form) -> CGPath {
        // 朝 +x 方向；握柄在英雄中心附近
        switch form {
        case .needle: return CGPath(roundedRect: CGRect(x: 10, y: -2, width: 30, height: 4), cornerWidth: 2, cornerHeight: 2, transform: nil)
        case .broad: return CGPath(roundedRect: CGRect(x: 10, y: -6, width: 26, height: 12), cornerWidth: 4, cornerHeight: 4, transform: nil)
        case .great: return CGPath(roundedRect: CGRect(x: 8, y: -7, width: 40, height: 14), cornerWidth: 5, cornerHeight: 5, transform: nil)
        }
    }
}

/// 一个敌人的占位图形：Mushling 圆帽、Sprite 竖叶 + 护盾点、Shellback 横向甲壳 + 护甲数值；头顶 HP 条。
@MainActor
final class UnitNode: SKNode {
    private let body: SKShapeNode
    private let hpBar = SKShapeNode()
    private let hpWidth: CGFloat
    private var pips: [SKShapeNode] = []
    private var lastHP = -1, lastPips = -1, lastBurning = false

    init(kind: EnemyKind, radius: CGFloat, armor: Int, guardPips: Int) {
        switch kind {
        case .sprite:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: radius * 1.4))
            path.addQuadCurve(to: CGPoint(x: 0, y: -radius * 1.2), control: CGPoint(x: radius * 1.3, y: 0))
            path.addQuadCurve(to: CGPoint(x: 0, y: radius * 1.4), control: CGPoint(x: -radius * 1.3, y: 0))
            body = SKShapeNode(path: path)
            body.fillColor = UIColor(hex: 0x9BCB6A)
        case .shellback:
            body = SKShapeNode(ellipseOf: CGSize(width: radius * 2.4, height: radius * 1.4))
            body.fillColor = UIColor(hex: 0x7D6B5A)
        default:
            let path = CGMutablePath()
            path.addArc(center: CGPoint(x: 0, y: -radius * 0.1), radius: radius, startAngle: 0, endAngle: .pi, clockwise: false)
            path.addRect(CGRect(x: -radius * 0.35, y: -radius * 0.9, width: radius * 0.7, height: radius * 0.8))
            body = SKShapeNode(path: path)
            body.fillColor = UIColor(hex: 0xC9A26B)
        }
        body.strokeColor = UIColor(hex: 0x252A28)
        body.lineWidth = 2
        hpWidth = max(18, radius * 2)
        super.init()
        name = "enemy_\(kind.rawValue)"
        addChild(body)
        if kind == .shellback {
            let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
            label.text = "\(armor)"
            label.fontSize = 11
            label.fontColor = UIColor(hex: 0xD9E2DB)
            label.verticalAlignmentMode = .center
            addChild(label)
        }
        for i in 0..<guardPips {
            let pip = SKShapeNode(circleOfRadius: 3.2)
            pip.position = CGPoint(x: (CGFloat(i) - CGFloat(guardPips - 1) / 2) * 8, y: radius * 1.4 + 9)
            pip.strokeColor = UIColor(hex: 0x252A28)
            pip.lineWidth = 1
            addChild(pip)
            pips.append(pip)
        }
        hpBar.position = CGPoint(x: -hpWidth / 2, y: -radius * 1.4 - 6)
        hpBar.strokeColor = .clear
        addChild(hpBar)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("not used") }

    func update(hp: Int, maxHP: Int, guardPips: Int, burning: Bool) {
        if hp != lastHP {
            lastHP = hp
            let fraction = max(0, min(1, CGFloat(hp) / CGFloat(max(maxHP, 1))))
            hpBar.path = CGPath(rect: CGRect(x: 0, y: 0, width: hpWidth * fraction, height: 3), transform: nil)
            hpBar.fillColor = UIColor(hex: 0xE0675A)
        }
        if guardPips != lastPips {
            lastPips = guardPips
            for (i, pip) in pips.enumerated() {
                pip.fillColor = i < guardPips ? UIColor(hex: 0x6FA8FF) : UIColor(hex: 0x6FA8FF, alpha: 0.15)
            }
        }
        if burning != lastBurning {
            lastBurning = burning
            body.glowWidth = burning ? 3 : 0
            body.strokeColor = burning ? UIColor(hex: 0xF07F2E) : UIColor(hex: 0x252A28)
        }
    }
}
