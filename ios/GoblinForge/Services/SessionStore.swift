import Darwin
import Foundation

/// 原型不保存游戏进度（PRD 0.2），只记住“当前在哪个测试块”，以便崩溃/重启后从该块重新开始并标记技术中断。
enum SessionStore {
    private static let defaults = UserDefaults.standard
    private static let keyParticipant = "proto.participant"
    private static let keyOrder = "proto.order"
    private static let keyCase = "proto.activeCase"
    private static let keyLog = "proto.logFile"

    static var participant: String? { defaults.string(forKey: keyParticipant) }
    static var order: Int { defaults.integer(forKey: keyOrder) }
    static var logFile: String? { defaults.string(forKey: keyLog) }

    static var activeCase: String? {
        get { defaults.string(forKey: keyCase) }
        set { defaults.set(newValue, forKey: keyCase) }
    }

    static func begin(participant: String, order: Int, logFile: String) {
        defaults.set(participant, forKey: keyParticipant)
        defaults.set(order, forKey: keyOrder)
        defaults.set(logFile, forKey: keyLog)
    }

    static func clear() {
        defaults.removeObject(forKey: keyCase)
        defaults.removeObject(forKey: keyLog)
    }
}

/// 日志文件：Documents/logs/<参与者>-<时间>.jsonl。Info.plist 开启了文件共享，可在“文件” App 或 Finder 中取出。
enum LogFiles {
    static var directory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("logs", isDirectory: true)
    }

    static func url(for participant: String, existing: String?) -> URL {
        if let existing { return directory.appendingPathComponent(existing) }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let safe = participant.filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
        return directory.appendingPathComponent("\(safe.isEmpty ? "participant" : safe)-\(formatter.string(from: Date())).jsonl")
    }
}

/// 冷启动耗时：进程创建到首个可交互画面（PRD 0.5 单列冷启动）
enum AppLaunch {
    static func millisecondsSinceProcessStart() -> Int {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        guard sysctl(&mib, u_int(mib.count), &info, &size, nil, 0) == 0 else { return -1 }
        let start = info.kp_proc.p_starttime
        let started = Double(start.tv_sec) + Double(start.tv_usec) / 1_000_000
        return Int((Date().timeIntervalSince1970 - started) * 1000)
    }
}
