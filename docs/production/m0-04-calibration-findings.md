# M0-04 场景校准：现状与需要 Codex 决定的事项

2026-10-11，Claude。范围：[第 0 章 0.3](../prd/00-two-week-prototype.md#03-固定配置与内容准备) 的学习题与迁移题。**本文只给可复现的数据与可选方向，不改数值**；数值由 Codex 定案并在第 6 天前冻结（[backlog M0-04](backlog.md)）。

## 工具与复现

| 用途 | 命令 |
|---|---|
| 按 0.3 判定当前配置（起始武器与登记答案 × 种子 1–10） | `python tools/prototype_cases.py` |
| 试单个构筑 | `python tools/prototype_cases.py --try learn_swarm "Broad B4/H6"` |
| CI 闸门（迁移题不满足时退出码 1；当前仅作报告，不阻断合并） | `python tools/prototype_cases.py --check` |
| 客户端逐场比对夹具（Linux 生成） | `python tools/prototype_cases.py --write-reference` |

配置文件：`config/prototype/m0_cases.json`（客户端打包同一文件）。战斗直接调用 `balance_sim.simulate()`：把场景波次临时放进 `STAGES[成长关卡]`，种子 = 配置种子 × 1000 + 成长关卡，不改模拟器。客户端 150 场与工具逐场一致（Linux 逐位；Apple 平台输赢与波次一致）。

## 当前结果（m0-draft-2026-10-11）

| 场景 | 波次（第 8 关属性） | 起始 Needle B3/H6 | 登记答案 | 0.3 判定 |
|---|---|---|---|---|
| learn_swarm | Mushling ×16（A） | 10/10 | Broad B4/H6 10、Great B8/H2 10 | FAIL：起始武器赢 |
| learn_armor | Shellback ×3（A） | 10/10 | Great 10、Needle+Ember 10 | FAIL：起始武器赢 |
| learn_guard | Sprite ×6（A） | 2/10 | Broad B4/H6 10、Broad+Ember 9 | PASS（但两个答案都是 Broad，见问题 3） |
| transfer_swarm_armor | Mushling ×4 + Shellback ×1（R） | 10/10 | Great 10、Broad+Ember 10 | FAIL：起始武器赢 |
| transfer_guard_swarm | Sprite ×2（T）+ Mushling ×3 | 10/10 | Broad 10、Needle+Ember 10 | FAIL：起始武器赢 |

学习题波次是 Claude 的占位草稿；迁移题是 0.3 写明的初稿数量。

## 需要决定的问题

1. **起始武器太强。** MD 20 的 Needle B3/H6 每击 27，第 8 关 Mushling HP 25，一击必杀；Mushling ×24 起始武器仍 10/10 胜。Armor 题 Shellback ×4 也 10/10。按 0.3 的“起始武器 ≤ 2/10”，需要换成更高成长关卡、更低 MD/预算、或更弱的起始武器之一。
2. **成长关卡的可选方向（同 MD 20 / 预算 10 / HP 164，种子 1–10）：**

   | 方案 | 起始 | Broad B4/H6 | Broad B7/H3 | Great B8/H2 | Needle+Ember | Broad+Ember | Great+Ember |
   |---|---|---|---|---|---|---|---|
   | 第 12 关，Mushling ×8 + Shellback ×2（R） | 0 | 10 | 10 | 10 | 0 | 10 | 10 |
   | 第 10 关，同上 | 1 | 10 | 10 | 10 | 0 | 10 | 10 |
   | 第 12 关，Shellback ×3 | 0 | 4 | 6 | 10 | 10 | 9 | 10 |
   | 第 12 关，Mushling ×12 | 5 | 10 | 10 | 10 | 0 | 10 | 10 |

   第一行满足 Swarm+Armor 迁移：起始 0/10，Broad 与 Great 两种形态都 10/10。
3. **Guard+Swarm 迁移在 M0 规则下缺第二种行为。** M0 只有 Ember：Great 间隔 > 1.5 s 破不了护盾，Needle 类答案不会比起始 Needle B3/H6 更会处理 Swarm，Ember 对 Guard 没有作用，所以能赢的只有 Broad（B4/H6、B7/H3、加 Ember 都是同一行为）。可选：给这题加一只 Shellback 让 Ember 有作用；或允许 Spark；或改题。工具把“形态 + 符文”不同视为行为不同，Broad 与 Broad+Ember 是否算两种答案需要 Codex 判断。
4. **学习题的起始武器**：0.3 只规定迁移题从 Needle B3/H6 开始；学习题目前沿用同一把。
5. **平台浮点差异**：模拟器在 Windows 与 Linux 上 `sin()` 最后一位不同，iPhone（Apple libm）也不同。实测 453 个正式关卡战斗中 Windows 与 Apple 平台各有 1 场细节（时间、剩余 HP）不同、输赢相同；`prototype_reference` 150 场中 Windows 有 1 场细节不同。建议以 Linux（CI）为基准校准，并在冻结的 build 上用真机复核两题的种子 1–10。

6. **失败方向文案提到 M0 没有的 Spark。** 学习题的 Guard 失败显示 `defeat_tip_guard` “Try faster swings (Hilt) or Spark.”（CI 截图已见），M0 只开放 Ember。是否为 M0 另加一条不提 Spark 的方向文案，由 Codex 决定并登记 strings.md。

## 客户端已经按以下理解实现，若不同请改

- 首分钟：英雄 HP 下限 1；未见效果就从第一波重刷（不计时）；交付非 Needle 形态后一次命中 ≥ 3 才算达成；之后出现 Next，允许继续试。
- 迁移题：每次尝试种子依次 1、2、3；3 次或 3 分钟（从进入本题算）先到为止；Retry 保留已锻武器，满血开始。
- 迁移成功记录两层：`success`（是否获胜）与 `counts_as_transfer`（自主改锻/换装后获胜、获胜武器不是初始武器、本题无提示曝光）。
- 失败报告：学习题显示主因 + 方向；迁移题只显示主因。锻造台常驻下半屏，因此失败卡片没有 Forge 按钮，只有 Retry（或用完次数后的 Next）。
