import Foundation

/// M0 本地事件（PRD 0.5 最小事件 + 重建时间线所需的少量补充）。每行一条 JSON（JSONL），只写本地文件。
public struct LogEvent: Codable, Equatable, Sendable {
    public enum Name: String, Codable, Sendable {
        // PRD 0.5 最小事件
        case prototypeStart = "prototype_start"
        case forgeComplete = "forge_complete"
        case weaponSwap = "weapon_swap"
        case stageEnd = "stage_end"
        case hintShown = "hint_shown"
        case transferResult = "transfer_result"
        case freePlayChoice = "free_play_choice"
        case prototypeEnd = "prototype_end"
        // 补充：重建时间线与有效性检查
        case caseStart = "case_start"
        case firstInteractive = "first_interactive"
        case multiHit = "multi_hit"
        case forgeCancel = "forge_cancel"
        case technicalInterrupt = "technical_interrupt"
    }

    public var event: Name
    public var participantID: String
    public var buildMode = "prototype"
    public var configVersion: String
    public var caseID: String?
    public var seed: Int?
    public var elapsedMs: Int
    public var hintPolicy: String?
    // 装备（forge_complete / weapon_swap）
    public var b: Int?
    public var h: Int?
    public var r: Int?
    public var form: String?
    public var rune: String?
    // 结果（stage_end / transfer_result / prototype_end）
    public var attempts: Int?
    public var success: Bool?
    public var hintExposed: Bool?
    public var exitReason: String?
    /// 其余键值（原因、计数、提示 ID 等），按键排序输出
    public var detail: [String: String]?

    enum CodingKeys: String, CodingKey {
        case event, participantID = "participant_id", buildMode = "build_mode", configVersion = "config_version"
        case caseID = "case_id", seed, elapsedMs = "elapsed_ms", hintPolicy = "hint_policy"
        case b, h, r, form, rune, attempts, success, hintExposed = "hint_exposed", exitReason = "exit_reason", detail
    }

    public init(event: Name, participantID: String, configVersion: String, elapsedMs: Int) {
        self.event = event
        self.participantID = participantID
        self.configVersion = configVersion
        self.elapsedMs = elapsedMs
    }

    mutating func equip(_ w: Weapon) {
        b = w.blade
        h = w.hilt
        r = w.runePoints
        form = w.form.rawValue
        rune = w.rune?.rawValue
    }

    /// 一行 JSONL（键排序，省略空字段）
    public func jsonLine() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return String(decoding: try! encoder.encode(self), as: UTF8.self)
    }
}

/// 日志去处。App 写文件；测试收集到内存。
public protocol LogSink: AnyObject {
    func write(_ event: LogEvent)
}

public final class MemoryLogSink: LogSink {
    public private(set) var events: [LogEvent] = []
    public init() {}
    public func write(_ event: LogEvent) { events.append(event) }
}

/// 追加写入 JSONL 文件；每条立即写盘，进程被杀也只丢正在写的一行。
public final class FileLogSink: LogSink {
    public let url: URL
    private let handle: FileHandle?

    public init(url: URL) {
        self.url = url
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: nil)
        }
        handle = try? FileHandle(forWritingTo: url)
        _ = try? handle?.seekToEnd()
    }

    deinit { try? handle?.close() }

    public func write(_ event: LogEvent) {
        guard let data = (event.jsonLine() + "\n").data(using: .utf8) else { return }
        try? handle?.write(contentsOf: data)
        try? handle?.synchronize()
    }
}
