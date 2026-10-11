# 3. 前 10 分钟完整脚本

## 3.1 目标

| 目标 | 本脚本中的时间点 | 可检验标准 |
|---|---|---|
| 第一把武器 | 0:45–1:25 | 玩家完成引导锻造 #1，得到 *Copper Needle* |
| 第一次遭遇克制 | 3:05 | 关卡 3 第 2 波的 10 只 Mushling 包围英雄，刺剑来不及清（模拟：刺剑 0/5 胜） |
| 第一次改造 | 3:20–3:55 | 引导锻造 #2：剑刃敲到 4 下时变形为 Broad |
| 第一次明显改变打法 | 3:55 | 第一次横扫命中 ≥ 3 只，弹出 `×N` 命中计数（模拟：平均每次挥砍命中 2.9 只，5/5 胜，剩余 HP 74%） |
| 至少两种有区别的战斗方式 | 到 10:00 共 4 种 | 刺击（Needle）→ 横扫（Broad）→ 灼烧刺击（Needle + Ember）→ 环斩（Great） |

**[决定] 首局保护规则：**

1. 首次会话（以完成关卡 7 为界）**不出现任何广告、商店弹窗或付费提示**。
2. 关卡 1–2 按模拟不可能失败（两种武器都 3/3 胜，剩余 HP ≥ 78%）。
3. 关卡 3 第 2 波触发 **Brace**（仅教程）：英雄 HP ≤ 60% 时进入防御姿态，受到伤害 −80%，直到新武器交付或持续 20 s。
4. 教程锻造只开放提示的区域，其他区域置灰；非引导期间的锻造完全自由。
5. 所有对白都是**不阻塞战斗的气泡**；只有锻造 #1 的“第一下敲击”是全屏遮罩阻塞引导。

## 3.2 逐段脚本

