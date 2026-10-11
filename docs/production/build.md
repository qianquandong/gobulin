# 构建、测试与安装说明

从全新 checkout 构建和测试 iOS 客户端。引擎与版本决定见 [ADR-001](decisions/engine.md)。凭据不进仓库。

## 环境要求

- macOS + Xcode 26.x（CI 使用 Xcode 26.3 / iOS SDK 26.2）；部署目标 iOS 17.0
- XcodeGen 2.45.4（`brew install xcodegen` 后用 `xcodegen --version` 核对）
- Python 3.11+（PRD 检查与文案导出）
- 只验证规则层时：任何装有 Swift 6.2 的机器，或 Docker 镜像 `swift:6.2`

## 一次完整验证（仓库根目录）

```bash
python3 tools/check_prd.py
python3 -m unittest discover -s tools -p "test_*.py"
python3 tools/export_strings.py --check
swift test --package-path Packages/GoblinForgeCore
xcodegen generate --spec ios/project.yml
xcodebuild -project ios/GoblinForge.xcodeproj -scheme GoblinForge \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

没有 Mac 时，规则层可以这样测：

```bash
docker run --rm -v "$PWD:/gobulin" -w /gobulin swift:6.2 swift test --package-path Packages/GoblinForgeCore
```

## 修改工程或文案

- 新增/删除源文件或改 target 设置：改 `ios/project.yml`，重新运行 `xcodegen generate --spec ios/project.yml` 并提交生成的工程。CI 会重新生成并比对。
- 玩家可见英文：先登记到 [strings.md](../prd/strings.md)，再运行 `python3 tools/export_strings.py` 生成 `ios/GoblinForge/Resources/strings.json`。客户端只用 `L10n.text` / `L10n.plural` 取文案。

## CI

| 工作流 | 运行环境 | 内容 |
|---|---|---|
| `validate.yml` | Ubuntu，Python 3.11 / 3.14 | PRD 一致性、经济回归、文案表同步 |
| `ios.yml` | Ubuntu `swift:6.2` 容器 + `macos-15` | 规则包测试（Linux 与 macOS）、工程漂移检查、模拟器单元/UI 测试（标准 + 小屏最旧运行时）、截图、Prototype 配置无签名编译与二进制检查、环境记录 |

`ios.yml` 的证据（环境记录、截图、UI 附件、日志、xcresult）作为 Actions artifact 保存。它们来自 GitHub 托管 runner 与模拟器，**不是真机证据**。只改 `docs/**` 或根目录 `*.md` 时 `ios.yml` 不运行。

## M0 原型怎么跑

1. 冷启动进入主持人设置页：输入匿名参与者编号（不填姓名），选择迁移题顺序 `A then B` / `B then A`（逐人交替），点 Start。
2. 流程：首分钟演示 → 3 个学习题 → 2 道迁移题 → 事后解释页（主持人照读 `prototype_reason` 与 `prototype_continue`）→ 参与者选择 Finish 或 Keep playing（最多 3 分钟）。
3. 主持人菜单：战场右上角长按 1.5 s。可跳过当前题（学习超时等，记 `host_skip`，不计主指标）、导出日志、结束本场。
4. 崩溃或被杀后重开：设置页出现 `Restart n/6`，从中断的测试块重新开始，日志追加到同一文件并记 `technical_interrupt`。
5. 日志：`Documents/logs/<编号>-<时间>.jsonl`，每行一个事件（字段见 PRD 0.5）。结束页或主持人菜单可 Export log；也可在 Mac 的 Finder 设备页或“文件” App 中取出。日志不含姓名与联系方式。
6. 场景配置：`config/prototype/m0_cases.json`（打包进 App）。改数值后运行 `python3 tools/prototype_cases.py` 与 `--write-reference`（在 Linux 上），见 [校准发现](m0-04-calibration-findings.md)。

Debug 构建的测试参数（Prototype 配置中不存在，CI 检查二进制）：`-gf-case <case_id>` 跳过设置页直接进入某题，`-gf-participant <id>`，`-gf-rack <b>/<h>/<r>` 替换起始武器。

## 真机安装

**当前状态：BLOCKED**——需要负责人提供 Mac、iPhone（型号/系统）和 Apple 账号。M0 只需一台团队现有 iPhone（PRD 0.2）。

1. 在 Mac 上 checkout 当前分支，运行一次 [完整验证](#一次完整验证仓库根目录)，并运行 `bash ci/record-environment.sh build/environment.md` 记录环境（输出已脱敏机器名）。
2. Xcode 打开 `ios/GoblinForge.xcodeproj`，选中 target `GoblinForge` → Signing & Capabilities：勾选 Automatically manage signing，Team 选负责人的账号；Bundle Identifier 改为负责人确定的值（例如反向域名 + `.goblinforge`）。不要把 Team 或证书提交到仓库。
3. 用数据线连接 iPhone，开启开发者模式（设置 → 隐私与安全性 → 开发者模式），在 Xcode 里选择该设备，Scheme 选 `GoblinForge`，Run。M0 测试包用 Product → Scheme → Edit Scheme → Run → Build Configuration 选 `Prototype`。
4. 首次安装用个人团队时，在 iPhone 设置 → 通用 → VPN 与设备管理中信任开发者。
5. 记录：iPhone 型号、iOS 版本、Xcode 版本、commit、安装方式、冷启动截图，填到 [状态板](status.md) 与测试记录。

外部 12 人测试若改用 TestFlight，需要 Developer Program 与提前审核，按 [上线手册](../release/app-store.md) 执行。
