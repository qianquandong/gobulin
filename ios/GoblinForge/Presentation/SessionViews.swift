import GoblinForgeCore
import SwiftUI

/// 根视图：主持人设置 → 试玩 → 事后解释 → 结束。
struct AppRootView: View {
    @ObservedObject var controller: PrototypeController

    var body: some View {
        ZStack {
            Theme.wood.ignoresSafeArea()
            switch controller.screen {
            case .setup: HostSetupView(controller: controller)
            case .play: PlayView(controller: controller)
            case .interview: InterviewView(controller: controller)
            case .done: DoneView(controller: controller)
            }
            #if DEBUG
            DebugProbeView(live: controller.live)
            #endif
        }
        .foregroundStyle(Theme.text)
    }
}

/// 主持人设置：匿名参与者编号与迁移题顺序（PRD 0.4 题序交替）。崩溃后可从当前块重新开始。
struct HostSetupView: View {
    @ObservedObject var controller: PrototypeController

    var body: some View {
        VStack(spacing: 18) {
            Text(L10n.text("app_name"))
                .font(.system(size: 30, weight: .heavy, design: .rounded))
            Text(L10n.text("proto_host_title"))
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .accessibilityIdentifier("host.title")
            TextField(L10n.text("proto_participant"), text: $controller.participantID)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .padding(12)
                .background(Theme.outline.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))
                .accessibilityIdentifier("host.participant")
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.text("proto_order")).font(.subheadline)
                HStack(spacing: 10) {
                    choice("proto_order_a", selected: controller.orderIndex == 0) { controller.orderIndex = 0 }
                    choice("proto_order_b", selected: controller.orderIndex == 1) { controller.orderIndex = 1 }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                controller.startSession()
            } label: {
                Text(L10n.text("proto_start")).frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(controller.participantID.trimmingCharacters(in: .whitespaces).isEmpty)
            .accessibilityIdentifier("host.start")
            if let resume = controller.resumableCase {
                Button {
                    controller.startSession(resume: true)
                } label: {
                    Text(L10n.text("proto_resume", ["case": caseLabel(resume)])).frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityIdentifier("host.resume")
            }
        }
        .padding(24)
        .frame(maxWidth: 420)
    }

    private func caseLabel(_ id: String) -> String {
        let index = (controller.config.cases.firstIndex { $0.id == id } ?? 0) + 1
        return "\(index)/\(controller.config.cases.count)"
    }

    private func choice(_ key: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(L10n.text(key)).frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(ChoiceButtonStyle(selected: selected))
        .accessibilityIdentifier("host.\(key)")
    }
}

/// 两道迁移题之后：主持人照读开放式问题，再给中性邀请（PRD 0.4）。App 不显示任何答案。
struct InterviewView: View {
    @ObservedObject var controller: PrototypeController

    var body: some View {
        VStack(spacing: 20) {
            Text(L10n.text("proto_interview")).font(.headline)
            Text(L10n.text("prototype_reason"))
                .font(.system(.title2, design: .rounded).weight(.bold))
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("interview.reason")
            Text(L10n.text("prototype_continue"))
                .font(.body)
                .multilineTextAlignment(.center)
                .opacity(0.85)
            HStack(spacing: 12) {
                Button { controller.freePlayChoice(continuePlaying: false) } label: {
                    Text(L10n.text("proto_finish")).frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityIdentifier("interview.finish")
                Button { controller.freePlayChoice(continuePlaying: true) } label: {
                    Text(L10n.text("proto_free_play")).frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityIdentifier("interview.continue")
            }
        }
        .padding(24)
    }
}

struct DoneView: View {
    @ObservedObject var controller: PrototypeController

    var body: some View {
        VStack(spacing: 20) {
            Text(L10n.text("proto_done"))
                .font(.system(.title, design: .rounded).weight(.bold))
                .accessibilityIdentifier("done.title")
            if let url = controller.logURL {
                ShareLink(item: url) {
                    Text(L10n.text("proto_export")).frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityIdentifier("done.export")
            }
            Button { controller.backToSetup() } label: {
                Text(L10n.text("btn_ok")).frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityIdentifier("done.ok")
        }
        .padding(24)
    }
}

/// 主持人菜单（战场右上角长按 1.5 s 打开）：跳过当前题、导出日志、结束本场。
struct HostMenuView: View {
    @ObservedObject var controller: PrototypeController

    var body: some View {
        VStack(spacing: 14) {
            Text(L10n.text("proto_host_menu")).font(.headline)
            Text("\(controller.participantID) · \(controller.run?.caseNumber ?? 0)/\(controller.run?.caseCount ?? 0)")
                .font(.subheadline.monospacedDigit())
            Button(role: .destructive) { controller.hostSkip() } label: {
                Text(L10n.text("proto_skip")).frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityIdentifier("host.skip")
            if let url = controller.logURL {
                ShareLink(item: url) { Text(L10n.text("proto_export")).frame(maxWidth: .infinity, minHeight: 44) }
                    .buttonStyle(SecondaryButtonStyle())
            }
            Button(role: .destructive) { controller.endSession() } label: {
                Text(L10n.text("proto_end")).frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityIdentifier("host.end")
            Button { controller.showHostMenu = false } label: {
                Text(L10n.text("btn_close")).frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(24)
        .foregroundStyle(Theme.text)
        .background(Theme.wood.ignoresSafeArea())
        .presentationDetents([.medium])
    }
}

// MARK: 按钮样式（ui_forge_core 正式素材到位前的占位）

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(Theme.outline)
            .background(Theme.copper.opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.35),
                        in: RoundedRectangle(cornerRadius: 12))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundStyle(Theme.text.opacity(isEnabled ? 1 : 0.4))
            .background(Theme.outline.opacity(configuration.isPressed ? 0.6 : 0.4), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct ChoiceButtonStyle: ButtonStyle {
    let selected: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundStyle(selected ? Theme.outline : Theme.text)
            .background(selected ? Theme.steel : Theme.outline.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(selected ? Theme.copper : .clear, lineWidth: 2))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

#if DEBUG
/// UI 测试读取的调试探针；只在 Debug 构建存在（CI 检查 Prototype 二进制中没有 “debug.probe”）。
struct DebugProbeView: View {
    @ObservedObject var live: LiveStatus
    var body: some View {
        Text(live.debugProbe)
            .font(.system(size: 1))
            .opacity(0.02)
            .frame(width: 1, height: 1)
            .accessibilityIdentifier("debug.probe")
            .allowsHitTesting(false)
    }
}
#endif
