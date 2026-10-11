import Foundation
import XCTest

/// 仓库根目录下的文件（测试从源码树读取共享夹具，不复制到包内）。
func repoFile(_ relative: String, file: StaticString = #filePath) -> URL {
    URL(fileURLWithPath: "\(file)")
        .deletingLastPathComponent()   // GoblinForgeCoreTests
        .deletingLastPathComponent()   // Tests
        .deletingLastPathComponent()   // GoblinForgeCore
        .deletingLastPathComponent()   // Packages
        .deletingLastPathComponent()   // repo root
        .appendingPathComponent(relative)
}

/// 用 JSONDecoder 解析通用 JSON。不能用 JSONSerialization：Linux 版把部分 17 位有效数字的小数
/// 解析错最后一位（2026-10-11 实测 “-6.649849426882663” → …662），会让逐位比对误报。
private enum JSONValue: Decodable {
    case null, bool(Bool), number(Double), string(String), array([JSONValue]), object([String: JSONValue])

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null }
        else if let b = try? c.decode(Bool.self) { self = .bool(b) }
        else if let d = try? c.decode(Double.self) { self = .number(d) }
        else if let s = try? c.decode(String.self) { self = .string(s) }
        else if let a = try? c.decode([JSONValue].self) { self = .array(a) }
        else { self = .object(try c.decode([String: JSONValue].self)) }
    }

    var any: Any {
        switch self {
        case .null: return NSNull()
        case let .bool(b): return b
        case let .number(d): return d
        case let .string(s): return s
        case let .array(a): return a.map(\.any)
        case let .object(o): return o.mapValues(\.any)
        }
    }
}

/// tools/reference/core_reference.json（由 tools/export_core_reference.py 从 balance_sim.py 生成）
enum Reference {
    static let json: [String: Any] = {
        let data = try! Data(contentsOf: repoFile("tools/reference/core_reference.json"))
        return try! JSONDecoder().decode(JSONValue.self, from: data).any as! [String: Any]
    }()

    static func rows(_ key: String) -> [[String: Any]] {
        json[key] as! [[String: Any]]
    }

    static var math: [String: Any] { json["math"] as! [String: Any] }
}

extension Dictionary where Key == String, Value == Any {
    func int(_ key: String) -> Int? { (self[key] as? Double).map { Int($0) } }
    func double(_ key: String) -> Double? { self[key] as? Double }
    func string(_ key: String) -> String? { self[key] as? String }
    func bool(_ key: String) -> Bool? { self[key] as? Bool }
    func doubles(_ key: String) -> [Double] { (self[key] as? [Any] ?? []).compactMap { $0 as? Double } }
    func ints(_ key: String) -> [Int] { doubles(key).map { Int($0) } }
}
