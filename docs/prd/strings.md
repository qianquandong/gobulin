# 玩家可见文案表（英文）

> **规则**
> 1. 游戏中所有玩家可见文字只用本表的英文。中文只出现在“中文用途说明”列，**不得进入游戏界面**。
> 2. 占位符用 `{name}`；数字统一用 `{count}`、`{amount}`、`{seconds}` 等；百分比 `{pct}` 不带 % 号，% 写在文案里。
> 3. 复数：带 `#one` / `#other` 后缀的是同一 ID 的单复数形式，由本地化库按 `{count}` 选择（遵循 CLDR 英语复数规则：1 用 one，其余用 other）。
> 4. 长度上限写在“出现位置”列（字符数含空格与占位符展开后的典型长度）：按钮 ≤ 14，标签 ≤ 18，接缝提示条 ≤ 38，Toast ≤ 48，失败报告每行 ≤ 60，教程气泡 ≤ 70，商品说明 ≤ 90。
> 5. 风格：短句、主动语态、第二人称；术语首字母大写并保持一致（Blade、Hilt、Rune、Temper、Guard、Armor、Swarm、Strikes、Rack、Loot Cart、Quick Forge）；大写全词只用于三个锻造区域名（BLADE / HILT / RUNE）与教程强调。
> 6. 上线前由英语母语者审校全表（风险 R7）。

## 通用与 HUD

| String ID | English Text | 中文用途说明 | 出现位置 |
|---|---|---|---|
| `app_name` | Goblin Forge | 游戏名（工作名，商标待核实） | App 图标名、标题（≤ 12） |
| `title_tap_to_start` | Tap to start | 标题画面提示 | 标题画面（≤ 18） |
| `hero_name` | Pip | 英雄名 | 对白、卡片 |
| `smith_name` | Gristle | 哥布林铁匠名 | 对白气泡署名 |
| `res_coins` | Coins | 软货币名 | 顶栏、奖励、按钮 |
| `res_ore` | Ore | 锻造材料名 | 顶栏、奖励 |
| `res_stones` | Rune Stones | 符文石名 | 顶栏长按、奖励 |
| `res_gems` | Gems | 高级货币名 | 顶栏、商店 |
| `res_coins_desc` | Spend Coins at the Workshop. | 资源说明 | 顶栏长按气泡（≤ 48） |
| `res_ore_desc` | Ore becomes weapons at the anvil. | 资源说明 | 顶栏长按气泡 |
| `res_stones_desc` | Socket one to give a weapon a rune. | 资源说明 | 顶栏长按气泡 |
| `res_gems_desc` | Rare gems for Quick Loot and style items. | 资源说明 | 顶栏长按气泡 |
| `hud_stage` | Stage {stage} | 当前关卡 | 顶栏（≤ 18） |
| `hud_stage_region` | Stage {stage} · {region} | 关卡 + 区域 | 顶栏（≤ 30） |
| `hud_wave` | Wave {wave}/{total} | 波次进度 | 战场顶部 |
| `hud_hp` | HP {hp}/{max} | 英雄血量 | HP 条 |
| `seam_next_wave` | Wave {wave}: {trait} ×{count} | 下一波预告 | 接缝提示条（≤ 38） |
| `seam_suggested` | {weapon} suggested | 推荐武器（与上一条用 “ · ” 连接） | 接缝提示条 |
| `seam_low_hp` | Pip is in trouble! | 英雄 HP < 30% | 接缝提示条 |
| `seam_slam` | Slam incoming! | Boss 重击预警 | 接缝提示条 |
| `btn_back` | Back | 返回 | 各面板左上（≤ 14） |
| `btn_ok` | OK | 确认 | 弹窗 |
| `btn_cancel` | Cancel | 取消（锻造中也用这一条） | 弹窗、锻造台 |
| `btn_got_it` | Got it | 知道了 | 解锁卡片 |
| `btn_close` | Close | 关闭 | 面板 |
| `num_k` | {value}K | 千位缩写（1,200 → 1.2K） | 数字显示 |
| `num_m` | {value}M | 百万缩写 | 数字显示 |

## 锻造

