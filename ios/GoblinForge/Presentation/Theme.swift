import SwiftUI
import UIKit

/// 美术规范初稿色板（docs/art/README.md）与反馈颜色语言（PRD 8.6 ⑦）。正式 UI 素材（ui_forge_core，A0）到位前用于占位。
enum Theme {
    static let outline = Color(hex: 0x252A28)
    static let forest = Color(hex: 0x466854)
    static let moss = Color(hex: 0x809461)
    static let copper = Color(hex: 0xB87942)
    static let wood = Color(hex: 0x654836)
    static let steel = Color(hex: 0xD9E2DB)
    static let text = Color(hex: 0xF3E8D1)
    static let ember = Color(hex: 0xF07F2E)
    static let good = Color(hex: 0x7BC47F)
    static let bad = Color(hex: 0xE0675A)
    static let guardBlue = Color(hex: 0x6FA8FF)
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
    }
}
