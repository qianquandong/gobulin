# Claude 实现入口

这是《哥布林打铁铺 / Goblin Forge》的实现交接约定。当前仓库已有 PRD、Python 数值模拟器和经济回归用例；尚无 iOS 客户端。不要把文档中的验收标准当作已通过的测试结果。

## 职责与范围

- **Codex**：产品策划、数值规则、实验设计、美术方向、素材制作与美术验收；本次已交付规范，实际素材状态见清单。
- **Claude**：客户端代码、工程与构建、素材导入和程序动画、自动化测试、真机问题修复、打包与技术发布准备。
- **项目负责人（用户）**：提供 Mac/iPhone/账号、招募测试者并安排实际操作、处理商业与账号资料、里程碑取舍和最终发布。
- **现在只实现 M0**。M0 通过后，按里程碑开放 M1–M6；完整 P0 表不构成提前开发全部功能的指令。
- 无 Mac、签名、真机或测试者时，继续可做的逻辑与文档工作，把对应环节标为 `BLOCKED`；不得用编辑器、模拟器或 Python 结果代替真机验收。

## 阅读顺序

1. [交接指令](docs/production/claude-handoff.md) 与 [当前状态](docs/production/status.md)。
2. [两周原型唯一范围](docs/prd/00-two-week-prototype.md)。
3. [职责、阶段与协作流程](docs/production/README.md)、[任务清单](docs/production/backlog.md)。
4. [美术规范](docs/art/README.md)、[素材清单](docs/art/asset-manifest.md)。
5. [测试计划](docs/qa/test-plan.md)、[测试记录模板](docs/qa/test-run-template.md)。
6. 实现某模块前读 [PRD 对应章节](docs/prd/README.md)；接入平台功能前读 [App Store 流程](docs/release/app-store.md)。

## 实现约定

- M0 第 1 天记录引擎选择、精确版本、目标 OS、构建命令和真机安装路径；选择依据见 PRD 10.12。不要同时维护两套引擎。
- 战斗规则与渲染分离，20 Hz 固定逻辑步进；美术动作不能决定伤害、命中或结算时点。先做可玩的完整小闭环，再扩模块。
- 数值以 PRD 及 `tools/balance_sim.py` 的一致结果为依据。有冲突先提交最小复现与建议修订，不能静默改规则让测试变绿。
- 玩家可见文字全部英文，登记在 `docs/prd/strings.md`；开发文档、PR、测试结论用中文。
- 原型场景、固定状态实验、正式经济三种模式分开；迁移题强制关闭所有答案提示，禁用 debug 奖励污染指标。
- 素材用稳定 ID 引用。缺图可用尺寸/锚点一致的占位资源继续开发；写明缺口，不能将占位或生成概念图标记为最终资产。
- 只接入当前阶段需要的依赖。M0 不接广告、IAP、商业分析 SDK、云存档、联网配置。
- 每次逻辑变更附必要的边界/回归测试；每个可玩 PR 附实际运行方式、已测设备、证据与未测项。测试失败先修复或记录阻塞。
- 涉及存档、钱、奖励的操作要求原子性和重复执行不重复发放；阶段 M1 起按经济与恢复矩阵验证。
- 每个任务按 `TODO → DOING → VERIFY → DONE` 更新状态；有阻塞用 `BLOCKED` 并记录解除条件。不得仅凭编译通过标记 DONE。
- 证书、私钥、账户凭据、测试者联系方式、原始购买票据不得提交到公开仓库；GitHub 只保留去标识化证据与受控存储索引。

## 现有检查

```bash
python tools/check_prd.py
python -m unittest discover -s tools -p "test_*.py"
```

修改数值时还须重跑 `python tools/balance_sim.py all`，更新输出快照及相关 PRD。上述命令只证明文档/模拟器的一致性；客户端测试命令由 BOOT-01 落实并记录，不能预填不存在的命令或测试结果。

## 首次执行

从 [BOOT-01](docs/production/backlog.md) 开始，检查工作区、现有改动和 GitHub PR 状态，写出环境与最小构建证据。接着推进 M0-01–M0-07。每次交接更新 `docs/production/status.md`，告诉负责人：完成什么、如何复现、哪里未测、下一步是谁执行。
