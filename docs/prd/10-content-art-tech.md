# 10. 内容、美术与技术约束

## 10.1 MVP 内容清单（P0）

| 类别 | 内容 | 数量 | 动画 / 状态 | 估算（美术日）[假设] |
|---|---|---|---|---|
| 英雄 | Pip（骨骼 2D，武器作为独立挂点） | 1 | 待机、3 套攻击（Needle 刺、Broad 扫、Great 旋）×（起手 / 出手 / 收招）、受击、Brace（教程）、死亡、胜利、换装 | 12 |
| 铁匠 | Gristle（下半屏） | 1 | 待机、敲击 ×3（对应 3 个区域位置）、Perfect 敲击、抛出武器、欢呼、说话 | 6 |
| 普通敌人 | Mushling、Bramble Sprite、Shellback | 3 | 各 4 段：移动、攻击、受击、死亡 | 3 × 3 = 9 |
| Boss | Queen Mushla、Ironhide、Thornwarden | 3 | 各 5–6 段：移动、攻击、技能（召唤 / 重击预警 + 重击 / 护盾回复）、受击、死亡 | 3 × 5 = 15 |
| Boss 变体 | Ironthorn Warden（Thornwarden 骨骼 + Ironhide 甲片部件 + 新配色） | 1 | 复用 | 3 |
| 武器部件 | 刀身轮廓 ×3（Needle / Broad / Great）、剑柄 ×1 + 缠绳叠加层 ×6、护手 ×1、符文宝石 ×1 | 12 个精灵 | 金属用 4 套调色板（渐变映射），符文用 4 种着色 + 1–5 级辉光 | 4 |
| 场景 | Mossy Hollow、Bramble Deep 战斗背景；工坊下半屏背景；Boss Gate 叠加层 | 4 | 2–3 层视差 | 8 |
| 锻造特效 | 普通火花、Perfect 金火花、热光圈、形态变形爆发、符文充能辉光 ×3 色、淬火蒸汽、交付轨迹 | 9 | — | 4 |
| 战斗特效 | 刀光 ×3 形状、形状轮廓闪光 ×3、灼烧、冰霜、电弧连线、护盾碎裂、甲壳“铛”、重击红圈、召唤烟雾、伤害数字（6 色）、命中计数 | 18 | — | 6 |
| UI | 资源图标 ×4、特性图标 ×4、符文 ×3、形态 ×3、设施 ×3、按钮、面板、商店插图 ×3、App 图标、商店截图 ×6 | ~40 | — | 10 |
| 外观 | Ember Anvil（首购赠品） | 1 | 火花颜色 + 纹路 | 2 |
| **美术合计** | | | | **约 79 天**（1 名美术约 16 周，含返工余量约 10%） |

| 音频 | 内容 | 数量 |
|---|---|---|
| 锻造音效 | 敲击 ×3 变体、Perfect、区域已满、变形 ×2、交付、淬火 | 9 |
| 战斗音效 | Needle 命中、Broad 挥砍 + 命中、Great 旋转 + 命中、Blocked、甲壳铛、灼烧、冰霜、电击、重击、召唤、敌人死亡 ×3、英雄受击、英雄死亡 | 16 |
| UI 音效 | 点击、升级、领取、购买成功、解锁、胜利、失败 | 7 |
| 音乐 | 区域 1 循环、区域 2 循环、Boss 循环、工坊环境音 | 4 |
| 来源 | 音效：授权音效库 + 后期加工；音乐：授权曲库或外包（预算待定）**[待验证]** | — |

## 10.2 复用方案：让武器差异看得见，同时控制成本