> 资源余额与 [7.5 资源路径](07-economy.md#75-完整资源路径初始装备首次-boss第一次构筑转型) 一致。初始资源：Coins 0、Ore 20、Rune Stones 0。战斗时长取自 `balance_sim.py`。英文文案的 ID 见 [strings.md](strings.md#教程)。

| 时间 | 画面（上：战场 / 下：锻造台） | 玩家动作 | 锻造选择 | 战斗反馈 | 奖励 / 余额 | 引导文案（英文，ID） |
|---|---|---|---|---|---|---|
| **0:00–0:20** | 启动画面 → 标题 *Goblin Forge* → 直接进入游戏（无登录、无账号）。上：林间空地。下：老哥布林 Gristle 站在铁砧旁 | 无 | — | — | — | `title_tap_to_start` “Tap to start” |
| **0:20–0:45** | 上：英雄 Pip 拿一根树枝（Twig，伤害 3）戳 2 只 Mushling，很吃力。下：铁砧发红光 | 观看 | — | 树枝每次只打出灰色的 “3” | — | `tut_01` “Pip! That twig is sad. Let’s forge you a real blade.” |
| **0:45–1:25** | 下：教程锻造 #1，预算固定 4 下。Hilt 区高亮 | 点 **Forge** → 敲 Hilt ×2 → 敲 Blade ×2 → **Deliver** | Blade 2 / Hilt 2 / Rune 0 → **Needle**（算例 E1：每击 12、间隔 0.86 s） | 第 3 下时出现热光圈，提示踩节拍。交付后英雄换上铜刺剑，第一击 12 点 | Ore 20 → **14** | `tut_02` “Tap the HILT. A light grip swings faster.”<br>`tut_03` “Now the BLADE. Tap when it glows for a Perfect strike!”<br>`tut_04` “Hand it over!” |
| **1:25–1:55** | 关卡 1（3 波，共 8 只 Mushling） | 观看 | — | 刺剑一次打一只，节奏明快（约 28 s） | 首通 +30 Coins、+6 Ore → C **30** / O **20** | `tut_05` “One at a time. Nice and quick.” |
| **1:55–2:30** | 关卡 2（11 只 Mushling） | 观看 | — | 约 34 s，英雄 HP 剩约 80% | +34 / +6 → C **64** / O **26** | — |
| **2:30–2:50** | 下：工坊按钮跳动，打开 Workshop 面板，Anvil 卡片高亮 | 升级 **Anvil Lv2**（40 Coins） | 预算 6 → 7 | — | C **24** | `tut_06` “More coins, more strikes. Upgrade the Anvil.” |
| **2:50–3:05** | 关卡 3 第 1 波（3 只） | 观看 | — | 正常清掉 | — | — |
| **3:05–3:20** | **第一次遭遇克制**：第 2 波 10 只 Mushling 从左右两侧涌入，围住 Pip。顶部显示 **Swarm** 图标 | 观看 | — | 同时有 6 只在攻击；HP ≤ 60% 时 Pip 举起锅盖进入 Brace（受伤 −80%） | — | `tut_07` “Swarmed! A needle can’t poke them all.”<br>`tut_08` “Hammer the BLADE wider. Wide blades hit everything in front.” |
| **3:20–3:55** | 下：教程锻造 #2，预算 7。Blade 区高亮 | Blade ×4（第 4 下时坯料“砰”地变宽，弹出 **Broad!**）→ Hilt ×3 → Deliver | Blade 4 / Hilt 3 → **Broad**（算例 E2：每击 13、间隔 1.07 s、150° 扇形、最多 6 目标） | 交付对比面板显示：`Hits: 1 → up to 6`，`Speed: slower` | Ore 26 → **20** | `forge_form_broad` “Broad!”<br>`tut_09` “Wider, but heavier. Worth it here!” |
| **3:55–4:15** | **第一次明显改变打法**：Pip 第一次横扫，扇形描边闪光，一次命中 4 只，屏幕中央弹出 **×4** | 观看 | — | 第 2 波约 12 s 清完，剩余 HP ≈ 74%；第 3 波（5 只）轻松清完 | +38 / +7 → C **62** / O **27** | `tut_10` “Look at that sweep!” |
| **4:15–4:35** | Workshop：Furnace 卡片高亮 | 升级 **Furnace Lv2**（60 Coins） | 金属基础伤害 10 → 12（只影响**之后**锻造的武器） | — | C **2** | `tut_11` “Hotter fire, harder metal. Your next forge hits harder.” |
| **4:35–5:10** | 关卡 4：第 2 波出现 2 只 Bramble Sprite，头顶 3 颗护盾点（Guard） | 可选：点武器架里的 Needle → **Swap** | — | 每一击打掉 1 颗护盾点（蓝色 “Blocked”）；Broad 依旧能赢（模拟 3/3，HP 62%） | +43 / +8 → C **45** / O **35** | `tut_12` “Guard pips block a whole hit. Each hit pops one.”<br>`tut_13` “Quick blades pop shields fast. Tap a weapon to swap.” |
| **5:10–5:20** | **Boss Gate**：战场暂停推进，Pip 在门前回满 HP。卡片：Queen Mushla，特性 **Swarm**（会在身边召唤） | 点 **Fight** | 推荐标签亮在 Broad 上 | — | — | `boss_gate_title` “Boss ahead!”<br>`boss_queen_hint` “Spawns Mushlings around her. Wide blades sweep her brood.” |
| **5:20–6:20** | 关卡 5：2 波小怪 + Queen Mushla（HP 300，每 8 s 在身边召唤 3 只） | 观看 | — | Broad（铜 MD 10，锻于 Furnace Lv1）一次扫中女王和召唤物；约 55 s，剩余 HP ≈ 31%（模拟 5/5 胜）。如果换成 Needle：模拟 0/3 胜，触发失败报告（[5.8](05-combat.md#58-失败处理与重复挑战)） | +147 Coins、+8 Ore、**+2 Rune Stones** → C **192** / O **43** / S **2** | `victory_title` “Victory!” |
| **6:20–6:45** | 解锁卡片：**Ember Rune**，演示火焰数字穿过护甲 | 点 **Got it** | — | — | — | `rune_unlocked` “New rune: {rune}!”<br>`rune_ember_desc` “Every few hits, sets the target on fire. Burn ignores Armor.” |
| **6:45–7:00** | Workshop：Barracks | 升级 **Barracks Lv2**（50） | 英雄 HP 100 → 118 | — | C **142** | `tut_14` “Tougher Pip, longer fights.” |
| **7:00–7:15** | 关卡 6 预告：第 2、3 波出现 **Shellback**（Armor 10） | 观看 | — | Broad 打在甲壳上只跳出灰色 “3”（13 − 10） | — | `tut_15` “Shells eat small hits. Fire doesn’t care.” |
| **7:15–7:55** | 下：引导锻造 #3，预算 7。先出现符文选择条，选 **Ember** | Blade ×3 → Hilt ×1 → Rune ×3 → Deliver | Blade 3 / Hilt 1 / Rune 3 → **Needle + Ember**（算例 E3：每击 16、间隔 0.93 s、每 3 次攻击点燃，每秒 8 点灼烧、持续 3 s） | 对比面板：`Rune: Burn every 3 swings` | Ore 43 → **35**，S 2 → **1** | `tut_16` “Pick a rune, then tap the RUNE slot to charge it.”<br>`forge_rune_every` “{effect} every {count} swings”（显示为 “Burn every 3 swings”） |
| **7:55–8:45** | 关卡 6：Pip 刺击甲壳虫，每第 3 下冒出橙色灼烧数字 “8 / 8 / 8” | 观看 | — | 2 只 Shellback 的波次：Needle + Ember 5/5 胜、剩余 HP 42%；纯 Broad 1/5 胜（模拟） | +55 / +9 → C **197** / O **44** / S **1** | `tut_17` “See? Burn goes right through.” |
| **8:45–9:05** | Workshop：Anvil Lv3（需通关 6） | 升级 **Anvil Lv3**（110） | 预算 7 → 8 | — | C **87** | `tut_18` “8 strikes! Put 8 into the BLADE for a Greatsword.” |
| **9:05–9:40** | 下：自由锻造（不强制），Blade 区出现“8”刻度提示。武器架已满（3/3） | Blade ×8 → Deliver → 弹出熔炼选择，选最早的铜刺剑 | Blade 8 / Hilt 0 → **Great**（算例 E4：每击 31、间隔 2.30 s、360°、最多 10 目标） | 熔炼返还 ⌊6 × 0.8⌋ = 4 Ore | Ore 44 − 8 + 4 = **40** | `forge_form_great` “Greatsword!”<br>`rack_full_pick` “Rack full. Pick a weapon to smelt.” |
| **9:40–10:00** | 关卡 7 开始：甲壳虫与蘑菇怪从四面围上来，Pip 第一次**原地环斩**，一圈全中 | 观看 | — | 关卡 7 用 Great：5/5 胜、剩余 HP 78%；用 Needle + Ember 0/5、用 Broad 0/5（模拟） | 通关后 +62 / +10 → C **149** / O **50** / S **1** | `tut_19` “Spin to win!” |
| **10:00 之后** | Loot Cart 介绍；工坊显示下一个目标：Furnace Lv4 *Iron*（需通关 5 ✔，还要 990 Coins 的升级组合） | 点 Cart | — | — | — | `tut_20` “Pip keeps fighting while you’re away. Come back for the loot!” |

## 3.3 前 10 分钟体验到的战斗方式

| # | 打法 | 首次出现 | 画面上的差异 | 模拟证据 |
|---|---|---|---|---|
| 1 | Needle 刺击：单体、快 | 1:25 | 一条细线刺出，命中 1 个目标 | 关卡 1–2 胜 |
| 2 | Broad 横扫：150° 扇形、偏慢 | 3:55 | 半圆描边，`×N` 计数 | 关卡 3：Broad 5/5 胜 vs 教程 Needle 0/5 胜 |
| 3 | Needle + Ember：刺击 + 周期性灼烧 | 7:55 | 武器符文槽亮起，每第 3 击冒火，橙色灼烧数字 | 关卡 6 第 3 波：5/5 胜（HP 42%）vs 纯 Broad 1/5 胜 |
| 4 | Great 环斩：360°、很慢、单击伤害高 | 9:40 | 原地一整圈，屏幕轻微震动 | 关卡 7：Great 5/5 胜（HP 78%）vs Broad 0/5 胜 |

## 3.4 分支与异常

| 情况 | 处理 |
|---|---|
| 关卡 5 Boss 失败（例如换成 Needle 去打） | 失败报告：`defeat_cause_swarm` “Swarmed by {count} at once.” + `defeat_tip_wider` “Try a wider blade (Blade 4+).”，提供 **Retry** 与 **Forge**。不扣任何资源 |
| 玩家在引导锻造 #2 之前就自己点了 Forge | 允许自由锻造；如果第 2 波开始时武器已是 Broad 或 Great，跳过 `tut_07–09` |
| 玩家在 3:20 时杀掉 App | 恢复后回到“锻造 #2 进行中”，已敲的次数保留（[4.10](04-forge-system.md#410-中断重铸替换材料不足与离线)） |
| 玩家拒绝熔炼（9:05） | 交付取消，回到锻造界面，坯料和敲击保留；提示 `rack_full_hint` “Smelt or keep? You can only carry {count} weapons.” |
| 关卡 6 时玩家没选 Ember | 允许，但无符文的 Needle（B3/H4）和 Broad 在关卡 6 都会输（模拟各 0/5）。失败报告给出主因 `defeat_cause_armor` 与提示 `defeat_tip_armor`，玩家可用身上的 1 颗 Rune Stone 重锻；不扣资源 |
| 玩家完全不踩节拍 | Temper 0。复算结果：关卡 1–7 在 Temper 0 与 Temper 2 下胜负和剩余 HP 相同（在铜阶段，+2% 被四舍五入吃掉，例如 12.6 与 12.85 都取整为 13） |