| String ID | English Text | 中文用途说明 | 出现位置 |
|---|---|---|---|
| `btn_forge` | Forge | 开始锻造 | 主界面下方中间（≤ 14） |
| `btn_reforge` | Reforge | 重铸 | 武器详情 |
| `btn_deliver` | Deliver | 交付武器 | 锻造台右下 |
| `btn_finish` | Finish | 未用完预算时提前完成 | 锻造台 |
| `btn_undo` | Undo | 撤销上一下敲击 | 锻造台左下 |
| `btn_reset` | Reset | 清空全部敲击 | 锻造台 |
| `btn_quick_forge` | Quick Forge | 按 Pattern 自动锻造 | 锻造台 |
| `btn_save_pattern` | Save Pattern | 保存分配 | 武器详情（≤ 14） |
| `forge_zone_blade` | BLADE | 剑刃区域名 | 铁砧区域标签 |
| `forge_zone_hilt` | HILT | 剑柄区域名 | 铁砧区域标签 |
| `forge_zone_rune` | RUNE | 符文区域名 | 铁砧区域标签 |
| `forge_zone_count` | {points}/{cap} | 区域点数 / 上限 | 区域旁 |
| `forge_budget_label` | Strikes | 预算标签（后接数字） | 锻造台空闲状态 |
| `forge_strikes_left#one` | {count} strike left | 剩余敲击（单数） | 锻造台底部 |
| `forge_strikes_left#other` | {count} strikes left | 剩余敲击（复数，含 0） | 锻造台底部 |
| `forge_temper` | Temper {value} | 当前 Temper | 锻造台底部 |
| `forge_perfect` | Perfect! | 踩中节拍 | 敲击点上方浮字 |
| `forge_zone_max` | Max | 区域已满 | 区域旁浮字 |
| `forge_form_needle` | Needle | 回退到刺剑形态时的浮字 | 坯料上方 |
| `forge_form_broad` | Broad! | 进入宽刃形态 | 坯料上方大字 |
| `forge_form_great` | Greatsword! | 进入巨刃形态 | 坯料上方大字 |
| `forge_form_change_warn` | This will turn it into a {form}. | 下一下敲击会跨形态阈值 | 对比面板顶部（≤ 48） |
| `forge_unused_confirm#one` | {count} strike unused. Finish anyway? | 预算未用完确认（单数） | 确认框 |
| `forge_unused_confirm#other` | {count} strikes unused. Finish anyway? | 预算未用完确认（复数） | 确认框 |
| `forge_reset_confirm` | Clear all strikes? | Reset 确认 | 确认框 |
| `forge_rune_none` | No Rune | 不带符文 | 符文选择条（≤ 14） |
| `forge_rune_pick_hint` | Pick a rune to charge the RUNE slot. | 未选元素时点符文区 | 气泡 |
| `forge_rune_every#one` | {effect} on every swing | 符文频率 N = 1 | 对比面板、武器详情 |
| `forge_rune_every#other` | {effect} every {count} swings | 符文频率 | 对比面板、武器详情 |
| `forge_compare_now` | NOW | 对比面板：当前装备列 | 对比面板 |
| `forge_compare_new` | NEW | 对比面板：锻造中列 | 对比面板 |
| `forge_cost` | Cost: {ore} Ore | 锻造成本 | Forge 按钮下方 |
| `forge_cost_stone` | + 1 Rune Stone | 带符文的额外成本 | Forge 按钮下方 |
| `reforge_stone_warn` | The old Rune Stone will break. Use a new one? | 重铸更换元素 | 确认框（≤ 48） |
| `qf_leftover#one` | {count} strike left. Tap to use it. | Quick Forge 后剩余预算（单数） | 锻造台 |
| `qf_leftover#other` | {count} strikes left. Tap to use them. | Quick Forge 后剩余预算（复数） | 锻造台 |
| `qf_pick_pattern` | Pick a pattern | 选择 Pattern | Quick Forge 面板 |
| `qf_pattern_default` | Pattern {index} | Pattern 默认名 | Quick Forge 面板 |
| `qf_unlocked` | Quick Forge unlocked! Save a weapon's pattern, then forge it in one tap. | Anvil Lv5 解锁说明 | 解锁卡片（≤ 90） |
| `qf_saved` | Pattern saved. | 保存成功 | Toast |
| `forge_delivering` | Catch, Pip! | 交付时铁匠喊话 | 气泡 |
| `deliver_changed` | What changed: | 交付卡片标题 | 战场边缘卡片 |
| `change_hits_more` | Sweeps up to {count} enemies. | 变为 Broad | 交付卡片（≤ 38） |
| `change_hits_circle` | Hits everything around Pip. | 变为 Great | 交付卡片 |
| `change_hits_single` | Focuses one enemy at a time. | 变为 Needle | 交付卡片 |
| `change_slower` | Swings slower. | 间隔变长 | 交付卡片 |
| `change_faster` | Swings faster. | 间隔变短 | 交付卡片 |
| `change_harder` | Hits harder. | 每击伤害变高 | 交付卡片 |
| `change_rune_new` | New: {rune_line} | 新增符文（{rune_line} 为 `forge_rune_every` 的结果） | 交付卡片 |

## 武器与材料

