# balance_sim.py 输出快照

> 由 `python tools/balance_sim.py all` 生成（2026-10-11，PRD v0.2）。章节1–5保留自然参考路径与战斗数值；章节6新增补助和全来源上限。M0新场景和真实登录事件进度不在此快照的验证范围。改数值后更新快照与PRD，再运行 `python tools/check_prd.py`。

## 1. 锻造算例（对应 PRD 4.9）

| Example | MD | B/H/R | Temper | Form | H per hit | Interval s | Single-target DPS | Rune every N swings |
|---|---|---|---|---|---|---|---|---|
| E1 tutorial forge 1 | 10 | 2/2/0  | 1 | Needle | 12 | 0.86 | 14.0 | - |
| E2 tutorial forge 2 (Broad) | 10 | 4/3/0  | 2 | Broad | 13 | 1.07 | 12.1 | - |
| E3 tutorial forge 3 (Needle+Ember) | 12 | 3/1/3 Ember | 2 | Needle | 16 | 0.93 | 17.2 | 3 |
| E4 first Great (stage 7) | 12 | 8/0/0  | 3 | Great | 31 | 2.3 | 13.5 | - |
| E5 Ironhide answer | 20 | 3/4/3 Ember | 5 | Needle | 27 | 0.72 | 37.5 | 3 |
| E6 Quick Forge, Temper 0 | 28 | 3/5/3 Spark | 0 | Needle | 36 | 0.65 | 55.4 | 3 |
| E7 no rune, 2 strikes unused | 24 | 3/6/0  | 4 | Needle | 32 | 0.58 | 55.2 | - |

## 2. 单目标参考矩阵（MD 20、预算 10、Temper 3）

| Build | H | Interval s | DPS armor 0 | DPS armor 12 | DPS armor 20 | Burn DPS (Ember, steady) | Swings to break 3 Guard pips |
|---|---|---|---|---|---|---|---|
| Needle B3/H6/R0 | 27 | 0.58 | 46.6 | 25.9 | 12.1 | 0.0 | 3 |
| Broad B4/H6/R0 | 26 | 0.78 | 33.3 | 17.9 | 7.7 | 0.0 | 3 |
| Great B8/H2/R0 | 52 | 1.98 | 26.3 | 20.2 | 16.2 | 0.0 | never (interval > 1.5 s regen) |
| Needle B3/H4/R3 Ember | 27 | 0.72 | 51.5 | 34.8 | 23.7 | 14.0 | 3 |
| Broad B4/H3/R3 Spark | 26 | 1.07 | 24.3 | 13.1 | 5.6 | 0.0 | 3 |
| Great B8/H1/R1 Frost | 52 | 2.14 | 24.3 | 18.7 | 15.0 | 0.0 | never (interval > 1.5 s regen) |

## 3. 关卡验证（期望状态，每格 3 个随机种子）

