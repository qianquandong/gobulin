import Foundation

/// 玩家可见英文文案：只来自 docs/prd/strings.md 导出的 strings.json（tools/export_strings.py）。
/// 占位符写作 `{name}`；复数用 `id#one` / `id#other`，按 CLDR 英语规则（1 → one，其余 → other）选择。
enum L10n {
    private static let table: [String: String] = {
        guard let url = Bundle.main.url(forResource: "strings", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let table = try? JSONDecoder().decode([String: String].self, from: data) else { return [:] }
        return table
    }()

    static func has(_ id: String) -> Bool { table[id] != nil }

    /// 缺失的 ID 在 Debug 下显示为 `‹id›` 便于发现；不回退到中文或硬编码文本。
    static func text(_ id: String, _ arguments: [String: String] = [:]) -> String {
        guard var value = table[id] else { return "‹\(id)›" }
        for (key, replacement) in arguments {
            value = value.replacingOccurrences(of: "{\(key)}", with: replacement)
        }
        return value
    }

    static func plural(_ id: String, count: Int, _ arguments: [String: String] = [:]) -> String {
        var arguments = arguments
        arguments["count"] = String(count)
        return text("\(id)#\(count == 1 ? "one" : "other")", arguments)
    }
}