| String ID | English Text | 中文用途说明 | 出现位置 |
|---|---|---|---|
| `weapon_name_pattern` | {metal} {form} | 武器名拼接规则（≤ 21） | 武器详情、Rack 长按 |
| `metal_copper` | Copper | 金属 1 | 武器名、工坊 |
| `metal_iron` | Iron | 金属 2 | 同上 |
| `metal_steel` | Steel | 金属 3 | 同上 |
| `metal_moonsilver` | Moonsilver | 金属 4 | 同上 |
| `form_needle_noun` | Needle | 武器名中的形态名词 | 武器名 |
| `form_broad_noun` | Broadsword | 同上 | 武器名 |
| `form_great_noun` | Greatsword | 同上 | 武器名 |
| `form_needle` | NEEDLE | 形态标签 | 对比面板 “Form:” 后 |
| `form_broad` | BROAD | 形态标签 | 同上 |
| `form_great` | GREAT | 形态标签 | 同上 |
| `twig_name` | Twig | 教程开场的树枝 | 教程 |
| `rune_ember` | Ember | 符文名 | 符文选择条、标签 |
| `rune_frost` | Frost | 符文名 | 同上 |
| `rune_spark` | Spark | 符文名 | 同上 |
| `rune_effect_burn` | Burn | Ember 效果词 | `forge_rune_every` 的 {effect} |
| `rune_effect_chill` | Chill | Frost 效果词 | 同上 |
| `rune_effect_shock` | Shock | Spark 效果词 | 同上 |
| `rune_ember_desc` | Every few swings, sets targets on fire. Burn ignores Armor. | Ember 说明 | 解锁卡片、符文长按（≤ 90） |
| `rune_frost_desc` | Every few swings, hits harder and slows targets down. | Frost 说明 | 同上 |
| `rune_spark_desc` | Every few swings, shocks up to 3 enemies. Shocks break through Guard. | Spark 说明 | 同上 |
| `rune_unlocked` | New rune: {rune}! | 符文解锁标题 | 解锁卡片 |
| `stat_form` | Form | 属性名 | 对比面板、武器详情 |
| `stat_damage` | Damage | 每击伤害 | 同上 |
| `stat_swing` | Swing | 攻击间隔 | 同上 |
| `stat_swing_value` | {seconds}s | 间隔数值，如 0.86s | 同上 |
| `stat_hits` | Hits | 命中目标数 | 同上 |
| `stat_hits_upto` | up to {count} | 最多命中 N 个 | 同上 |
| `stat_shape` | Shape | 攻击形状 | 武器详情 |
| `shape_thrust` | Thrust | Needle 形状 | 武器详情 |
| `shape_arc` | Arc {degrees}° | Broad 形状 | 武器详情 |
| `shape_circle` | Full circle | Great 形状 | 武器详情 |
| `stat_rune` | Rune | 符文 | 对比面板、武器详情 |
| `stat_good_vs` | Good vs | 克制标签前缀 | 武器详情 |
| `stat_weak_vs` | Weak vs | 弱点标签前缀 | 武器详情 |
| `weapon_equipped` | Equipped | 当前装备标记 | Rack、武器详情 |
| `btn_equip` | Equip | 装备 | 武器详情 |
| `btn_lock` | Lock | 上锁 | 武器详情 |
| `btn_unlock` | Unlock | 解锁 | 武器详情 |
| `btn_smelt` | Smelt | 熔炼 | 武器详情 |
| `trait_swarm` | Swarm | 特性：成群 | 波次图标、标签 |
| `trait_armor` | Armor | 特性：护甲 | 同上 |
| `trait_guard` | Guard | 特性：护盾 | 同上 |
| `trait_boss` | Boss | 特性：Boss | 同上 |
| `trait_swarm_desc` | Comes in big groups. | 特性说明 | 图标长按 |
| `trait_armor_desc` | Shrugs off small hits. | 特性说明 | 图标长按 |
| `trait_guard_desc` | Blocks whole hits until its pips pop. | 特性说明 | 图标长按 |

## 战斗