| Stage | State A/F/B | Budget | MD | Hero HP | Best single build | Result | Worst build | Result | 2-weapon rack (if no single build wins 3/3) |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 1/1/1 | 6 | 10 | 100 | Broad B4/H2/R0 | Win 3/3, 24s, HP 92% | Needle B3/H3/R0 | Win 3/3, 27s, HP 91% |  |
| 2 | 1/1/1 | 6 | 10 | 100 | Broad B4/H2/R0 | Win 3/3, 28s, HP 92% | Needle B3/H3/R0 | Win 3/3, 32s, HP 82% |  |
| 3 | 2/1/1 | 7 | 10 | 100 | Broad B4/H3/R0 | Win 3/3, 30s, HP 74% | Needle B3/H4/R0 | Win 0/3 (dead at wave 2, 26s) |  |
| 4 | 2/2/1 | 7 | 12 | 100 | Broad B4/H3/R0 | Win 3/3, 32s, HP 62% | Needle B3/H4/R0 | Win 3/3, 42s, HP 17% |  |
| 5 | 2/2/1 | 7 | 12 | 100 | Broad B4/H3/R0 | Win 3/3, 49s, HP 46% | Needle B3/H4/R0 | Win 0/3 (dead at wave 3, 49s) |  |
| 6 | 2/2/2 | 7 | 12 | 118 | Needle B3/H1/R3 Ember | Win 3/3, 50s, HP 40% | Broad B4/H3/R0 | Win 0/3 (dead at wave 3, 57s) |  |
| 7 | 3/2/2 | 8 | 12 | 118 | Great B8/H0/R0 | Win 3/3, 39s, HP 80% | Needle B3/H5/R0 | Win 0/3 (dead at wave 2, 40s) |  |
| 8 | 4/4/3 | 9 | 17 | 139 | Broad B4/H5/R0 | Win 3/3, 45s, HP 46% | Great B8/H0/R1 Ember | Win 0/3 (dead at wave 1, 22s) |  |
| 9 | 4/5/3 | 9 | 20 | 139 | Broad B4/H3/R2 Ember | Win 3/3, 43s, HP 36% | Great B8/H0/R1 Ember | Win 0/3 (dead at wave 3, 39s) |  |
| 10 | 5/5/4 | 10 | 20 | 164 | Needle B3/H4/R3 Ember | Win 3/3, 68s, HP 34% | Great B8/H2/R0 | Win 0/3 (dead at wave 2, 38s) |  |
| 11 | 5/5/4 | 10 | 20 | 164 | Broad B4/H6/R0 | Win 3/3, 39s, HP 48% | Great B8/H1/R1 Frost | Win 0/3 (dead at wave 1, 20s) |  |
| 12 | 5/6/5 | 10 | 24 | 194 | Broad B4/H6/R0 | Win 3/3, 54s, HP 33% | Great B8/H1/R1 Frost | Win 0/3 (dead at wave 1, 24s) |  |
| 13 | 6/6/5 | 11 | 24 | 194 | Broad B4/H4/R3 Spark | Win 3/3, 34s, HP 68% | Great B8/H3/R0 | Win 0/3 (dead at wave 2, 32s) |  |
| 14 | 6/6/5 | 11 | 24 | 194 | Broad B4/H4/R3 Ember | Win 2/3 (dead at wave 3, 51s) | Great B8/H2/R1 Frost | Win 0/3 (dead at wave 2, 37s) | Rack swap: Great B8/H3/R0 → Needle B3/H5/R3 Spark → Needle B3/H5/R3 Spark: Win 3/3, HP 45% |
| 15 | 6/7/6 | 11 | 28 | 229 | Needle B3/H5/R3 Spark | Win 3/3, 48s, HP 70% | Great B8/H2/R1 Frost | Win 0/3 (dead at wave 1, 22s) |  |
| 16 | 7/7/6 | 12 | 28 | 229 | Great B8/H4/R0 | Win 3/3, 34s, HP 90% | Needle B3/H6/R0 | Win 0/3 (dead at wave 2, 40s) |  |
| 17 | 7/7/6 | 12 | 28 | 229 | Needle B3/H6/R3 Spark | Win 3/3, 56s, HP 16% | Great B8/H2/R2 Frost | Win 0/3 (dead at wave 1, 22s) |  |
| 18 | 7/8/7 | 12 | 33 | 270 | Great B8/H2/R2 Ember | Win 3/3, 36s, HP 91% | Needle B3/H6/R0 | Win 0/3 (dead at wave 2, 36s) |  |
| 19 | 8/8/7 | 13 | 33 | 270 | Needle B3/H6/R4 Spark | Win 3/3, 43s, HP 52% | Great B8/H3/R2 Frost | Win 0/3 (dead at wave 1, 26s) |  |
| 20 | 8/8/8 | 13 | 33 | 319 | Broad B7/H6/R0 | Win 3/3, 80s, HP 34% | Needle B3/H6/R0 | Win 0/3 (dead at wave 1, 34s) |  |

