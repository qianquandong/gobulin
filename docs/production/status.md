# 当前项目状态

状态快照：2026-10-11（Claude 更新，BOOT-01 与 M0-01–M0-05 客户端部分之后）。此表是实际状态，后续由当班执行者持续更新。**当前阶段：M0 进行中——可玩原型已在模拟器跑通；真机、场景校准与真人测试未发生；尚无玩法通过或发布放行结论。**

## 已有成果与尚未发生的工作

| 项 | 实际状态 | 证据 / 下一步 |
|---|---|---|
| PRD v0.2、两周原型和经济修订 | 已写入 PR，待合并 | [PR #1](https://github.com/qianquandong/gobulin/pull/1)；分支 `codex/prd-two-week-prototype`。Claude 的实现分支都基于它 |
| Python 数值模拟器与经济回归 | 可运行；8 条经济测试 | `tools/balance_sim.py`、`tools/test_economy_rules.py` |
| 引擎 ADR | 已决定 | [ADR-001](decisions/engine.md)：SpriteKit + SwiftUI，Xcode 26.3 / iOS SDK 26.2（CI），部署 iOS 17.0，仅 iPhone 竖屏 |
| 客户端规则层 | 自动检查通过 | `Packages/GoblinForgeCore`：武器公式 3572 把、E1–E7、20 关 × 代表构筑 × 3 种子 453 场与模拟器逐场一致（Linux 逐位；Apple 平台输赢一致） |
| 可玩原型（模拟器） | VERIFY | 首分钟 → 3 学习题 → 2 迁移题 → 解释 → 自由继续；锻造、武器架换装、Retry、失败报告、主持人菜单、JSONL 日志；CI UI 测试与截图。**真机 NOT RUN** |
| 可安装 iOS 包 | BLOCKED | Prototype 配置无签名真机架构编译通过并检查二进制；签名安装需要负责人的 Mac / iPhone / Apple 账号 |
| 美术素材与音频 | PLANNED | 客户端用带资源 ID 的程序占位（节点名即 asset_id）；敲击音为程序合成占位。需求见下文 |
| M0 迁移题多解验证 | FAIL（草稿） | `python tools/prototype_cases.py`：5 题中 4 题不满足 0.3，详见 [校准发现](m0-04-calibration-findings.md)，等 Codex 定案 |
| 3 人内部测试 / 12 人外测 | NOT RUN | 依赖真机 build 与冻结配置；负责人安排招募/执行 |
| 真机性能、购买/广告/iCloud 测试 | NOT RUN | M0 不涉及购买/广告/iCloud |
| Apple 账号/签名/商店记录 | 待确认 | 负责人提供；仓库只有占位 Bundle ID `com.example.GoblinForge`，Team 为空 |
| TestFlight / App Store 审核 / 线上发布 | NOT STARTED | 按阶段闸门与上线手册执行 |

## 任务状态（M0）

| 任务 | 状态 | 证据 | 未完成部分 / 解除条件 |
|---|---|---|---|
| BOOT-01 | VERIFY（真机 BLOCKED） | ADR、工程、CI；模拟器冷启动截图；Release 二进制检查 PASS | 负责人 Mac 环境记录、iPhone 型号/系统、签名安装与真机截图 |
| M0-01 | VERIFY | 规则包测试（Linux/macOS）；UI 测试：Blade 3→4 预警与形态、Undo/Reset/Cancel 无残留 | 真机手感、误触 NOT RUN |
| M0-02 | VERIFY | 453 场与模拟器一致；护甲/护盾/灼烧/换装时点单例；场景截图 | 真机帧率与可读性 NOT RUN；占位图形待 A0 |
| M0-03 | VERIFY | UI 测试：首分钟锻 Broad 并真实横扫 ≥ 3；学习/迁移失败报告的提示差异 | 单手真机操作、首分钟实际用时 NOT RUN |
| M0-04 | BLOCKED | 场景工具与客户端一致；当前配置 4/5 不满足 0.3 | Codex 定数量/方向/成长关卡并冻结；之后在冻结 build 上真机复核 |
| M0-05 | VERIFY | 日志字段与流程单测；迁移题提示开关单测与 UI 测试 | 真机一人完整跑一遍并从 JSONL 重建时间线 NOT RUN |
| M0-06 | BLOCKED | — | 真机 build、冻结配置、3 名内部测试者 |
| M0-07 | BLOCKED | — | M0-06 完成、12 名新用户、主持人 |

“DONE” 需要该阶段的真机证据（[完成定义](README.md#完成定义)），因此目前最多到 VERIFY。本轮测试记录：[2026-10-11 M0 CI 38166409004](../qa/runs/2026-10-11-M0-ci-38166409004.md)（逻辑与模拟器 10 项 PASS，T-04 配置未校准 FAIL，真机 BLOCKED）。

## 环境与外部依赖

| 项目 | 当前信息 | 谁落实 / 最晚时点 |
|---|---|---|
| CI 构建机 | GitHub `macos-15`：macOS 15.7.9、Xcode 26.3（17C529）、iOS SDK 26.2、Swift 6.2.4、XcodeGen 2.45.4；模拟器 iPhone 17 / iOS 26.2 与 iPhone SE / iOS 18.5 | Claude；已记录 |
| 负责人的 Mac/macOS/Xcode | 待确认（运行 `bash ci/record-environment.sh build/environment.md`） | 负责人；真机安装前 |
| M0 iPhone 型号/OS/安装方式 | 待确认（[真机安装步骤](build.md#真机安装)） | 负责人 + Claude；D1 |
| Developer Program/团队角色 | 待确认 | 负责人；远程分发/上传之前 |
| M0 主持人、12 名新用户及档期 | 待安排 | 负责人；D1–D5 预约 |
| 最低支持设备及云存档双机 | 待安排 | 负责人；相应 M5/M6 验收前 |
| 最终名称、支持邮箱、隐私页托管 | 待定 | 负责人；名称 M3 前 |
| 音频授权/人工制作与测试预算 | 待定 | Codex 给需求，负责人决定；采购前 |

## 下一步

| 顺序 | 任务 | 责任人 | 状态 |
|---|---|---|---|
| 1 | 审阅并合并 PR #1 与 Claude 的堆叠 PR（BOOT-01 → M0-01 → M0-02 → M0-03） | 负责人 | TODO |
| 2 | 提供 Mac / iPhone / 账号；按 [真机安装](build.md#真机安装) 装 Prototype 配置并回传截图与系统版本 | 负责人 | TODO |
| 3 | 按 [校准发现](m0-04-calibration-findings.md) 定案学习题与迁移题，冻结 `config/prototype/m0_cases.json` | Codex | TODO |
| 4 | A0 占位素材（见下）；Claude 按资源 ID 导入 | Codex → Claude | TODO |
| 5 | 冻结配置后：真机冒烟、日志时间线复核、3 人内部排障（M0-06） | Claude + 负责人 | BLOCKED（1–3） |
| 6 | 12 人外测与决策（M0-07） | 负责人 + Codex + Claude | BLOCKED（5） |

## 美术 / 策划请求（转交 Codex）

客户端接口（BOOT-01 填写）：SpriteKit 中 1u = 32 pt（战场 12u × 9u，按屏幕缩放）；节点名即 asset_id，替换占位只需提供同 ID 的图片。

| asset_id | 客户端当前占位与用途 | 需要的规格 |
|---|---|---|
| `char_pip` | 铜色圆（碰撞半径 0.5u = 16 pt），居中、只转向 | 分层占位，武器挂点；朝 +x 方向时的握柄位置 |
| `char_gristle` | 未绘制，只在气泡里显示名字 | 气泡旁的小头像或半身（M0 可选） |
| `weapon_needle` / `weapon_broad` / `weapon_great` | 绕英雄中心旋转的长方形（长 30/26/40 pt） | 刀身、柄、Ember 标志分层；锚点 (0.5, 0.18)；缩到 30–40 pt 仍能分辨三形态 |
| `enemy_mushling` / `enemy_sprite` / `enemy_shellback` | 圆帽 / 竖叶 + 3 颗可数护盾点 / 横向甲壳 + 护甲数字；头顶 HP 条 | 静态占位，护盾点与甲壳状态独立一层 |
| `bg_mossy_hollow`、`bg_workshop` | 纯色 #466854 / #654836 | 上半屏战场底与下半屏工坊底，按安全区可裁切 |
| `ui_forge_core` | 三区域按钮（Blade 82 pt、Rune 64 pt、Hilt 64 pt，宽 150 pt，8 pt 间隔），符文选择、对比面板、四个底部按钮 | 区域与按钮底图、状态层（可敲 / Max / 不可用） |
| `fx_form_outline_*` | 程序轮廓：Needle 线、Broad 150° 扇形、Great 圆环；常规 0.15 s、新武器前 3 击 0.3 s 加粗 | 线宽、明暗、衰减参考（不交付预烘焙扇形） |
| `fx_hit_count` | ×N 文字，N ≥ 5 放大 | 字体/描边参考 |
| `sfx_hammer_*` | 程序合成：普通敲击（880 Hz 泛音）、跨形态（520 Hz）、交付（660 Hz） | 可授权的敲击、整形、交付音，附来源记录 |

策划决定：见 [校准发现](m0-04-calibration-findings.md) 第 1–5 条与“客户端已经按以下理解实现”。

## 每次交接更新格式

```text
时间 / 执行人:
当前阶段与任务:
已完成（PR、commit、build、配置）:
实际检查与证据:
未测项和原因:
阻塞与解除条件（责任人）:
美术/策划请求（asset_id 或 PRD 小节）:
下一步:
是否达到阶段闸门及决定记录:
```

若 PR #1 已合并，更新上述链接/基线状态；保留历史报告，不覆盖旧失败记录。只有实际执行并留证才从 TODO 改为 DONE。