| String ID | English Text | 中文用途说明 | 出现位置 |
|---|---|---|---|
| `boss_gate_title` | Boss ahead! | Boss Gate 标题 | Boss 卡片 |
| `btn_fight` | Fight | 开始 Boss 战 | Boss 卡片右下 |
| `btn_change_gear` | Change gear | 去换装 / 锻造 | Boss 卡片左下 |
| `boss_suggested` | Suggested: {weapons} | Boss 推荐武器 | Boss 卡片 |
| `victory_title` | Victory! | 胜利 | 战场中央 |
| `first_clear` | First clear! | 首通标记 | 奖励卡 |
| `reward_line` | +{amount} {resource} | 奖励行 | 奖励卡 |
| `defeat_title` | Defeated | 失败 | 失败报告 |
| `btn_retry` | Retry | 立即重试 | 失败报告 |
| `defeat_auto_practice` | Back to practice in {seconds}... | 自动进入练习倒计时 | 失败报告底部 |
| `farm_label` | Practice | 练习模式角标 | 战场角落 |
| `btn_farm` | Practice | 手动进入练习模式 | 关卡菜单 |
| `btn_challenge` | Challenge Stage {stage} | 回到推进 | 练习模式下方按钮（≤ 22） |
| `combat_blocked` | Blocked | 护盾挡下 | 敌人头顶浮字 |
| `combat_hit_count` | ×{count} | 一次命中多个 | 屏幕中央 |
| `hits_per_swing` | Hits/swing {new} (was {old}) | 交付后效率徽章 | HP 条旁 |
| `wave_summary_guard#one` | Guard blocked {count} hit. | 波次小结（单数） | Toast |
| `wave_summary_guard#other` | Guard blocked {count} hits. | 波次小结（复数） | Toast |
| `wave_summary_armor` | Armor soaked {pct}% of your damage. | 波次小结 | Toast |
| `btn_swap` | Swap | 换装（Rack 武器点开后的按钮；直接点 Rack 也会换装） | Rack、武器详情 |
| `swap_cooldown` | Ready in {seconds}s | 换装冷却 | Rack 按钮 |
| `hint_suggested` | Good vs {trait} | 推荐标签 | Rack 武器下方 |
| `hint_weak` | Weak vs {trait} | 弱点标签 | Rack 武器下方 |
| `time_left` | {seconds}s left | 最后 15 s 倒计时 | 战场顶部 |
| `tut_brace` | Pip braces! | 教程 Brace 状态 | 英雄头顶 |
| `stages_title` | Stages | 关卡列表标题 | 关卡面板 |
| `stage_first_clear_rewards` | First clear: {rewards} | 首通奖励预览 | 关卡面板 |
| `stage_locked` | Clear Stage {stage} | 区域 / 关卡未解锁 | 关卡面板 |
| `rack_title` | Rack | 武器架 | 主界面 |
| `rack_slot_unlocked` | New rack slot! | 武器架扩展 | 解锁卡片 |

## 敌人与区域

| String ID | English Text | 中文用途说明 | 出现位置 |
|---|---|---|---|
| `enemy_mushling` | Mushling | 蘑菇小怪 | 波次图标长按、Codex |
| `enemy_sprite` | Bramble Sprite | 护盾小怪 | 同上 |
| `enemy_shellback` | Shellback | 甲壳虫 | 同上 |
| `boss_queen` | Queen Mushla | Boss 1 | Boss 卡片 |
| `boss_ironhide` | Ironhide | Boss 2 | Boss 卡片 |
| `boss_thornwarden` | Thornwarden | Boss 3 | Boss 卡片 |
| `boss_ironthorn` | Ironthorn Warden | Boss 4（复合） | Boss 卡片 |
| `boss_queen_hint` | Spawns Mushlings around her. Wide blades sweep her brood. | Boss 提示 | Boss 卡片（≤ 70） |
| `boss_ironhide_hint` | Thick shell. Heavy blades or Ember. | Boss 提示 | Boss 卡片 |
| `boss_thornwarden_hint` | Huge Guard that grows back fast. Quick swings or Spark. | Boss 提示 | Boss 卡片 |
| `boss_ironthorn_hint` | Armor and Guard. Fast, heavy hits win. | Boss 提示 | Boss 卡片 |
| `boss_slam` | Slam | 重击技能名 | Boss 卡片标签 |
| `region_mossy` | Mossy Hollow | 区域 1 | 顶栏、关卡面板 |
| `region_bramble` | Bramble Deep | 区域 2 | 同上 |
| `region_rustfang` | Rustfang Mines | 区域 3（P1） | 同上 |

## 失败报告与提示

| String ID | English Text | 中文用途说明 | 出现位置 |
|---|---|---|---|
| `defeat_cause_guard` | Guard blocked {pct}% of your hits. | 主因：护盾 | 失败报告第 1 行（≤ 60） |
| `defeat_tip_guard` | Try faster swings (Hilt) or Spark. | 方向：护盾 | 失败报告第 2 行 |
| `defeat_cause_armor` | Armor soaked {pct}% of your damage. | 主因：护甲 | 失败报告第 1 行 |
| `defeat_tip_armor` | Try a heavier blade (Blade 8+) or Ember. | 方向：护甲 | 失败报告第 2 行 |
| `defeat_cause_swarm` | Swarmed by {count} at once. | 主因：被围 | 失败报告第 1 行 |
| `defeat_tip_wider` | Try a wider blade (Blade 4+). | 方向：变宽 | 失败报告第 2 行 |
| `defeat_cause_timeout` | Out of time. | 主因：超时 | 失败报告第 1 行 |
| `defeat_tip_damage` | You need more damage. Upgrade the Furnace, then reforge. | 方向：伤害 | 失败报告第 2 行 |
| `defeat_cause_outmatched` | Outmatched. | 主因：综合不足 | 失败报告第 1 行 |
| `defeat_tip_upgrade` | Upgrade the Barracks or Furnace, then try again. | 方向：升级 | 失败报告第 2 行 |
| `defeat_recipe` | Try: Blade {blade} · Hilt {hilt} · Rune {rune} | 连续 3 次失败后的配方 | 锻造台顶部 |
| `defeat_try_weapon` | Try your {weapon}. | 连续 3 次失败、已有匹配武器 | Rack 上方气泡 |