## 4. 资源路径（期望玩家，PRD 7.5）

| Stage | Upgrades bought (coins) | Forge ore / refund / stones | First clear coins/ore/stones | Farm min before stage | Balance after (coins/ore/stones) | Cumulative idle min | ≈ Day |
|---|---|---|---|---|---|---|---|
| 1 | - (0) | 6 / 0 / 0 | 30 / 6 / 0 | 0 | 30 / 20 / 0.0 | 0 | 1.0 |
| 2 | - (0) | 0 / 0 / 0 | 34 / 6 / 0 | 0 | 64 / 26 / 0.0 | 0 | 1.0 |
| 3 | A2 (40) | 6 / 0 / 0 | 38 / 7 / 0 | 0 | 62 / 27 / 0.0 | 0 | 1.0 |
| 4 | F2 (60) | 0 / 0 / 0 | 43 / 8 / 0 | 0 | 45 / 35 / 0.0 | 0 | 1.0 |
| 5 | - (0) | 0 / 0 / 0 | 147 / 8 / 2 | 0 | 192 / 43 / 2.0 | 0 | 1.0 |
| 6 | B2 (50) | 8 / 0 / 1 | 55 / 9 / 0 | 0 | 197 / 44 / 1.0 | 0 | 1.0 |
| 7 | A3 (110) | 8 / 4 / 0 | 62 / 10 / 0 | 0 | 149 / 50 / 1.0 | 0 | 1.0 |
| 8 | A4, F3, F4, B3 (990) | 30 / 10 / 0 | 71 / 10 / 1 | 119 | 71 / 44 / 2.3 | 119 | 1.1 |
| 9 | F5 (1050) | 18 / 6 / 0 | 80 / 11 / 0 | 126 | 80 / 48 / 2.7 | 244 | 1.3 |
| 10 | A5, B4 (1130) | 18 / 0 / 1 | 270 / 12 / 2 | 123 | 270 / 47 / 4.0 | 367 | 1.4 |
| 11 | - (0) | 0 / 0 / 0 | 102 / 13 / 0 | 0 | 372 / 60 / 4.0 | 367 | 1.4 |
| 12 | F6, B5 (3620) | 44 / 24 / 1 | 115 / 14 / 2 | 313 | 115 / 68 / 5.9 | 680 | 1.7 |
| 13 | A6 (2130) | 22 / 14 / 1 | 130 / 15 / 0 | 177 | 130 / 83 / 5.4 | 857 | 1.9 |
| 14 | - (0) | 0 / 0 / 0 | 147 / 16 / 0 | 0 | 277 / 99 / 5.4 | 857 | 1.9 |
| 15 | F7, B6 (9410) | 96 / 48 / 0 | 498 / 18 / 1 | 661 | 498 / 104 / 8.2 | 1518 | 2.6 |
| 16 | A7 (5740) | 0 / 0 / 0 | 188 / 19 / 0 | 345 | 188 / 143 / 9.2 | 1863 | 2.9 |
| 17 | - (0) | 0 / 0 / 0 | 212 / 21 / 0 | 0 | 400 / 164 / 9.2 | 1863 | 2.9 |
| 18 | F8, B7 (24470) | 76 / 42 / 1 | 240 / 22 / 0 | 1310 | 240 / 236 / 11.8 | 3173 | 4.3 |
| 19 | A8 (15500) | 38 / 25 / 0 | 271 / 24 / 0 | 755 | 271 / 297 / 13.9 | 3927 | 5.1 |
| 20 | B8 (15450) | 0 / 0 / 0 | 918 / 26 / 2 | 683 | 918 / 372 / 17.8 | 4610 | 5.8 |

## 5. 设施与关卡数值表（PRD 7.3 / 7.4）

