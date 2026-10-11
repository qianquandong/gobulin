import GoblinForgeCore
import SwiftUI

@main
struct GoblinForgeApp: App {
    @StateObject private var controller = PrototypeController(config: PrototypeController.loadBundledConfig())

    var body: some Scene {
        WindowGroup {
            AppRootView(controller: controller)
                .onAppear {
                    #if DEBUG
                    let options = LaunchOptions(arguments: ProcessInfo.processInfo.arguments)
                    if let caseID = options.caseID, controller.screen == .setup {
                        controller.debugStart(caseID: caseID, participant: options.participant ?? "UITEST")
                    }
                    #endif
                }
        }
    }
}

#if DEBUG
/// 调试启动参数（只编译进 Debug；CI 检查 Prototype 二进制中不存在）：
/// - `-gf-case <case_id>`：跳过主持人页直接进入某场景（UI 测试与截图）
/// - `-gf-participant <id>`：配合上一条使用的参与者编号（默认 UITEST）
struct LaunchOptions {
    var caseID: String?
    var participant: String?

    init(arguments: [String]) {
        func value(after flag: String) -> String? {
            guard let i = arguments.firstIndex(of: flag), i + 1 < arguments.count else { return nil }
            return arguments[i + 1]
        }
        caseID = value(after: "-gf-case")
        participant = value(after: "-gf-participant")
    }
}
#endif