## 教程

| String ID | English Text | 中文用途说明 | 出现位置 |
|---|---|---|---|
| `tut_01` | Pip! That twig is sad. Let's forge you a real blade. | 开场 | Gristle 气泡（≤ 70） |
| `tut_02` | Tap the HILT. A light grip swings faster. | 锻造 #1 第 1 步 | 气泡 + 区域高亮 |
| `tut_03` | Now the BLADE. Tap when it glows for a Perfect strike! | 锻造 #1 第 2 步 + 节拍 | 气泡 |
| `tut_04` | Hand it over! | 提示 Deliver | 气泡 |
| `tut_05` | One at a time. Nice and quick. | Needle 打法说明 | 气泡 |
| `tut_06` | More coins, more strikes. Upgrade the Anvil. | 第一次升级 | 气泡 |
| `tut_07` | Swarmed! A needle can't poke them all. | 第一次遭遇克制 | 气泡 |
| `tut_08` | Hammer the BLADE wider. Wide blades hit everything in front. | 引导锻造 Broad | 气泡 |
| `tut_09` | Wider, but heavier. Worth it here! | 讲取舍 | 气泡 |
| `tut_10` | Look at that sweep! | 第一次横扫 | 气泡 |
| `tut_11` | Hotter fire, harder metal. Your next forge hits harder. | Furnace 升级 | 气泡 |
| `tut_12` | Guard pips block a whole hit. Each hit pops one. | Guard 说明 | 气泡 |
| `tut_13` | Quick blades pop shields fast. Tap a weapon to swap. | 换装说明 | 气泡 |
| `tut_14` | Tougher Pip, longer fights. | Barracks 升级 | 气泡 |
| `tut_15` | Shells eat small hits. Fire doesn't care. | Armor 说明 | 气泡 |
| `tut_16` | Pick a rune, then tap the RUNE slot to charge it. | 第一次符文锻造 | 气泡 |
| `tut_17` | See? Burn goes right through. | 灼烧穿甲 | 气泡 |
| `tut_18` | 8 strikes! Put 8 into the BLADE for a Greatsword. | 引导 Great | 气泡 |
| `tut_19` | Spin to win! | 第一次环斩 | 气泡 |
| `tut_20` | Pip keeps fighting while you're away. Come back for the loot! | 介绍 Loot Cart | 气泡 |

## 工坊

| String ID | English Text | 中文用途说明 | 出现位置 |
|---|---|---|---|
| `workshop_title` | Workshop | 工坊标题 | 工坊面板、主界面按钮 |
| `fac_anvil` | Anvil | 设施名 | 工坊卡片 |
| `fac_anvil_desc` | More strikes per forge. | 设施说明 | 工坊卡片 |
| `fac_furnace` | Furnace | 设施名 | 工坊卡片 |
| `fac_furnace_desc` | Better metal for your next forge. | 设施说明 | 工坊卡片 |
| `fac_barracks` | Barracks | 设施名 | 工坊卡片 |
| `fac_barracks_desc` | More HP for Pip. | 设施说明 | 工坊卡片 |
| `upgrade_level` | Lv {level} | 等级 | 工坊卡片 |
| `upgrade_anvil_effect` | Strikes {from} → {to} | Anvil 升级效果 | 工坊卡片 |
| `upgrade_furnace_effect` | {metal} {from} → {to} | Furnace 升级效果（金属名 + MD） | 工坊卡片 |
| `upgrade_barracks_effect` | HP {from} → {to} | Barracks 升级效果 | 工坊卡片 |
| `upgrade_unlocks_qf` | Unlocks Quick Forge | Anvil Lv5 额外说明 | 工坊卡片 |
| `upgrade_unlocks_pattern` | +1 Quick Forge pattern | Anvil Lv10 额外说明 | 工坊卡片 |
| `upgrade_reforge_hint` | Reforge to use the new metal. | 提醒金属只影响之后的锻造 | 工坊卡片 |
| `btn_upgrade` | Upgrade {cost} | 升级按钮（{cost} 带 Coins 图标） | 工坊卡片（≤ 16） |
| `upgrade_max` | Max level | 已满级 | 工坊卡片 |
| `upgrade_locked_stage` | Clear Stage {stage} to unlock | 关卡门槛 | 工坊卡片（≤ 30） |
| `err_not_enough_coins` | Not enough coins | Coins 不足 | 工坊卡片 |

## 武器架与熔炼

