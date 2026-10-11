# 5. 战斗系统

> 数值均为初始设计值，与 `tools/balance_sim.py` 一致。单位：伤害与 HP 为“点”，时间为秒（s），距离为 u（1u = 32 pt）。

## 5.1 战场

| 项 | 规则 |
|---|---|
| 区域 | 上半屏，逻辑尺寸 12u × 9u。英雄固定站在中心 (0, 0)，不移动，只转身面向目标 |
| 刷怪 | 敌人从距英雄 6.5u 处（屏幕外）出现：L = 左侧 180° ± 35°，R = 右侧 0° ± 35°，T = 上方 90° ± 35°，A = 任意角度。同一波内每 0.35 s 刷一只 |
| 近战位 | 同时最多 **6** 个敌人攻击英雄（围成一圈），其余在外圈排队，排队者仍可被英雄的攻击范围覆盖 |
| 逻辑帧 | 固定 20 Hz（dt = 0.05 s），与渲染帧率无关；渲染插值 |
| 随机 | 每次挑战一个种子：`seed = hash(stage_id, attempt_index)`，只用于刷怪角度与刷怪顺序；伤害没有随机、没有暴击 |

## 5.2 英雄基础能力

**英雄 Pip**（MVP 唯一英雄）

| 属性 | 值 | 来源 |
|---|---|---|
| 最大 HP | 100 / 118 / 139 / 164 / 194 / 229 / 270 / 319 / 376 / 444（Barracks Lv1–10） | [7.3](07-economy.md#73-前-10-级锻造设施) |
| 护甲 | 0（字段保留，MVP 不使用） | — |
| 碰撞半径 | 0.5u | — |
| 无武器时 | 教程开场用 Twig：H = 3，I = 1.0 s，Needle 形状 | 只在教程出现 |
| 攻击 | 完全由当前武器决定：形状、H、I、W、符文 | [4.6](04-forge-system.md#46-区域如何改变属性正式公式) |
| HP 回复 | 每关开始回满；每次波次间隔回复最大 HP 的 20%；Boss Gate 回满；其余时间不回复 | — |
| 技能 | MVP 没有主动技能。符文触发就是“技能”，由锻造决定 | — |

## 5.3 攻击：动画、命中逻辑、视觉特效三层分离

| 层 | 职责 | 规则 | 不允许 |
|---|---|---|---|
| **命中逻辑**（权威） | 决定命中谁、扣多少 | 状态 Ready → Windup(W) → **命中帧** → Recover(I − W) → Ready。Ready 时如果有敌人进入武器范围，就选主目标（边缘距离最近者）开始前摇。命中帧时**重新计算**形状内的目标：Needle 选此刻最近的敌人；Broad 以前摇开始时锁定的朝向为中心取 ±75°；Great 取半径内全部敌人，按距离取前 N 个。目标为空则挥空，不计符文充能 | 不读取动画进度；不受帧率影响 |
| **攻击动画** | 让玩家看到“怎么打” | 每种形态 3 段动作：起手、出手、收招。起手段缩放到 W，收招段缩放到 I − W，出手关键帧对齐逻辑命中帧。缩放倍率限制在 0.6×–1.6×，超出范围时切换到 fast / slow 变体 | 动画结束不触发伤害 |
| **视觉特效** | 让玩家看懂“打中了什么” | 命中帧时，按**逻辑形状**画一次轮廓闪光（Needle 细线、Broad 150° 扇形、Great 圆环），持续 0.15 s；伤害数字；刀光；Great 命中时只对英雄精灵做 0.04 s 的顿帧（仅渲染） | 特效不参与判定；“Reduce effects” 设置可以关掉粒子与震屏，但**不能关掉形状轮廓**（读战斗要用） |

伤害数字颜色规则（[8.6](08-ui-ux.md#86-一眼看懂这把武器改变了什么)）：白色为普通伤害；灰色为被护甲削减超过 50%；蓝色 “Blocked” 为被护盾挡下；橙色为灼烧；青色为冰霜触发；黄色为电击。

## 5.4 武器何时装备、何时生效、能否战斗中替换

| 规则 | 值 |
|---|---|
| 新锻武器 | Deliver 后进入 Rack。若设置 `settings_auto_equip` = On（默认），立即发起一次换装 |
| 手动换装 | 战斗中任何时候都可以点 Rack 里的武器 → **Swap**（`btn_swap`） |
| 生效时点 | 英雄处于前摇时：等这次命中帧结算完；处于收招或 Ready 时：立即开始换装 |
| 换装耗时 | 0.5 s，期间不攻击；结束后进入 Ready，范围内有敌人就立刻起手 |
| 冷却 | 两次换装之间至少隔 3 s（按钮显示冷却环） |
| 符文充能 | 换装时清零 |
| Boss 战 | 允许换装，规则相同 |
| 离线 / Farm 模式 | 保持当前装备 |
| 推荐 | 每波开始前的 1 s 间隔里，带有本波克制标签的武器在 Rack 中发光（[5.9](#59-波次预告与推荐标签)），不会自动替换 |

**[决定]** 换装是一次单击操作，难度不依赖操作速度：每个普通关都存在不需要换装的单一构筑解，或者在波次间隔里换一次即可通过（[6.3](06-gear-builds.md#63-构筑可用的打法)）。

## 5.5 伤害公式与单位

### 5.5.1 英雄 → 敌人

| 步骤 | 公式 | 说明 |
|---|---|---|
| ① 原始伤害 R | `R = rhu(H × (1.3 if 本次触发 Frost else 1))`；Spark 电弧为 `R = rhu(0.6 × H)` | H 见 [4.6.3](04-forge-system.md#463-公式) |
| ② 护盾 Guard | 目标护盾点 > 0：非贯穿攻击 → 护盾点 −1，伤害 = 0，该目标不吃符文效果；贯穿攻击（Spark 电弧）→ 护盾点 −1，**继续结算** | 护盾回复：目标 `regen` 秒未被击中后，每 `regen` 秒 +1 点直到上限。被任何一次命中（包括被挡下的）都会重新计时 |
| ③ 护甲 Armor | `D = max(R − A, ceil(0.2 × R))` | A：护甲值（点）。任何命中至少造成 20% |
| ④ 灼烧（Ember） | 每跳 `ceil(1.5 × H / 3)`，第 1、2、3 秒各一跳 | 无视护甲与护盾；不算“命中”，不触发符文，也不重置护盾计时；同一目标只保留一个灼烧：新灼烧每跳 ≥ 旧灼烧时替换并刷新时长 |
| ⑤ 冰霜（Frost） | 被这一击造成伤害的目标获得 Chill 3.5 s：攻击、移动、召唤、重击计时按 ×0.65 的速度推进 | 不叠加，重复触发只刷新时长 |
| 符文充能 | 每次**接触到至少一个目标**的挥砍（含被护盾挡下的）充能 +1；达到 N 时这一击触发并清零 | Ember / Frost 只作用于本击**造成了伤害**的目标；Spark 即使本击被全部挡下也会触发 |

### 5.5.2 敌人 → 英雄

`D_hero = max(dmg − hero_armor, 1)`，MVP 中 hero_armor = 0，即 D_hero = dmg。Boss 重击单独结算：在 1.5 s 红圈预警后，对英雄造成固定伤害，无法闪避（Frost 能拉长重击计时）。

### 5.5.3 算例

| # | 情景 | 计算 | 结果 |
|---|---|---|---|
| D1 | E2 Broad（H 13）横扫 4 只关卡 3 的 Mushling（HP 16，A 0） | 每只 D = max(13 − 0, ceil(2.6)) = 13；一刀后每只剩 3 HP，第二刀全灭 | 2 次挥砍（2.14 s）清 4 只 |
| D2 | E2 Broad 打关卡 6 的 Shellback（HP 90，A 10） | D = max(13 − 10, ceil(2.6)) = 3 | 要 30 次挥砍（32 s）。这就是“失败报告：Armor soaked {pct}%”的来源 |
| D3 | E3 Needle + Ember（H 16，N 3）打同一只 Shellback | 物理 D = max(6, 4) = 6；灼烧每跳 ceil(24/3) = 8，每 2.79 s 刷新一次 → 覆盖率 100% | 6/0.93 + 8 = 14.5 DPS，约 6.2 s 一只 |
| D4 | E4 Great（H 31）打 Bramble Sprite（Guard 3，regen 1.5） | 间隔 2.30 s > 1.5 s：一刀打掉 1 点 → 1.5 s 无人击中，回 1 点 → 0.8 s 后下一刀再打掉 1 点 | 护盾永远 ≥ 2，伤害恒为 0（模拟：关卡 8 第 1 波 Great 造成 0 伤害，26 次被挡） |
| D5 | E6 Needle + Spark（H 36）打 Thornwarden（Guard 6，regen 1.2） | 前 6 次挥砍打掉护盾（间隔 0.65 s < 1.2 s，不会回复）；每第 3 次挥砍放电，电弧 rhu(21.6) = 22 贯穿 | Boss 段约 25 s 击败 |
| D6 | E5 Needle + Ember（H 27）打 Ironhide（A 20） | 物理 max(7, ceil(5.4)) = 7；灼烧每跳 ceil(13.5) = 14 | 23.7 DPS（见 [4.9 E5](04-forge-system.md#算例-e5ironhide-的答案)） |
| D7 | 关卡 5，Mushling（dmg 3，间隔 1.5 s）× 6 围攻英雄（HP 100） | 6 × 3 / 1.5 = 12 HP/s | 不清怪的话约 8.3 s 死亡；所以 Brace 在 HP ≤ 60% 时触发（教程） |

## 5.6 普通敌人（3 类）

### 5.6.1 基础属性（关卡 1）与成长

| 敌人（英文名） | 特性 | HP | Armor | Guard | 伤害 / 间隔 | 移速 u/s | 半径 u | 验证的构筑 |
|---|---|---|---|---|---|---|---|---|
| **Mushling** | Swarm（成群） | 14 | 0 | 0 | 3 / 1.5 s | 1.1 | 0.35 | 覆盖面：Broad、Great、Spark 电弧 |
| **Bramble Sprite** | Guard（护盾） | 16 | 0 | 3 点，未被击中 1.5 s 后每 1.5 s +1 | 3 / 1.6 s | 1.6 | 0.30 | 攻击次数：Needle、Broad、Spark 贯穿；**Great 无效** |
| **Shellback** | Armor（护甲） | 60 | 7 | 0 | 7 / 2.4 s | 0.7 | 0.50 | 单击重量：Great；无视护甲：Ember |

成长公式（关卡 s，四舍五入）：

- `HP(s) = rhu(HP₁ × 1.085^(s−1))`
- `Armor(s) = rhu(A₁ × 1.065^(s−1))`（护甲跟随 Furnace 金属的伤害曲线，保证“护甲意味着什么”不随关卡漂移）
- `dmg(s) = rhu(dmg₁ × 1.03^(s−1))`
- Guard 点数与回复时间不随关卡成长

### 5.6.2 各关属性（复算用）

| 关卡 | Mushling HP / dmg | Sprite HP / dmg | Shellback HP / Armor / dmg |
|---|---|---|---|
| 1 | 14 / 3 | 16 / 3 | 60 / 7 / 7 |
| 3 | 16 / 3 | 19 / 3 | 71 / 8 / 7 |
| 5 | 19 / 3 | 22 / 3 | 83 / 9 / 8 |
| 6 | 21 / 3 | 24 / 3 | 90 / 10 / 8 |
| 8 | 25 / 4 | 28 / 4 | 106 / 11 / 9 |
| 10 | 29 / 4 | 33 / 4 | 125 / 12 / 9 |
| 12 | 34 / 4 | 39 / 4 | 147 / 14 / 10 |
| 15 | 44 / 5 | 50 / 5 | 188 / 17 / 11 |
| 17 | 52 / 5 | 59 / 5 | 221 / 19 / 11 |
| 20 | 66 / 5 | 75 / 5 | 283 / 23 / 12 |

### 5.6.3 行为

| 敌人 | 移动 | 攻击 | 表现 |
|---|---|---|---|
| Mushling | 直线走向英雄 | 进入 0.25u 攻击距离后，第一次攻击在 0.5 × 间隔后发生 | 小、圆、成群；被扫中会弹飞（仅视觉） |
| Bramble Sprite | 直线快速飞向英雄 | 同上 | 头顶 3 颗蓝色护盾点；被挡下时护盾点碎裂，弹出 “Blocked” |
| Shellback | 慢速爬行 | 同上 | 甲壳上显示护甲图标与数值；被削减的伤害数字显示为灰色 |

## 5.7 Boss（4 场，3 个独立 Boss + 1 个复合变体）

| Boss（英文名） | 关卡 | 属性（固定值，不走成长公式） | 机制 | 验证目标 | 期望状态下的模拟结果（Boss 段，3 个种子） |
|---|---|---|---|---|---|
| **Queen Mushla** | 5 | HP 300，A 0，伤害 5 / 2.2 s，移速 0.8，半径 0.9 | 每 8 s 在**自己身边**（±25°，比她远 0.8u）召唤 3 只本关 Mushling | Swarm → 需要覆盖面；Needle 会被召唤物拖住 | Broad B4/H3：3/3，27 s，HP 46%<br>Needle B3/H4：0/3 |
| **Ironhide** | 10 | HP 500，**A 20**，伤害 6 / 2.5 s | **Slam**：每 12 s 一次，红圈预警 1.5 s，造成 24 点伤害 | Armor → 需要重击或 Ember | Great B8/H2：3/3，36 s，HP 27%<br>Needle + Ember B3/H4/R3：3/3，32 s，HP 34%<br>Broad + Ember：3/3，38 s，HP 27%<br>纯 Needle B3/H6：0/3；纯 Broad B4/H6：0/3 |
| **Thornwarden** | 15 | HP 750，**Guard 6**（1.2 s 未被击中后每 1.2 s +1），伤害 6 / 2.0 s | 每 15 s 在身边召唤 2 只本关 Bramble Sprite | Guard → 需要攻击次数；**Great 完全无效** | Needle + Spark：3/3，25 s，HP 70%<br>Broad B5/H6：3/3，28 s，HP 65%<br>纯 Needle：3/3，53 s，HP 8%<br>任何 Great：0/3（伤害 0） |
| **Ironthorn Warden** | 20 | HP 850，**A 26 + Guard 4**（regen 1.2），伤害 8 / 2.2 s | 每 14 s 召唤 2 只 Sprite；每 14 s Slam 30（预警 1.5 s） | 综合题：既要快，又要能穿甲 | Broad + Ember：3/3，33 s，HP 50%<br>重刃 Broad B7/H6：3/3，38 s，HP 34%<br>Needle + Spark：3/3，41 s，HP 32%<br>Needle + Frost：3/3，52 s，HP 22%<br>纯 Needle、Needle + Ember、任何 Great：0/3 |

Boss 通用规则：

1. **Boss Gate**：Boss 波之前，英雄在门前停下并回满 HP，显示 Boss 卡片（名称、特性图标、一句提示），玩家点 **Fight**（`btn_fight`）后开始。设置 `settings_auto_boss` = On 时 10 s 后自动开始（默认 Off）。
2. Boss 段时间上限 120 s，超时判负（`defeat_cause_timeout`）。
3. Boss 有血条与特性图标；Slam 预警红圈。
4. 首通 Boss 奖励 Coins × 3，并解锁内容（[7.4](07-economy.md#74-前-20-关示例进度与材料需求)）。

## 5.8 失败处理与重复挑战

| 项 | 规则 |
|---|---|
| 胜利条件 | 所有波次（含 Boss）清空 |
| 失败条件 | 英雄 HP ≤ 0；或时间上限：普通关**整关** 90 s，Boss 段 120 s |
| 失败后果 | **不扣任何资源**；首通奖励仍保留给下次胜利 |
| 失败报告 | 上半屏弹出卡片：标题 `defeat_title` “Defeated”、一句主因、一句方向，以及 **Forge**（打开锻造台并让对应区域呼吸发光）/ **Retry** 两个按钮。5 s 无操作后，英雄自动回到 Farm 模式 |
| 主因判定（按顺序，取第一个满足的） | ① 护盾挡下的命中 ≥ 40% → `defeat_cause_guard` “Guard blocked {pct}% of your hits.” + `defeat_tip_guard` “Try faster swings (Hilt) or Spark.”<br>② 护甲吸收的伤害 ≥ 40% → `defeat_cause_armor` “Armor soaked {pct}% of your damage.” + `defeat_tip_armor` “Try a heavier blade (Blade 8+) or Ember.”<br>③ 同时围攻 ≥ 5 且形态为 Needle → `defeat_cause_swarm` “Swarmed by {count} at once.” + `defeat_tip_wider` “Try a wider blade (Blade 4+).”<br>④ 超时 → `defeat_cause_timeout` “Out of time.” + `defeat_tip_damage` “You need more damage. Upgrade the Furnace, then reforge.”<br>⑤ 其他 → `defeat_cause_outmatched` “Outmatched.” + `defeat_tip_upgrade` “Upgrade the Barracks or Furnace, then try again.” |
| 重复挑战 | 无限次、无冷却、无体力。**Retry** 立即重开本关（新种子） |
| 连续 3 次在同一关失败 | 提示升级：在 Rack 中高亮**最匹配**的现有武器；如果没有匹配的武器，在锻造台上显示一条具体配方，例如 `defeat_recipe` “Try: Blade {blade} · Hilt {hilt} · Rune {rune}”。这只是建议，不会自动执行 |
| Farm 模式 | 失败后（或玩家点 `btn_farm`），英雄循环挑战最高已通关卡，作为“练习场”：不发放击杀奖励，HP 不会降到 1 以下，不会死亡。战场角标显示 `farm_label` “Practice”。点 **Challenge Stage {stage}**（`btn_challenge`）回到推进 |
| 自动推进 | 胜利后 2 s 自动进入下一关；下一关是 Boss 关时停在 Boss Gate。设置 `settings_auto_advance` 可关闭 |

## 5.9 波次预告与推荐标签

- 进入关卡时，顶部显示 3 个波次图标，每个图标标出该波主要特性（Swarm / Armor / Guard / Boss）与敌人数量。
- 每次波次间隔（1 s）以及第一波前，下一波图标脉冲；Rack 中拥有对应**克制标签**的武器显示绿色边框（`hint_suggested` “Good vs {trait}”）。
- 克制标签由武器属性**自动推导**，不是手工配置：

| 标签 | 条件 |
|---|---|
| Good vs Swarm | 形态为 Broad 或 Great，或符文为 Spark |
| Good vs Armor | 形态为 Great，或符文为 Ember |
| Good vs Guard | 攻击间隔 ≤ 1.5 s，或符文为 Spark |
| Good vs Boss | 形态为 Needle，或符文为 Frost |
| Weak vs Guard（红色） | 攻击间隔 > 1.5 s 且符文不是 Spark |

## 5.10 关卡结构

- 普通关 3 波；Boss 关 2 波小怪 + Boss。每关具体组成见 [7.4](07-economy.md#74-前-20-关示例进度与材料需求)。
- 波次之间间隔 1.0 s，回复 20% 最大 HP。
- 区域：Mossy Hollow（1–10）、Bramble Deep（11–20）、Rustfang Mines（21–30，P1）。

## 5.11 模拟验证摘要

`python tools/balance_sim.py stages` 在每关的期望状态下，用 3 个种子测试所有代表性构筑。完整表见 [sim_output §3](../balance/sim_output.md#3-关卡验证期望状态每格-3-个随机种子)。结论：

1. 20 关中有 19 关存在 3/3 胜的单一构筑；关卡 14 的最佳单一构筑为 2/3 胜，在波次间隔换一次装可以 3/3 胜（剩余 HP 45%）。这一关被定义为“换装关”。关卡 17 只有 Needle + Spark 能 3/3 胜（剩余 HP 16%）。
2. 每关的“最差构筑”都会失败，即**选错一定有代价**（关卡 1、2、4 除外，这三关两种构筑都能赢，属于教学关）。
3. 第 8 关以后，形态最优的构筑在 Broad、Great、Needle + 符文之间轮换，没有一种形态通吃（[6.5](06-gear-builds.md#65-构筑使用率预期)）。

## 5.12 离线战斗

离线**不做逐帧模拟**。Loot Cart 按最高通关关卡的固定速率累积资源（[7.7](07-economy.md#77-离线收益与领取规则)），与武器、击杀速度无关。理由：结果可预期、计算便宜，也不能通过离线刷取。
