import GoblinForgeCore
import SpriteKit
import UIKit
import SwiftUI

/// BOOT-01 空壳：上半屏 SpriteKit 战场（占位英雄），下半屏标题与开始提示。
/// 验证 SwiftUI + SpriteKit + 纯 Swift 规则包能一起编译、启动；M0-03 起替换为原型流程。
struct BootView: View {
    @State private var scene = PlaceholderBattleScene(size: CGSize(width: 390, height: 380))

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                SpriteView(scene: scene)
                    .frame(height: proxy.size.height * 0.45)
                    .accessibilityIdentifier("battlefield")
                VStack(spacing: 12) {
                    Spacer()
                    Text(L10n.text("app_name"))
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .accessibilityIdentifier("title.name")
                    Text(L10n.text("title_tap_to_start"))
                        .font(.system(.title3, design: .rounded))
                        .accessibilityIdentifier("title.tap")
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(Palette.text)
                .background(Palette.workshop)
            }
            .ignoresSafeArea(edges: .top)
        }
        .background(Palette.workshop.ignoresSafeArea())
    }
}

/// 美术规范初稿色板（docs/art/README.md）；正式素材到位前用于占位。
enum Palette {
    static let outline = Color(red: 0x25 / 255, green: 0x2A / 255, blue: 0x28 / 255)
    static let forest = Color(red: 0x46 / 255, green: 0x68 / 255, blue: 0x54 / 255)
    static let moss = Color(red: 0x80 / 255, green: 0x94 / 255, blue: 0x61 / 255)
    static let copper = Color(red: 0xB8 / 255, green: 0x79 / 255, blue: 0x42 / 255)
    static let workshop = Color(red: 0x65 / 255, green: 0x48 / 255, blue: 0x36 / 255)
    static let steel = Color(red: 0xD9 / 255, green: 0xE2 / 255, blue: 0xDB / 255)
    static let text = Color(red: 0xF3 / 255, green: 0xE8 / 255, blue: 0xD1 / 255)
}

/// 占位战场：森林底色 + 英雄圆（碰撞半径 0.5u，1u = 32pt）。
final class PlaceholderBattleScene: SKScene {
    override func didMove(to view: SKView) {
        backgroundColor = UIColor(Palette.forest)
        scaleMode = .resizeFill
        removeAllChildren()
        let hero = SKShapeNode(circleOfRadius: 16)
        hero.fillColor = UIColor(Palette.copper)
        hero.strokeColor = UIColor(Palette.outline)
        hero.lineWidth = 3
        hero.position = CGPoint(x: size.width / 2, y: size.height / 2)
        hero.name = "char_pip"
        addChild(hero)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        childNode(withName: "char_pip")?.position = CGPoint(x: size.width / 2, y: size.height / 2)
    }
}