| String ID | English Text | 中文用途说明 | 出现位置 |
|---|---|---|---|
| `rack_full_pick` | Rack full. Pick a weapon to smelt. | 武器架满时交付 | 熔炼面板标题 |
| `rack_full_hint#one` | You can carry {count} weapon. Smelt one or keep forging. | 拒绝熔炼时（单数，理论不出现） | 气泡 |
| `rack_full_hint#other` | You can carry {count} weapons. Smelt one or keep forging. | 拒绝熔炼时 | 气泡 |
| `rack_all_locked` | All weapons are locked. Unlock one to smelt it. | 全部上锁 | 气泡 |
| `btn_keep_forging` | Keep forging | 放弃熔炼，回到锻造 | 熔炼面板 |
| `btn_smelt_deliver` | Smelt & Deliver | 熔炼并交付 | 熔炼面板（≤ 16） |
| `smelt_confirm` | Smelt {name}? You get {ore} Ore back. | 熔炼确认 | 确认框 |
| `smelt_stone_lost` | The Rune Stone is lost. | 熔炼带符文武器 | 熔炼面板 / 确认框 |
| `smelt_done` | Smelted {name}. +{ore} Ore | 熔炼完成 | Toast |
| `btn_undo_smelt` | Undo | 撤销熔炼（5 s） | Toast 按钮 |

## Loot Cart 与离线

| String ID | English Text | 中文用途说明 | 出现位置 |
|---|---|---|---|
| `cart_title` | Loot Cart | 离线收益 | Cart 面板、图标 |
| `cart_accrued` | {hours}h {minutes}m of loot | 已累积时长 | Cart 图标、面板 |
| `cart_full` | Cart full! | 达到 8 h | Cart 图标 |
| `btn_collect` | Collect | 领取 | Cart 面板、回归面板 |
| `welcome_back_title` | Welcome back! | 回归面板标题 | 回归面板 |
| `welcome_back_away` | You were away for {hours}h {minutes}m. | 离开时长 | 回归面板 |
| `btn_ad_double` | Watch ad: ×2 | 看广告翻倍 | 回归面板 |
| `quick_loot_title` | Quick Loot | 立即获取 Cart 收益 | Cart 面板 |
| `quick_loot_desc` | Get {duration} of cart loot now. | Quick Loot 说明（{duration} 如 “2h”、“30 min”） | Cart 面板 |
| `quick_loot_left` | {left}/{max} left today | 今日剩余次数 | Cart 面板 |
| `stone_overflow` | Rune Stones full! Extras became {coins} Coins. | 符文石溢出 | Toast（≤ 48） |

## Codex

| String ID | English Text | 中文用途说明 | 出现位置 |
|---|---|---|---|
| `codex_title` | Codex | 图鉴 | 主菜单、面板 |
| `codex_progress` | {found}/{total} found | 进度 | 面板顶部 |
| `codex_reward` | First forge: +{gems} Gems | 首次奖励 | 未点亮格 |
| `codex_unknown` | ??? | 未点亮 | 未点亮格 |
| `codex_tip_needle_none` | Fast single strikes. Pops Guard quickly. | 组合提示 | Codex 格 |
| `codex_tip_needle_ember` | Burns through Armor, one foe at a time. | 组合提示 | Codex 格 |
| `codex_tip_needle_frost` | Slows big hitters while you chip away. | 组合提示 | Codex 格 |
| `codex_tip_needle_spark` | Shocks hop to nearby foes and crack Guard. | 组合提示 | Codex 格 |
| `codex_tip_broad_none` | Sweeps the crowd in front of Pip. | 组合提示 | Codex 格 |
| `codex_tip_broad_ember` | Sets a whole row on fire. | 组合提示 | Codex 格 |
| `codex_tip_broad_frost` | Chills everything in the arc. | 组合提示 | Codex 格 |
| `codex_tip_broad_spark` | Sweep, then shock the stragglers. | 组合提示 | Codex 格 |
| `codex_tip_great_none` | Slow, heavy spins. Laughs at Armor. | 组合提示 | Codex 格 |
| `codex_tip_great_ember` | Big spin, big burns. | 组合提示 | Codex 格 |
| `codex_tip_great_frost` | Freeze the whole circle. | 组合提示 | Codex 格 |
| `codex_tip_great_spark` | Too slow for Guard. Spark helps a little. | 组合提示 | Codex 格 |

## 设置

| String ID | English Text | 中文用途说明 | 出现位置 |
|---|---|---|---|
| `settings_title` | Settings | 设置 | 设置面板 |
| `settings_music` | Music | 音乐音量 | 设置 |
| `settings_sound` | Sound | 音效音量 | 设置 |
| `settings_haptics` | Haptics | 震动 | 设置 |
| `opt_off` | Off | 选项：关 | 设置 |
| `opt_on` | On | 选项：开 | 设置 |
| `opt_light` | Light | 震动：轻 | 设置 |
| `opt_full` | Full | 震动：全 | 设置 |
| `settings_rhythm` | Rhythm | 节奏模式 | 设置 |
| `opt_relaxed` | Relaxed | 节奏：宽松 | 设置 |
| `settings_rhythm_desc` | Perfect strikes add Temper (+1% damage each). Off gives a flat Temper 3. | 节奏说明 | 设置（≤ 90） |
| `settings_reduce_fx` | Reduce Effects | 减少特效 | 设置 |
| `settings_auto_equip` | Auto-equip New Weapons | 自动装备新武器 | 设置 |
| `settings_auto_advance` | Auto-advance | 胜利后自动进入下一关 | 设置 |
| `settings_auto_boss` | Auto-start Boss | 10 s 后自动开始 Boss | 设置 |
| `settings_notifications` | Notifications | 推送 | 设置 |
| `btn_restore` | Restore Purchases | 恢复购买 | 设置、商店（≤ 18） |
| `settings_support` | Support | 客服 | 设置 |
| `settings_privacy` | Privacy Policy | 隐私政策 | 设置、商店 |
| `settings_terms` | Terms of Use | 用户协议 | 设置、商店 |
| `settings_version` | Version {version} | 版本号 | 设置底部 |