| 手段 | 规则 | 效果 |
|---|---|---|
| **部件化武器** | 武器 = 刀身轮廓（按形态 3 选 1）× 刀身宽度缩放（同一形态内每点 Blade 横向 +6%）× 剑柄缠绳叠加（0–6 层）× 符文宝石（着色 + 辉光）× 金属调色板（4 套） | 约 12 个精灵组合出 3 × 4 × 4 = 48 种明显不同的外观，加上宽度与缠绳的细分 |
| **攻击动作按形态，不按武器** | 英雄只需要 3 套攻击动作；同一形态的所有武器共用动作，只换挂点上的武器精灵 | 动画量与武器数量无关 |
| **形状轮廓是程序绘制** | 扇形与圆环用矢量或网格实时生成，半径与角度读配置 | 改范围不需要改美术 |
| **骨骼动画 + 动作时长缩放** | 动作按逻辑时长缩放（0.6×–1.6×），超出范围才用 fast / slow 变体 | Hilt 改变速度时不需要新动画 |
| **敌人配色变体** | P1 的精英怪 / 新区域：同一骨骼 + 新配色 + 1 个附加部件（头盔、甲片） | 新敌人成本约为原创的 1/3 |
| **Boss 部件拼装** | Ironthorn Warden = Thornwarden 骨骼 + Ironhide 甲片 | 第 4 场 Boss 只需约 3 个美术日 |
| **元素着色器** | 灼烧、冰霜、电击都用同一个“目标叠加层”着色器，换颜色与噪声贴图 | 3 种符文共享特效框架 |

## 10.3 存档

| 项 | 规则 |
|---|---|
| 位置 | App 沙盒 `Application Support/save/`，JSON（发布版可做轻度混淆与压缩），带 `schema_version` |
| 内容 | 资源、设施等级、关卡进度与首通标记、武器列表、武器架与装备、Pattern、Codex、未完成的 `forge_session`、Cart（上次领取时间、小数累积、可信时间基准）、设置、已发放的购买（交易 ID）、广告与 Quick Loot 计数、教程标记、时钟异常标记 |
| 写入时机 | 交付、通关、升级、购买发放、Cart 领取、设置变更、切到后台时立即写入；活跃期间每 30 s 写一次；锻造敲击节流为 1 s |
| 原子性 | 写临时文件 → 同步落盘 → 重命名覆盖；保留最近 3 份轮转备份；每份带 SHA-256 校验 |
| 损坏 | 校验失败时按时间倒序加载最近一份有效备份，并上报 `save_corrupted`；全部损坏时尝试 iCloud 副本，再不行才重置（概率应接近 0） |
| 云端 | iCloud Key-Value Store 镜像（单个存档 < 100 KB，上限 1 MB），本地写入后 10 s 防抖同步。启动时比较 `progress_score`（最高关卡 × 10⁶ + 设施总等级 × 10³ + Codex 数）与 `saved_at`。云端领先且不一致时，让玩家选择：`cloud_conflict` “Cloud save: Stage {cloud}. This device: Stage {local}. Keep which?” |
| 迁移 | 每个 schema 版本都有迁移函数；未知字段原样保留，不删除 |

## 10.4 离线结算

