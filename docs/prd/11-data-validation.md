# 11. 数据与商业验证

> 本章所有指标目标均为**实验假设**，用来判断继续、调整还是停止，不是行业基准，也不代表承诺。

**阶段口径**：M0 的 12 人无提示迁移与继续标准以 [00](00-two-week-prototype.md) 为准；本章完整事件表用于后续版本。原型、固定状态试玩、正式经济玩家必须分开，不混算留存/ARR。

## 11.1 埋点事件

公共属性（每个事件都带）：`install_id`、`session_id`、`app_version`、`config_version`、`ab_bucket`、`install_age_days`、`highest_stage`、`anvil_lv`、`furnace_lv`、`barracks_lv`、`coins`、`ore`、`stones`、`gems`、`ts_utc`、`build_mode`（prototype / fixed_state / economy）、`case_id`、`hint_policy`。

| 事件 | 触发条件 | 关键属性 | 分析用途 |
|---|---|---|---|
| `session_start` | 冷启动或回到前台（离开 ≥ 30 s） | offline_minutes, cart_minutes, is_cold_start | 会话数、离线时长 |
| `session_end` | 切到后台 | duration_s, stages_cleared, forges, swaps, ads_watched | 会话时长（目标 3–5 分钟） |
| `tutorial_step` | 每个教程步骤完成（`tut_01`–`tut_20`） | step_id, elapsed_since_install_s | 教程漏斗、前 10 分钟节奏 |
| `forge_start` | 进入 Setup | source（manual / reforge / quick_forge）, context（idle / after_defeat / boss_gate / wave_break / tutorial）, stage_id, next_wave_trait, budget, md | 锻造是不是在回应战场 |
| `forge_complete` | Deliver 成功 | weapon_id, form, bp, hp, rp, rune, temper, strikes_unused, duration_s, undo_count, reset_count, ore_spent, stone_spent, tutorial_ore_subsidy, tutorial_stone_subsidy, smelted_weapon_id, form_changed_vs_equipped, tags[]（Good vs …）, source | 构筑分布、Temper 分布、手动 vs 自动 |
| `forge_cancel` | Cancel | phase, strikes_done, duration_s | 犹豫与退出点 |
| `forge_strike_sample` | 1% 抽样的单次敲击 | zone, perfect, interval_ms | 节奏窗口调参、连点器识别 |
| `weapon_swap` | 换装生效 | from_form, to_form, from_rune, to_rune, context（wave_break / in_wave / boss_gate / auto_equip）, was_suggested, wave_trait | 推荐标签是否有用 |
| `stage_start` | 关卡开始 | stage_id, attempt_index, mode（push / retry / challenge）, equipped_summary, rack_summary, hero_hp | 尝试次数 |
| `wave_end` | 每波结束 | stage_id, wave_index, duration_s, hp_lost_pct, guard_block_pct, armor_absorb_pct, max_engaged, hits_per_swing | 波次难度、克制是否生效 |
| `stage_end` | 胜负或超时 | result, duration_s, hp_left_pct, defeat_cause, wave_reached, first_clear, equipped_summary | 通关率、失败原因 |
| `defeat_report_action` | 失败报告后玩家的第一个动作 | action（forge / retry / auto_farm / swap / upgrade）, time_to_action_s, hint_level | 核心验证（11.2） |
| `hint_shown` | 显示推荐标签、3 次失败配方 | hint_type, stage_id, recommended_tags | 提示强度实验 |
| `boss_gate` | 进入与离开 Boss Gate | boss_id, wait_s, changed_gear | Boss 前是否准备 |
| `upgrade` | 设施升级 | facility, to_level, cost, coins_after | 资源流 |
| `material_blocked` | 报价材料不足 | required_ore, available_ore, required_stones, available_stones, tutorial_covered, wait_s | 区分资源等待与不会改锻 |
| `content_exhausted` | 首次清完该版本可用内容 | last_available_stage, elapsed_since_install_s | D7 内容充足检查；不从留存分母删除 |
| `transfer_result` | 无提示迁移结束 | case_id, attempts, success, hint_exposed, reason_code | 与 ARR 分开评价自主理解 |
| `cart_collect` | 领取 Cart | minutes, coins, ore, stones, ad_double, was_capped, natural_reward, bonus_reward, transaction_id | 离线收益、上限触达率 |
| `quick_loot` | 使用 Quick Loot | source（ad / gems）, minutes | 加速使用 |
| `codex_unlock` | 点亮 Codex | form, rune | 组合探索 |
| `comprehension_survey` | 首次学习后的一题问卷（可跳过）；迁移测试需延后到全部题目结束 | question_id, answer, is_correct, skipped | 可理解性（11.2） |
| `store_open` | 打开商店 | entry_point | 付费漏斗 |
| `offer_impression` | 首购卡、免广告卡展示 | offer_id, placement | 推荐频率 |
| `iap_start` / `iap_success` / `iap_fail` / `iap_restore` / `iap_revoked` | StoreKit 事件 | product_id, price_tier, currency, error_code, tx_hash | 转化、失败原因 |
| `ad_offer` / `ad_start` / `ad_complete` / `ad_fail` | 激励广告 | placement, reward, network | 广告漏斗 |
| `settings_change` | 设置变更 | key, value | 节奏 / 震动偏好 |
| `clock_anomaly` / `save_corrupted` / `cloud_conflict` | 异常 | direction / backup_used / choice | 技术健康 |