## 商店与商品

| String ID | English Text | 中文用途说明 | 出现位置 |
|---|---|---|---|
| `shop_title` | Shop | 商店 | 主界面按钮、面板 |
| `shop_offers` | Offers | 分区 | 商店 |
| `shop_supplies` | Supplies | 分区 | 商店 |
| `shop_gems` | Gems | 分区 | 商店 |
| `shop_more` | More | 分区 | 商店 |
| `shop_style` | Style | 分区（P1） | 商店 |
| `iap_starter_name` | Smith's Starter Kit | 首购名 | 商店、卡片（≤ 24） |
| `iap_starter_desc` | 300 Gems, 5 Rune Stones and the Ember Anvil. One per player. | 首购说明 | 商店（≤ 90） |
| `offer_starter_card` | A little kit for a new smith. Once only. | 第 2 次会话的首购卡 | 回归面板下方卡片 |
| `iap_supply_name` | Forge Supply Box | 材料自选包名 | 商店 |
| `iap_supply_desc` | Pick one: 6 Rune Stones, a crate of Ore, or 4h of cart Coins. Once a week. | 材料自选包说明 | 商店 |
| `supply_pick_title` | Pick your supplies | 三选一标题 | 选择面板 |
| `supply_opt_stones` | 6 Rune Stones | 选项 a | 选择面板 |
| `supply_opt_ore` | {ore} Ore | 选项 b | 选择面板 |
| `supply_opt_coins` | {coins} Coins (4h of cart) | 选项 c | 选择面板 |
| `supply_resets_in` | Resets in {days}d {hours}h | 真实每周重置 | 商店 |
| `supply_stone_cap` | That would go over 20 Rune Stones. Pick another. | 选项 a 会溢出 | 选择面板 |
| `iap_adfree_name` | Skip Ads, Keep Rewards | 免广告名 | 商店 |
| `iap_adfree_desc` | Get every ad reward instantly. Daily limits stay the same. | 免广告说明 | 商店 |
| `offer_adfree_hint` | Tired of ads? Skip them and keep the rewards. | 看满 10 次广告后一次 | 广告确认框 |
| `iap_gems_pouch` | Pouch of Gems | ¥6 档 | 商店 |
| `iap_gems_sack` | Sack of Gems | ¥30 档 | 商店 |
| `iap_gems_chest` | Chest of Gems | ¥68 档 | 商店 |
| `iap_gems_vault` | Vault of Gems | ¥128 档 | 商店 |
| `iap_gems_hoard` | Hoard of Gems | ¥328 档（P1） | 商店 |
| `iap_gems_amount` | {amount} Gems | 宝石数量 | 商店 |
| `iap_first_bonus` | First buy: double Gems! | 每档首次双倍 | 商店角标 |
| `iap_pattern_name` | Pattern Book | Pattern 槽扩展（P1） | 商店 |
| `iap_pattern_desc` | Hold up to 6 Quick Forge patterns and name them. | 说明（P1） | 商店 |
| `iap_monthly_name` | Smith's Monthly | 月卡（P1） | 商店 |
| `iap_monthly_desc` | 300 Gems now, plus 30 Gems every day for 30 days. | 月卡说明（P1） | 商店 |
| `monthly_claim` | Daily Gems: +{gems} | 月卡每日领取 | 回归面板 |
| `style_ember_anvil` | Ember Anvil | 外观名 | 商店、外观 |
| `style_ember_anvil_desc` | Your sparks burn orange-red. | 外观说明 | 商店 |
| `iap_pending` | Purchase pending... | 购买处理中 / 家长批准 | 商店 Toast |
| `iap_failed` | Purchase failed. Please try again. | 购买失败 | 商店 Toast |
| `iap_success` | Thanks! Your items are here. | 购买成功 | 商店 Toast |
| `iap_restored` | Purchases restored. | 恢复成功 | Toast |
| `iap_nothing_to_restore` | No purchases to restore. | 无可恢复 | Toast |
| `shop_legal` | Terms · Privacy | 商店底部链接 | 商店 |

## 广告