1. 切到后台时记录：设备时间、最近一次可信时间及其对应的单调时钟读数（`systemUptime`）。
2. 回到前台时：用可信时间计算流逝；拿不到可信时间时用设备时间，并执行 [7.7](07-economy.md#77-离线收益与领取规则) 的回拨与前跳规则。
3. Cart 按“最高通关关卡”费率分段累积，最多 480 分钟；小数进入累积器。
4. 离线 ≥ 30 分钟时弹出 Welcome back；否则只更新 Cart 图标。
5. 离线**不模拟战斗**、不消耗或掉落武器、不推进关卡。

## 10.5 系统时间变化

| 情况 | 处理 |
|---|---|
| 设备时间往回调 | 本段累积为 0，以当前时间作为新基准；不触发每日重置；记录 `clock_anomaly(direction=back)` |
| 设备时间往前调 | 受 8 h 上限约束；联网后若可信时间显示实际流逝更短，修正**未领取**部分；记录 `clock_anomaly(direction=forward)` |
| 时区或夏令时变化 | 内部只用 UTC 时间戳；每日重置按可信时间推算的本地 04:00 |
| 每日计数 | 存储“上次重置的日序号”，只有日序号**增加**时才重置，回拨不会导致重复重置 |

## 10.6 崩溃恢复

| 状态 | 恢复后 |
|---|---|
| 锻造中 | 恢复到 Striking，保留已敲的点数、Temper 与元素（最多丢失最后 1 s 的敲击） |
| 战斗中 | 从当前关第 1 波重新开始（不保存逐帧战斗状态）；不扣资源 |
| 交付动画中 | 交付的扣费与武器生成在同一次存档里原子提交：要么都发生，要么都没发生 |
| 购买发放中 | 交易在“发放 + 存档”成功后才 `finish()`；重启时从 `Transaction.updates` 和未完成交易中补发，用交易 ID 去重 |
| 崩溃上报 | 集成崩溃上报 SDK（Crashlytics 或 Sentry 二选一），附带最近 20 条埋点作为上下文 |

## 10.7 购买与恢复

| 项 | 规则（StoreKit 2） |
|---|---|
| 商品类型 | 一次性商品（Starter Kit、Skip Ads、Pattern Book、外观）为非消耗型；Gems、Supply Box、月卡为消耗型 |
| 发放 | 先在本地验证 JWS 签名的交易，再发放；发放与存档在同一事务中，最后 `finish()` |
| 恢复购买 | 设置与商店都有 **Restore Purchases**（`btn_restore`），读取 `Transaction.currentEntitlements` 并重新发放非消耗型权益 |
| Starter Kit 内含的消耗品 | 每个存档按原始交易 ID 只发一次；重装且没有 iCloud 存档时，恢复购买会再发一次（原存档已丢失，可以接受） |
| 消耗型的保护 | Apple 不能恢复消耗型，靠 iCloud 存档保护 |
| 待处理 / 家长批准 | 显示 `iap_pending`；稍后在 `Transaction.updates` 中完成 |
| 退款 | 检测到 `revocationDate`：撤销非消耗型权益（例如免广告失效）；消耗型在 MVP 中不追回，只记录 `iap_revoked` |
| 服务端校验 | MVP 不做（单机、无交易市场，风险有限）；P1 视作弊数据再决定 |

## 10.8 配置更新

| 项 | 规则 |
|---|---|
| 来源 | 远程配置（CDN 上的静态 JSON 或 Firebase Remote Config），带 `config_version`、`min_app_version` 与签名哈希 |
| 拉取 | 启动时拉取（3 s 超时），失败用缓存，再失败用包内默认值 |
| 生效时机 | **下一次会话开始**，或者回到主界面且不在战斗 / 锻造中时；绝不在战斗中途替换 |
| 可远程调整 | 关卡波次、敌人 / Boss 属性、首通奖励、Cart 费率与上限、设施费用、广告上限与开关、商品上下架、功能开关、A/B 分组 |
| 不可远程调整 | 形态的 Bp 区间与含义、字符串 ID 的含义（需要发版） |
| 已生成武器 | 保留生成时的数值（`calc_version`），见 [4.10](04-forge-system.md#410-中断重铸替换材料不足与离线) |
| A/B | 按 `install_id` 哈希分桶，桶号写入存档与埋点 |

## 10.9 服务端 vs 本地

| 功能 | MVP 方案 | 是否需要自建服务端 |
|---|---|---|
| 战斗、锻造、经济 | 本地 | 否 |
| 存档 | 本地 + iCloud KVS | 否 |
| 可信时间 | CDN 响应的 HTTP Date | 否（复用配置 CDN） |
| 配置 / A/B | CDN JSON 或 Firebase Remote Config | 否 |
| 埋点 | 第三方分析 SDK（Firebase / GameAnalytics / Amplitude 三选一）**[待定]** | 否 |
| 崩溃 | 第三方 | 否 |
| 内购校验 | 本地 StoreKit 2 | 否（P1 再评估） |
| 广告 | 聚合 SDK（AppLovin MAX 或 AdMob 二选一）**[待定]** | 否 |
| 推送 | 只用本地通知（Cart 满） | 否 |
| 排行榜、PvP、社交 | 不做 | — |

**结论**：MVP 不需要自建游戏服务端，运维成本接近 0。

## 10.10 性能目标

| 指标 | 目标 [假设，M1 实测后修订] |
|---|---|
| 帧率 | iPhone 11（A13）及更新机型稳定 60 fps；最低支持机型 iPhone XR / XS（A12）≥ 30 fps，并自动降低粒子 |
| 同屏单位 | ≤ 40 个敌人 + 1 名英雄（1–20 关最多约 15 个 + 召唤物） |
| 粒子 | 同屏 ≤ 300；Reduce Effects 模式 ≤ 80 |
| 逻辑帧耗时 | 20 Hz 逻辑，每帧 ≤ 2 ms（A13） |
| 触控到反馈 | 点击到火花 / 音效 ≤ 50 ms |
| 内存 | ≤ 350 MB |
| 安装包 | 首次下载 ≤ 150 MB |
| 冷启动 | 到标题 ≤ 3 s，到可操作 ≤ 5 s |
| 耗电 / 发热 | iPhone 12 连续 30 分钟耗电 ≤ 10%，不触发降频 |

## 10.11 关键配置表字段

| 表 | 关键字段 |
|---|---|
| `forms` | id, blade_min, blade_max, dmg_mult, base_interval_s, arc_deg, range_u, max_targets, windup_ratio, windup_min_s, windup_max_s, anim_set_id, outline_vfx_id |
| `forge_rules` | blade_step, hilt_step, temper_step, temper_cap, temper_baseline, blade_cap, hilt_cap, rune_cap, beat_period_s, perfect_window_ms, relaxed_window_ms, min_tap_interval_s, tutorial_budget, smelt_refund |
| `runes` | id, unlock_stage, trigger_base（6）, effect_type, ratio, ticks, duration_s, slow_mult, chain_count, chain_range_u, pierce_guard, color_id, vfx_id, sfx_id, desc_string_id |
| `anvil_levels` | level, budget, cost_coins, gate_stage, perk（quick_forge / pattern_slot） |
| `furnace_levels` | level, metal_id, md, ore_cost, cost_coins, gate_stage, palette_id |
| `barracks_levels` | level, hero_hp, cost_coins |
| `enemies` | id, trait, hp, armor, guard, guard_regen_s, dmg, atk_interval_s, move_speed_u, radius_u, reach_u, hp_growth, armor_growth, dmg_growth, prefab_id, name_string_id |
| `bosses` | id, hp, armor, guard, guard_regen_s, dmg, atk_interval_s, move_speed_u, radius_u, summon_enemy_id, summon_count, summon_interval_s, slam_interval_s, slam_telegraph_s, slam_dmg, hint_string_id |
| `stages` | id, region_id, waves[{enemy_id, count, side}], is_boss, time_limit_s, boss_time_limit_s, first_clear_coins, first_clear_ore, first_clear_stones, first_clear_gems, unlocks[], expected_state（QA 用） |
| `economy` | cart_coin_base, cart_coin_growth, cart_ore_base, cart_ore_growth, cart_cap_min, stone_interval_min, stone_cap, stone_overflow_minutes, wave_heal_ratio, max_attackers, spawn_gap_s, wave_gap_s, spawn_dist_u |
| `codex` | form_id, rune_id, reward_gems, tip_string_id |
| `iap_products` | product_id, type, price_ref_cny, contents{}, purchase_limit, limit_period, show_after_stage, enabled |
| `ad_placements` | id, reward{}, daily_cap, show_after_stage, enabled |
| `strings` | string_id, en, max_chars, plural_one, plural_other, context |

## 10.12 引擎与技术栈 [待定]

| 选项 | 适合的情况 | 风险 |
|---|---|---|
| Unity（2D，LTS 版本） | 程序熟悉 Unity；以后可能出 Android；广告聚合 SDK 支持成熟 | 包体与启动时间需要优化 |
| SpriteKit（Swift） | 程序是 iOS 原生背景；只做 iPhone | 以后移植 Android 等于重写 |

**决定方式**：按程序的现有经验选择，在 M0 第 1 周结束前确定。无论选哪个，都要求战斗逻辑与渲染分离（纯逻辑层可以无界面运行），这样 `tools/balance_sim.py` 的规则能用单元测试逐条比对。
