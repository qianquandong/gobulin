import Foundation

/// PRD 第 4、5 章与 tools/balance_sim.py 的常量。改数值时先改模拟器，再同步这里与参考夹具（tools/export_core_reference.py）。
public enum Rules {
    // MARK: 锻造（PRD 4.6）
    public static let bladeCap = 12
    public static let hiltCap = 6
    public static let runeCap = 5
    public static let hiltStep = 0.07
    public static let bladeStep = 0.10
    public static let temperStep = 0.01
    public static let temperCap = 10
    /// 平衡基准 Temper（TEMPER_BASELINE）；M0 隐藏节奏玩法，固定按此值锻造（PRD 0.2）
    public static let temperBaseline = 3
    /// 相邻两次有效敲击的最小间隔（PRD 4.4.3）
    public static let minStrikeInterval = 0.15

    // MARK: 符文（PRD 4.6.3）
    public static let runeChainRange = 3.0
    public static let sparkRatio = 0.6
    public static let emberRatio = 1.5
    public static let frostBonus = 0.3
    public static let frostSlow = 0.65
    public static let frostTime = 3.5
    public static let minDamageRatio = 0.2

    // MARK: 设施（PRD 7.3，M0 只用其中的 MD 与金属名）
    public static let furnaceMD = [10, 12, 14, 17, 20, 24, 28, 33, 39, 46]
    public static let anvilBudget = [6, 7, 8, 9, 10, 11, 12, 13, 14, 14]
    public static let barracksHP = [100, 118, 139, 164, 194, 229, 270, 319, 376, 444]

    /// 按 MD 反查锻造时的金属（武器名 `{metal} {form}`）
    public static func metal(forMD md: Int) -> Metal {
        guard let index = furnaceMD.firstIndex(of: md) else { return md < furnaceMD[0] ? .copper : .moonsilver }
        switch index + 1 {
        case 1...3: return .copper
        case 4...6: return .iron
        case 7...9: return .steel
        default: return .moonsilver
        }
    }
}

public enum Metal: String, Codable, CaseIterable, Sendable {
    case copper, iron, steel, moonsilver

    /// strings.md 的 ID：metal_copper …
    public var stringID: String { "metal_\(rawValue)" }
}

/// PRD 的取整规则：四舍五入（half up），即 Python `int(math.floor(x + 0.5))`。
@inline(__always)
public func rhu(_ x: Double) -> Int {
    Int((x + 0.5).rounded(.down))
}

/// 与 Python `round(x, 2)` 完全一致：对二进制精确值做正确舍入、恰好一半时取偶。
/// `%.2f` 的格式化在 Apple 与 glibc 上都按精确值正确舍入，结果与 Python 相同；
/// 不能用 `(x * 100).rounded() / 100`（乘法会引入新的舍入误差）。
public func pyRound2(_ x: Double) -> Double {
    Double(String(format: "%.2f", x))!
}

/// Python `math.ceil`
@inline(__always)
public func pyCeil(_ x: Double) -> Int {
    Int(x.rounded(.up))
}