| String ID | English Text | 中文用途说明 | 出现位置 |
|---|---|---|---|
| `btn_watch_ad` | Watch ad | 看广告 | 各广告位（≤ 14） |
| `btn_claim_free` | Claim | 已购免广告时直接领取 | 各广告位 |
| `ad_quick_loot` | 30 min of loot | 广告版 Quick Loot | Cart 面板 |
| `ad_daily_stone` | Free Rune Stone | 每日广告符文石 | 工坊顶部 |
| `ad_limit_reached` | Come back tomorrow for more. | 今日次数用完 | 广告按钮 |
| `ad_not_ready` | No ad right now. Try again soon. | 广告加载失败 | 广告按钮 |
| `att_preprompt_title` | A quick question | ATT 前置说明标题 | 自有说明页 |
| `att_preprompt` | Next, iOS will ask about tracking. Allowing it helps us show relevant ads. Your rewards are the same either way. | ATT 前置说明 | 自有说明页（≤ 120） |

## 系统与错误

| String ID | English Text | 中文用途说明 | 出现位置 |
|---|---|---|---|
| `err_not_enough_ore` | Not enough ore | Ore 不足 | Forge 按钮下方 |
| `err_no_rune_stones` | No Rune Stones | 没有符文石 | 符文选择条 |
| `err_save_failed` | Couldn't save. We'll try again. | 存档失败 | 全局 Toast |
| `save_restored_backup` | We restored your last good save. | 加载备份存档 | 启动 Toast |
| `net_offline` | You're offline. The shop and ads need a connection. | 无网络 | 商店、广告入口 |
| `cloud_conflict` | Cloud save: Stage {cloud}. This device: Stage {local}. Keep which? | iCloud 冲突 | 确认框 |
| `btn_use_cloud` | Use Cloud | 选云端 | 确认框 |
| `btn_use_device` | Use This Device | 选本机 | 确认框（≤ 16） |
| `update_required` | A new version is out. Please update to keep playing. | 低于远程配置的最低版本 | 全屏提示 |

## 问卷

| String ID | English Text | 中文用途说明 | 出现位置 |
|---|---|---|---|
| `survey_q_broad` | What changed with your new blade? | 首次交付 Broad 后的问卷 | 问卷卡片 |
| `survey_a_more` | Hits more enemies at once | 正确答案 | 问卷选项 |
| `survey_a_harder` | Hits harder | 干扰项 | 问卷选项 |
| `survey_a_faster` | Swings faster | 干扰项 | 问卷选项 |
| `survey_a_unsure` | Not sure | 不确定 | 问卷选项 |
| `survey_q_rune` | What does your new rune do? | 首次交付符文武器后的问卷 | 问卷卡片 |
| `survey_rune_ember` | Burns through Armor | Ember 正确答案（Frost / Spark 用下面两条） | 问卷选项 |
| `survey_rune_frost` | Slows enemies down | Frost 正确答案 | 问卷选项 |
| `survey_rune_spark` | Breaks through Guard | Spark 正确答案 | 问卷选项 |
| `survey_rune_wrong` | Heals Pip | 干扰项 | 问卷选项 |
| `survey_skip` | Skip | 跳过 | 问卷卡片 |
| `survey_thanks` | Thanks! | 提交后 | Toast |

## 推送通知

| String ID | English Text | 中文用途说明 | 出现位置 |
|---|---|---|---|
| `notif_preprompt` | Want a ping when your Loot Cart is full? | 系统权限请求前的自有说明 | Cart 上线时的卡片 |
| `push_cart_full` | Pip's Loot Cart is full! Come collect it. | Cart 满时的本地通知 | iOS 通知（≤ 60） |

## 商店与 ASO

| String ID | English Text | 中文用途说明 | 出现位置 |
|---|---|---|---|
| `store_title` | Goblin Forge | App Store 名称（≤ 30，商标待核实） | App Store |
| `store_subtitle` | Tap to forge. Watch Pip fight. | 副标题（30 字符） | App Store |
| `store_tagline_1` | A few taps turn a needle into a broadsword. | 卖点 1 | 截图 1 文案 |
| `store_tagline_2` | Every enemy has an answer. Forge it. | 卖点 2 | 截图 2 文案 |
| `store_tagline_3` | Pip keeps fighting while you're away. | 卖点 3 | 截图 3 文案 |
| `store_tagline_4` | No gacha. Your taps decide your blade. | 卖点 4（公平） | 截图 4 文案 |
| `store_promo` | Hammer the blade, change the fight. | 推广文本（≤ 170） | App Store 推广文本 |
| `store_keywords` | forge,blacksmith,idle,rpg,sword,goblin,tap,auto battle,crafting,offline | 关键词（≤ 100 字符；本条 71） | App Store Connect |
| `app_name_alt_1` | Goblin Smithy | 备选名（内部，待商标检索） | 不进游戏 |
| `app_name_alt_2` | Pip & the Anvil | 备选名（内部） | 不进游戏 |
| `app_name_alt_3` | Gobsmith | 备选名（内部） | 不进游戏 |
