# ADR-001：引擎与技术栈（BOOT-01）

状态：**已决定**（2026-10-11，Claude）。依据 [PRD 10.12](../../prd/10-content-art-tech.md#1012-引擎与技术栈-待定)。变更须新写 ADR 并说明迁移成本，不同时维护两套引擎。

## 决定

| 项 | 选择 / 精确版本 | 说明 |
|---|---|---|
| 引擎 | **SpriteKit + SwiftUI（Apple 原生）** | 战场与锻造台动画用 SpriteKit，面板/按钮/文字用 SwiftUI |
| 规则层 | 纯 Swift 包 `Packages/GoblinForgeCore`（swift-tools 5.10，iOS 17 / macOS 14） | 不依赖 UIKit/SpriteKit；Linux 上可直接 `swift test` |
| 语言 | Swift 6.2.4 编译器，Swift 5 语言模式 | 与 CI runner 的 Xcode 一致 |
| IDE / SDK | Xcode 26.3（17C529），iOS SDK 26.2 | CI：GitHub Actions `macos-15` 镜像。**负责人的 Mac：待记录**（运行 `bash ci/record-environment.sh`） |
| 最低系统 | iOS 17.0；仅 iPhone；仅竖屏 | 覆盖 A12（XR/XS）档设备；构建 SDK 与最低运行系统是两件事 |
| 工程生成 | XcodeGen 2.45.4，`ios/project.yml` → 提交生成的 `ios/GoblinForge.xcodeproj` | CI 重新生成并比对，防止手改漂移 |
| 配置 | `Debug`（调试入口、测试启动参数）/ `Prototype`（Release 优化，M0 测试包） | 调试入口只编译进 Debug，CI 检查 Prototype 二进制 |
| 第三方依赖 | **无** | M0 不接广告、IAP、商业分析 SDK、云存档、联网配置 |
| Bundle ID | 占位 `com.example.GoblinForge`，Team 为空 | 真机签名前由负责人提供，不在仓库伪造 |

## 理由

1. **只做 iPhone**（PRD 0.2：一台团队现有 iPhone、竖屏单手），SpriteKit 不需要额外运行时，包体和冷启动开销最小。
2. **构建条件**：当前执行环境没有本地 Mac，iOS 构建与模拟器测试依赖 GitHub Actions 的 macOS runner。原生工程只需要 Xcode；Unity 需要编辑器许可证与账号凭据进入 CI，M0 第 1 天无法满足。
3. **规则与渲染分离**（PRD 10.12、CLAUDE.md）：纯 Swift 规则包可以在 Linux 容器和 macOS 上无界面运行，`tools/balance_sim.py` 的公式与 20 Hz 战斗可逐条比对（含 Python `random` 的确定性种子）。
4. **代价**：以后若做 Android 需要重写表现层；规则层是纯 Swift，移植成本只在表现层。PRD 10.12 已列出此风险；M0 不为此预留抽象。

## 构建与安装路径

| 环节 | 命令 / 路径 | 当前状态 |
|---|---|---|
| 规则包测试 | `swift test --package-path Packages/GoblinForgeCore` | Linux（Docker `swift:6.2`）与 CI macOS 可运行 |
| 生成工程 | `xcodegen generate --spec ios/project.yml` | 可运行 |
| 模拟器测试 | `xcodebuild -project ios/GoblinForge.xcodeproj -scheme GoblinForge -destination 'platform=iOS Simulator,name=iPhone 17' test` | CI 可运行 |
| 真机安装 | 负责人 Mac：Xcode 打开工程 → Signing 选择个人/团队账号 → 连接 iPhone → Run；或用开发者账号导出 Ad Hoc/TestFlight | **BLOCKED**：需要负责人的 Mac、iPhone 型号/系统、Apple 账号；见 [构建说明](../build.md#真机安装) |

完整步骤见 [构建说明](../build.md)。
