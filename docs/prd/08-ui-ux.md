# 8. UI 与交互

> 线框图中的游戏文字一律为英文（与 [strings.md](strings.md) 一致）；线框外的中文是给团队的说明。图标在线框里用 ASCII 代替：`C` = Coins，`O` = Ore，`R` = Rune Stones，`G` = Gems。

## 8.1 布局原则

| 规则 | 值 |
|---|---|
| 方向 | 只支持竖屏 |
| 分屏比例 | 上半屏战场约 45%（含顶栏），下半屏锻造台约 55%。以 iPhone 13/14/15 的逻辑分辨率 390 × 844 pt 为基准 |
| 拇指热区 | 所有高频操作（Forge、三个敲击区、Deliver、Undo、Rack 换装）都在屏幕下 55% 内；右手单手时 Deliver 位于右下 |
| 最小触控 | 44 × 44 pt（系统按钮）；敲击区 ≥ 64 × 64 pt |
| 安全区 | 顶部避开灵动岛与刘海，底部避开 Home 指示条（16 pt） |
| 字号 | 正文 ≥ 13 pt，数字 ≥ 15 pt，伤害数字 14–28 pt |
| 动效时长 | 面板切换 ≤ 200 ms；锻造变形 250 ms；交付抛掷 600 ms |

## 8.2 主界面（上下分屏）

```
+--------------------------------------+
| C 1,240   O 54   R 3   G 120     [=] |  <- top bar
| Stage 8 . Mossy Hollow  [GRD][ARM][SWM]|  <- wave icons, next one pulses
|                                      |
|      m         m                     |
|   m      \   (Pip)   /     m         |  <- battlefield 12u x 9u
|             '-----'                  |
|      s              m                |
| HP [########--] 112/139   [Cart 2h]  |
|======================================|  <- seam ticker (one line)
| Wave 2: Guard x3 - Needle suggested  |
|======================================|
| RACK [Broad *][Great][Needle.Ember]  |  <- tap to swap; * = equipped
|                                      |
|            .------------.            |
|            |   /\        |  Strikes 9 |
|            |  |  | BLADE |            |
|            |  <o> RUNE   |            |
|            |  |=| HILT   |            |
|            '------------'            |
| [Workshop]     [  FORGE  ]    [Shop] |
+--------------------------------------+
```

- **接缝提示条（seam ticker）**：分屏线上的一行文字。上半屏的重要事件（下一波特性与推荐、英雄 HP < 30%、Boss 重击预警）同步写在这里，玩家**低头敲铁砧时不用抬眼**也能看到。
- Cart 图标上显示已累积的时长；满了变为 `cart_full`。

## 8.3 锻造选择与交付对比

```
+--------------------------------------+
| (battle keeps running above)         |
|======================================|
| Wave 3: Armor x2 - Ember suggested   |
|======================================|
| Rune: [No Rune] [Ember*] [Frost] [--]|  <- Spark locked = hidden
|  .-----------.     NOW      NEW      |
|  |   /\      |  Damage  13  ->  16 ^ |
|  |  |  | 3/12|  Swing  1.07s->0.93s^|
|  |  |  |     |  Hits  up to 6 -> 1 v |
|  |  <o> 3/5  |  Rune     -  -> Burn  |
|  |   |       |           every 3     |
|  |  |=| 1/6  |  Form:  NEEDLE        |
|  '-----------'  Good vs: Armor       |
|  Strikes left 0      Temper 2        |
| [Undo] [Reset]   [Cancel] [DELIVER]  |
+--------------------------------------+
```

- 左侧是铁砧特写，每个区域旁显示“当前点数 / 上限”。
- 右侧对比：左列 NOW = 当前装备，右列 NEW = 锻造中的武器；▲ / ▼ 用绿 / 红表示变好 / 变差。**只显示有变化的行**，排序为：形态 > 命中数 > 伤害 > 间隔 > 符文。
- 形态即将跨阈值时（例如 Blade 3 → 4），NEW 列预先闪烁 `forge_form_change_warn`。
- 交付确认不再弹窗（Deliver 本身就是确认）；但如果交付会熔炼武器，会先弹出熔炼选择。