| Level | Anvil budget | Anvil cost | Furnace metal | Metal base dmg | Ore per forge | Furnace cost | Hero HP | Barracks cost |
|---|---|---|---|---|---|---|---|---|
| 1 | 6 | - | Copper | 10 | 6 | - | 100 | - |
| 2 | 7 | 40 | Copper | 12 | 8 | 60 | 118 | 50 |
| 3 | 8 | 110 | Copper | 14 | 10 | 160 | 139 | 130 |
| 4 | 9 | 290 | Iron | 17 | 15 | 410 | 164 | 340 |
| 5 | 10 | 790 | Iron | 20 | 18 | 1050 | 194 | 880 |
| 6 | 11 | 2130 | Iron | 24 | 22 | 2740 | 229 | 2280 |
| 7 | 12 | 5740 | Steel | 28 | 32 | 7130 | 270 | 5940 |
| 8 | 13 | 15500 | Steel | 33 | 38 | 18530 | 319 | 15450 |
| 9 | 14 | 41840 | Steel | 39 | 45 | 48190 | 376 | 40160 |
| 10 | 14 | 112970 | Moonsilver | 46 | 65 | 125300 | 444 | 104410 |

| Stage | First clear coins | ore | stones | Idle coins/min | Idle ore/min |
|---|---|---|---|---|---|
| 1 | 30 | 6 | 0 | 4.0 | 0.025 |
| 2 | 34 | 6 | 0 | 4.4 | 0.027 |
| 3 | 38 | 7 | 0 | 4.84 | 0.028 |
| 4 | 43 | 8 | 0 | 5.32 | 0.03 |
| 5 | 147 | 8 | 2 | 5.86 | 0.032 |
| 6 | 55 | 9 | 0 | 6.44 | 0.033 |
| 7 | 62 | 10 | 0 | 7.09 | 0.035 |
| 8 | 71 | 10 | 1 | 7.79 | 0.038 |
| 9 | 80 | 11 | 0 | 8.57 | 0.04 |
| 10 | 270 | 12 | 2 | 9.43 | 0.042 |
| 11 | 102 | 13 | 0 | 10.37 | 0.045 |
| 12 | 115 | 14 | 2 | 11.41 | 0.047 |
| 13 | 130 | 15 | 0 | 12.55 | 0.05 |
| 14 | 147 | 16 | 0 | 13.81 | 0.053 |
| 15 | 498 | 18 | 1 | 15.19 | 0.057 |
| 16 | 188 | 19 | 0 | 16.71 | 0.06 |
| 17 | 212 | 21 | 0 | 18.38 | 0.064 |
| 18 | 240 | 22 | 0 | 20.22 | 0.067 |
| 19 | 271 | 24 | 0 | 22.24 | 0.071 |
| 20 | 918 | 26 | 2 | 24.46 | 0.076 |

## 6. 教程补助与全来源加速（PRD 7.6）

| Source | Extra Cart-equivalent minutes | Period / condition |
|---|---|---|
| Welcome back x2 | 960 | daily; two 480-minute base claims |
| Ad Quick Loot | 90 | daily; 3 x 30 |
| Gem Quick Loot | 360 | daily; 3 x 120 |
| All ads | 1050 | daily; excludes Daily Rune Stone |
| All ads + Gems | 1410 | daily; excludes weekly Supply Box |
| Supply Box Coins | 240 | weekly; Coins only |

Daily Rune Stone: +1 stone/day. Supply Box: choose Coins OR 6 stones OR 10 forge costs of Ore.
Bonuses are paid directly; they never enter the Cart and cannot be doubled again.
These are resource bounds at a fixed rate, not predicted days to Stage 20.

| Tutorial case (highest stage / Furnace / Ore / Stones) | Wallet after O/S | ore_paid | Ore / Stone subsidy |
|---|---|---|---|
| 2 / 1 / 0 / 0 | 0/0 | 0 | 6 / 0 |
| 5 / 2 / 2 / 0 | 0/0 | 2 | 6 / 1 |