**隐私**：只收集匿名的 install_id，不收集个人信息；ATT 拒绝时不传 IDFA；遵守 App Store 隐私标签要求。

## 11.2 核心验证：玩家遇到困难时，是否主动更换锻造策略

### 11.2.1 定义

- **特性失配失败**：`stage_end.result = lose`，且 `defeat_cause ∈ {guard, armor, swarm}`。
- **对症响应**：失败后，在同一关的下一次 `stage_start` 之前（且 15 分钟以内），玩家完成一次 `forge_complete` 或 `weapon_swap`，并且新装备的 `tags[]` 含有 “Good vs {defeat_cause}”。
- **被动刷数值**：失败后到下一次尝试之间只有 `upgrade`，没有对症的锻造或换装。

ARR 按 `hint_policy` 与实际 `hint_shown` 分层：无提示、方向提示、具体配方分别报告；同时给出用户级比例，避免少数重复失败者主导事件级 ARR。未再次挑战者仍留在失败分母。ARR 高只能说明响应发生，不能单独证明自主理解；两题无提示迁移按第 0 章另算。

### 11.2.2 指标与实验假设

| 指标 | 公式 | 目标 [假设] | 若未达标 |
|---|---|---|---|
| **对症响应率 ARR** | 对症响应次数 / 特性失配失败次数 | ≥ 50% | 30–50%：调整 UI 与提示；< 30%：触发停止评估（11.6） |
| 对症成功率 | 对症响应后 2 次尝试内通关的比例 | ≥ 60% | 检查推荐标签与数值 |
| 响应时间 | 失败到对症锻造的中位秒数 | ≤ 60 s | 失败报告的“Forge”按钮引导 |
| 理解率（Broad） | 首次交付 Broad 后问卷 “What changed?” 选中 “Hits more enemies at once” 的比例 | ≥ 70% | 加强交付卡片与形状轮廓 |
| 理解率（符文） | 首次交付符文武器后，选中该符文正确效果的比例 | ≥ 60% | 符文说明与特效 |
| 被动刷数值占比 | 被动刷数值次数 / 特性失配失败次数 | 只监控 | 占比高说明玩家没把它当构筑游戏 |
| 自动化后的手动锻造占比 | Quick Forge 解锁后 7 天内，手动锻造 / 全部锻造 | 只监控（如果 ARR 达标，这一项低也可以接受，见 [2.7](02-core-loop.md#27-解锁自动化后玩家为什么还会手动锻造)） | — |
| 3 次失败提示后的响应率 | 强提示后的 ARR | ≥ 70% | 提示文案 |

问卷文案见 [strings.md](strings.md#问卷)：`survey_q_broad` “What changed with your new blade?”，选项 `survey_a_more` “Hits more enemies at once” / `survey_a_harder` “Hits harder” / `survey_a_faster` “Swings faster” / `survey_a_unsure` “Not sure”。

## 11.3 构筑与进度指标

| 指标 | 定义 | 目标 [假设] |
|---|---|---|
| 首次 Boss 完成率 | 开始教程的玩家中，首次会话内通关关卡 5 的比例 | ≥ 75% |
| 教程完成率 | 通关关卡 7 的比例 | ≥ 70% |
| 关卡漏斗 | 1–20 关各自的到达与通关人数 | 不出现单关流失 > 15% |
| 中位尝试次数 | 每关通关前的 `attempt_index` 中位数 | Boss 关 ≤ 3，普通关 ≤ 2 |
| 形态使用率 | 关卡 8–20 中，各形态的装备时长占比 | 没有任何形态 > 60%，每种 ≥ 15% |
| 符文使用率 | 解锁后，各符文的装备时长占比（在带符文的时间里） | 每种 ≥ 15% |
| 换装关表现 | 关卡 14 的通关玩家中，在波次间隔换过装的比例 | ≥ 40% |
| Codex 进度 | D7 时的 Codex 平均点亮数 | ≥ 7 / 12 |
| 资源流 | 每日来源与消耗（按资源分）；Coins 余额分布；Ore 余额 < 1 次锻造成本的玩家占比；符文石触顶比例 | Ore 不足占比 < 10%；符文石触顶 < 10% |
| 留存 | D1 / D3 / D7，按安装后 24–48 / 72–96 / 168–192 h 窗口内有有效游玩定义，原始安装 cohort 为分母 | 完整首测目标 ≥40% / 25% / 15%；短内容验证版只用 D1 决策，D7 依 11.6 判断是否可解释 |
| 会话 | 每日会话数；会话时长中位数 | ≥ 3 次；3–6 分钟 |
| Cart 上限触达率 | 领取时已满 8 h 的比例 | 30–60%（太高说明上限太短，太低说明可以不必上线） |
| 稳定性 | 无崩溃会话占比 | ≥ 99.5% |

## 11.4 商业指标

| 指标 | 定义 | 目标 [假设] |
|---|---|---|
| 广告参与率 | 当日看过 ≥ 1 次广告的 DAU 占比 | ≥ 30% |
| 人均广告观看 | 广告完成次数 / DAU | 1.5–3.0（上限 6） |
| 各广告位占比 | Welcome back / Quick Loot / Daily Stone | 只监控 |
| 首购转化 | 看到首购卡的玩家中购买的比例 | ≥ 3% |
| D7 付费率 | 7 日内付费玩家 / 新增 | ≥ 1.5% |
| ARPPU / ARPDAU | 分 IAP 与广告分别统计 | 首测基线，用于 LTV 估算 |
| 付费与免费的构筑差异 | 付费玩家与免费玩家形态使用率之差 | < 10 个百分点（验证“不卖强度”） |
| 付费加速 | 分离自然、广告、宝石、广告+宝石及 Supply Box 组，比较关卡 15/20 到达时间分布 | 先建立真实基线；撤回最多提前 1.5 天的承诺，接受范围在 M5 登录事件模拟后冻结 |
| LTV / CPI | 测试市场 30 日 LTV 估算 / 实际 CPI | ≥ 1.2 才考虑扩大投放 |

## 11.5 收入目标分析（若讨论“亿元”目标）

### 11.5.1 口径

| 口径 | 定义 |
|---|---|
| **流水（Gross Bookings）** | 玩家实际支付的内购总额（含平台佣金与税）。广告收入单列 |
| **净收入（Net Revenue）** | 流水 − 平台佣金 − 代扣税费。**[事实，上架前按 Apple 最新条款复核]** App Store 标准佣金为 30%；上一自然年收益不超过 100 万美元的开发者可加入小企业计划，佣金 15%，当年收益超过 100 万美元后，当年剩余时间适用标准费率。亿元流水规模下按 30% 估算。税费因国家而异，本文用假设值 |
| **利润（Profit）** | 净收入 + 广告净收入 − 买量（UA）− 人员 − 外包 − 工具与服务 − 管理费用 − 企业所得税 |

### 11.5.2 倒算公式

| 量 | 公式 |
|---|---|
| 平均 DAU | `DAU = G / (365 × ARPDAU_iap)` |
| 所需安装 | `Installs = G / LTV_iap` |
| 买量费用 | `UA = Installs × (1 − organic_share) × CPI` |
| 净收入 | `Net = G × (1 − commission) × (1 − tax)` |
| 利润（税前） | `Profit = Net + Ad_net − UA − Team − Other` |

### 11.5.3 示例场景（全部参数均为假设，仅用于理解量级）

G = ¥100,000,000（12 个月 IAP 流水），commission = 30%，tax = 7%（假设），Team + Other = ¥8,000,000 / 年（扩编后的运营团队，假设）。

| 参数 | 场景 A | 场景 B | 场景 C |
|---|---|---|---|
| ARPDAU_iap | ¥0.50 | ¥0.50 | ¥0.30 |
| 平均 DAU | 548k | 548k | 913k |
| LTV_iap / 安装 | ¥10 | ¥10 | ¥6 |
| 所需安装 | 1,000 万 | 1,000 万 | 1,667 万 |
| 自然量占比 | 30% | 30% | 30% |
| CPI | ¥6 | ¥9 | ¥6 |
| UA | ¥4,200 万 | ¥6,300 万 | ¥7,000 万 |
| 净收入 | ¥6,510 万 | ¥6,510 万 | ¥6,510 万 |
| 广告净收入（假设为 IAP 流水的 10%） | ¥1,000 万 | ¥1,000 万 | ¥1,000 万 |
| **税前利润** | **¥2,510 万** | **¥410 万** | **−¥290 万** |

**解读**：

1. “亿元流水”意味着全年平均 DAU 在 50 万以上（ARPDAU ¥0.5 时），远超 MVP 首测的验证范围。
2. 同样的流水，利润主要取决于 **LTV / CPI**。场景 A 与 C 的差别只在 LTV 与 ARPDAU。
3. MVP 不验证亿元目标，只验证能否估算出 LTV 曲线，以及测试市场里 **LTV ≥ 1.2 × CPI**（11.4）。达标之后，才用真实参数重做本表。

## 11.6 继续、调整、停止的条件

| 阶段 | 继续条件 [假设] | 不得据此推断 |
|---|---|---|
| 两周 M0 | 第 0 章四项体验指标及有效性门槛全部通过 | D1/D7、商业可行、正式数值平衡 |
| M1/E-1 固定状态切片 | 12 名新用户按无提示协议测试，沿用 M0 理解与迁移门槛；首分钟反馈达标，关键资源/提示无阻塞 | 被补满资源的试玩可以代表真实留存 |
| 1–10 关验证版 | ARR ≥50%（提示分层），Broad 理解 ≥70%，新用户迁移复测达标，D1 ≥40%，教程完成 ≥70%，无崩溃会话 ≥99.5% | 用约 Day1.4 耗尽的内容直接判断 D7；D7 仅描述，不是通过/停止条件 |
| 完整首测版 | 上述核心门槛持续达标；完成经济分组模拟；内容充足时增加 D7 ≥15% 条件 | 只因已有 20 关就自动认为足够测 D7 |

**D7 内容充足检查**：实验开始前锁定配置和可用内容，记录首次 `content_exhausted`。若安装后 168 h 前已耗尽内容的人数达到 cohort 的 10%，或预先模拟已显示大部分内容会在这之前结束，则将 D7 标记为“受内容截断”，不启用其通过/停止闸门。仍报告全 cohort 的原始 D7、耗尽比例和时间；不得剔除通关者重新计算一个更漂亮的留存。10% 是待验证的运营阈值，不能靠延长金币等待满足它。可先补可重复且有选择的挑战，再用新的完整 cohort 测试。

**样本与时间**：1–10 关验证版先招 300–1,000 安装，按有效埋点检查，报告人数、比例及 95% 置信区间。D1 必须等完整观察窗结束；第 12 周开始发测试包不等于第 12 周已有 D7 数据。M3 之后至少另留 1 周观察/复盘，不能在未读到数据前默认启动 M4。提示 A/B 样本不足以判断 10 个百分点差异时，只报告探索结果，不宣称胜出；具体样本量按试跑基线再计算。

**调整与停止**：

- M0 最多追加一轮 5 个工作日，复测仍未达门槛则停止/转向；测试无效先补证据，见 0.6。
- 后续核心理解不足：区分首分钟反馈、提示依赖、难度与经济阻塞，每轮只改主要原因，最多两轮、每轮两周。
- ARR 达标但无提示迁移差，先调整选择空间与可读性，不以更强配方提示宣布玩法通过。
- D1 达标而 D7 低：先做内容充足检查，再判断挑战/成长循环；短内容版不能据 D7 判死刑。
- 完整且内容充足的首测两轮后仍 ARR <30%，或 D1 <30% 且 D7 <8%，进入停止/转向评审；同时结合无提示迁移与逐人观察，避免单一指标误判。
- 留存达标但付费不足：调商品与展示，维持不出售专属构筑的边界；不得在尚未完成全来源经济模拟时扩大投放。