## 8.4 装备对比与武器架

```
+--------------------------------------+
| Iron Greatsword                [Lock]|
|        ___                           |
|       /   \      Form: GREAT         |
|      |     |     Blade 8 Hilt 1 Rune -|
|       \___/      Temper 3            |
|--------------------------------------|
|              EQUIPPED      THIS      |
| Damage          26    ->    44   ^   |
| Swing         0.78s   ->  2.14s  v   |
| Hits          up to 6 -> up to 10 ^  |
| Shape         Arc 150    Full circle |
| Good vs       Swarm      Swarm, Armor|
| Weak vs       Armor      Guard       |
|--------------------------------------|
| [Equip] [Reforge] [Save Pattern] [Smelt]|
+--------------------------------------+
```

- 从 Rack 长按（0.4 s）或点 ⓘ 进入；单击 Rack 武器直接换装（[5.4](05-combat.md#54-武器何时装备何时生效能否战斗中替换)）。
- “Good vs / Weak vs” 由武器属性自动推导（[5.9](05-combat.md#59-波次预告与推荐标签)）。

## 8.5 关卡、Boss Gate 与失败报告

**关卡列表**

```
+--------------------------------------+
| < Back            STAGES             |
| MOSSY HOLLOW                         |
|  (1)-(2)-(3)-(4)-[5 Queen Mushla]    |
|  (6)-(7)-(8)-(9)<you  [10 Ironhide]  |
| BRAMBLE DEEP        Clear Stage 10   |
|--------------------------------------|
| Stage 9                              |
| W1 Swarm x7  W2 Armor x2             |
| W3 Guard x3 + Armor x1               |
| First clear: 80 Coins . 11 Ore       |
|           [ Challenge ]              |
+--------------------------------------+
```

**Boss Gate**（战场内卡片，不全屏）

```
+--------------------------------------+
|            BOSS AHEAD!               |
|            IRONHIDE                  |
|      [ARMOR 20]   [SLAM]             |
| Thick shell. Heavy blades or Ember.  |
|  Suggested: Needle.Ember  Great      |
|      [Change gear]   [ FIGHT ]       |
+--------------------------------------+
```

**失败报告**

```
+--------------------------------------+
|            DEFEATED                  |
| Armor soaked 71% of your damage.     |
| Try a heavier blade (Blade 8+)       |
| or Ember.                            |
|      [ Forge ]        [ Retry ]      |
| Back to practice in 5...             |
+--------------------------------------+
```

## 8.6 一眼看懂“这把武器改变了什么”

| 手段 | 规则 | 何时出现 |
|---|---|---|
| ① 铁砧上的轮廓变化 | 每次敲击都改变坯料：Blade 每点让刀身变宽 / 变长，跨阈值 4 与 8 时有“砰”的整形动画（250 ms）；Hilt 每点多缠一圈绳；Rune 每点让宝石亮一级 | 锻造中 |
| ② 只列变化的对比面板 | NOW → NEW，最多 4 行，形态变化永远放第一行，例如 `Hits: 1 → up to 6` | 锻造中、交付前 |
| ③ 交付卡片 | 交付时，战场边缘弹出 2 秒小卡：`deliver_changed` “What changed:” + 1–2 行，例如 “Sweeps up to 6 enemies.” “Swings slower.” | 交付后 |
| ④ 形状轮廓加强 | 新武器的前 3 次攻击，命中形状轮廓持续 0.3 s（平时 0.15 s），并更亮 | 交付后前 3 击 |
| ⑤ 命中计数 | 一次命中 ≥ 3 个目标时，弹出 `×N`（N ≥ 5 时字号放大） | 战斗中 |
| ⑥ 效率徽章 | 交付后 10 s 内，在 HP 条旁显示“每击平均命中数”与上一把武器的对比：`hits_per_swing` “Hits/swing {new} (was {old})” | 交付后 10 s |
| ⑦ 颜色语言 | 白色普通、灰色被甲削减、蓝色 Blocked、橙色灼烧、青色冰霜、黄色电击；全游戏统一 | 战斗中 |
| ⑧ 波次小结 | 本波护盾挡下 ≥ 10 次，或护甲吸收 ≥ 40% 时，波次间隔里出 1 行 toast：`wave_summary_guard` “Guard blocked {count} hits.” | 波次间隔 |

## 8.7 音效与震动

| 事件 | 音效 | 震动（iOS 触感反馈） | 视觉 |
|---|---|---|---|
| 普通敲击 | 短促的金属“叮” | Light impact | 白色火花 |
| Perfect 敲击 | 高音“叮” + 回响 | Medium impact | 金色火花、`Perfect!` |
| 区域已满 | 闷响 | Soft（Rigid 0.3） | 区域抖动、`Max` |
| 形态跨阈值 | 重“铛” | Heavy impact | 坯料整形动画、`Broad!` / `Greatsword!` |
| 节拍提示 | 无声（避免吵） | 节拍时 Selection 轻触，仅在“Rhythm: On”且“Haptics: Full”时 | 光圈收缩 |
| Deliver | 呼啸 + 接住声 | Medium + Light（两段） | 抛物线 |
| 符文触发（战斗） | 各元素一个音效 | 无（战斗中太频繁） | 元素特效 |
| 英雄 HP < 30% | 心跳音（每波一次） | Double light | 接缝提示条变红 |
| Boss 重击预警 | 低音嗡鸣 | Warning notification | 红圈 |
| 胜利 / 失败 | 胜利号角 / 低沉鼓点 | Success / Error notification | 卡片 |

设置（`settings_*`）：Music 音量、SFX 音量、Haptics（Off / Light / Full）、Rhythm（On / Relaxed / Off）、Reduce Effects（关闭粒子与震屏，保留形状轮廓）、Notifications。静音开关（iPhone 侧键）开启时遵循系统，只保留震动。

## 8.8 回收（熔炼）

```
+--------------------------------------+
| RACK FULL - PICK ONE TO SMELT        |
|--------------------------------------|
| ( ) Copper Needle      +4 Ore        |
| ( ) Copper Broadsword  +4 Ore  [Lock]|
| (x) Copper Needle.Ember +6 Ore       |
|     Rune Stone is lost.              |
|--------------------------------------|
|    [Keep forging]    [Smelt & Deliver]|
+--------------------------------------+
```

熔炼后显示 5 s 的 Toast：`smelt_done` “Smelted {name}. +{ore} Ore” + **Undo**。

## 8.9 商店

```
+--------------------------------------+
| < Back              SHOP             |
| OFFERS                               |
|  .--------------------------------.  |
|  | Smith's Starter Kit    $0.99*  |  |
|  | 300 Gems, 5 Rune Stones,       |  |
|  | Ember Anvil skin. Once only.   |  |
|  '--------------------------------'  |
| SUPPLIES                             |
|  Forge Supply Box (weekly)   $1.99*  |
| GEMS                                 |
|  60  $0.99*   330  $4.99*  780 ...   |
| MORE                                 |
|  Skip Ads, Keep Rewards      $4.99*  |
|  Quick Loot (2h)      50 G   [2/3]   |
|--------------------------------------|
|  Restore Purchases   Terms  Privacy  |
+--------------------------------------+
```

`*` 处显示 StoreKit 返回的本地化价格（不硬编码；线框以美国区价格档为例）。人民币测试价与内容见 [9.3](09-monetization.md#93-候选商品逐项规格)。商店**只能由玩家主动进入**，例外见 [9.4](09-monetization.md#94-展示规则)。

## 8.10 工坊

```
+--------------------------------------+
| < Back            WORKSHOP           |
| ANVIL      Lv 4   Strikes 9 -> 10    |
|            Unlocks Quick Forge       |
|                     [Upgrade  790 C] |
| FURNACE    Lv 4   Iron 17 -> 20      |
|            Reforge to use new metal  |
|                     [Upgrade 1,050 C]|
| BARRACKS   Lv 3   HP 139 -> 164      |
|                     [Upgrade  340 C] |
+--------------------------------------+
```

## 8.11 注意力在锻造台与战场之间如何切换

| 规则 | 说明 |
|---|---|
| 战斗从不要求输入 | 唯一需要玩家点的战斗节点是 Boss Gate 的 Fight（会等待），以及失败报告（5 s 后自动进入练习） |
| 锻造从不限时 | 锻造时战斗继续，但不会因为锻造慢而错过任何东西 |
| 接缝提示条 | 战场上的关键事件同时写到分屏线上，眼睛不用离开下半屏 |
| 触感代替视线 | HP < 30%、波次清空、Boss 预警都有不同的震动（8.7），玩家盯着铁砧时也能感知 |
| 何时该抬头 | 交付后的前 3 击（形状轮廓加强），以及 Boss Gate。这两个时刻下半屏会把亮度降低 30%，引导视线上移 |
| 不自动暂停 | 除了 Boss Gate 与教程的第一次阻塞引导，不做任何自动暂停 |

## 8.12 关键状态提示与操作反馈

| 状态 | 提示（英文 ID） | 位置 |
|---|---|---|
| Ore 不够锻造 | `err_not_enough_ore` | Forge 按钮下方 |
| 没有符文石 | `err_no_rune_stones` | 符文选择条 |
| 区域已满 | `forge_zone_max` | 区域旁 |
| 预算没用完 | `forge_unused_confirm` | 确认框 |
| 形态将改变 | `forge_form_change_warn` | 对比面板 |
| 武器架已满 | `rack_full_pick` | 交付前 |
| 换装冷却中 | `swap_cooldown` “Ready in {seconds}s” | Rack 按钮 |
| 设施被关卡锁住 | `upgrade_locked_stage` | 工坊卡片 |
| Coins 不够升级 | `err_not_enough_coins` | 工坊卡片（按钮置灰） |
| Cart 已满 | `cart_full` | 顶栏 Cart 图标 |
| 广告次数用完 | `ad_limit_reached` | 广告按钮 |
| 广告加载失败 | `ad_not_ready` | 广告按钮 |
| 购买处理中 / 失败 / 恢复完成 | `iap_pending` / `iap_failed` / `iap_restored` | 商店 |
| 存档失败 | `err_save_failed` | 全局 Toast |
| 网络不可用（不影响游戏） | `net_offline` | 只在商店、广告入口显示 |

## 8.13 误触处理

| 场景 | 防护 |
|---|---|
| 敲错区域 | Undo（不限次），Reset（需确认）；区域之间留 8 pt 死区 |
| 锻到一半不想要了 | Cancel 完全无损 |
| 预算没用完就点了 Finish | 二次确认 |
| 连点 Deliver / Upgrade / 购买 | 500 ms 防抖；购买走系统支付确认 |
| 误熔炼 | 确认 + 5 s Undo；上锁武器不进入熔炼列表 |
| 误换装 | 3 s 冷却，冷却环可见；换装只花 0.5 s，代价低 |
| 误跳过 Boss Gate | Fight 按钮位于卡片右下，不在锻造区的常用位置上 |
| 广告误触 | 广告按钮全部带 “Watch ad” 字样与图标；任何广告都需要玩家主动点击 |

## 8.14 设置一览

| 设置（英文） | 选项 | 默认 |
|---|---|---|
| Music / Sound | 0–100% | 70% / 100% |
| Haptics | Off / Light / Full | Full |
| Rhythm | On / Relaxed / Off | On |
| Reduce Effects | On / Off | Off |
| Auto-equip New Weapons | On / Off | On |
| Auto-advance | On / Off | On |
| Auto-start Boss | On / Off | Off |
| Notifications | On / Off（首次在 Cart 上线时请求系统权限） | — |
| Restore Purchases / Support / Privacy / Terms | — | — |
