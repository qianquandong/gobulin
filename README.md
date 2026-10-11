# 哥布林打铁铺 · *Goblin Forge*

iPhone 竖屏单手游戏：下半屏点击锻造，上半屏英雄自动战斗。锻造选择会改变英雄的攻击形状、节奏和触发效果。

## 仓库内容

| 路径 | 内容 |
|---|---|
| [docs/prd/00-two-week-prototype.md](docs/prd/00-two-week-prototype.md) | **当前开发范围**：两周原型、试玩协议与继续/停止标准 |
| [docs/prd/README.md](docs/prd/README.md) | **PRD 入口**：一页摘要、文档地图、标记约定、术语表 |
| [docs/prd/](docs/prd/) | 两周原型 + 12 章正文 + 一致性检查 + 玩家可见英文文案表 |
| [docs/balance/sim_output.md](docs/balance/sim_output.md) | 数值模拟器输出快照（PRD 中所有表格的数字来源） |
| [tools/balance_sim.py](tools/balance_sim.py) | 数值模拟器：锻造公式、20 Hz 战斗模拟、关卡验证、资源路径 |
| [tools/check_prd.py](tools/check_prd.py) | 一致性检查：PRD 数字与模拟器一致、文档内链接与锚点有效、文案 ID 已登记 |

## 常用命令

需要 Python 3.10+，不依赖第三方库。

```bash
python tools/balance_sim.py all
```

```bash
python tools/check_prd.py
python -m unittest discover -s tools -p "test_*.py"
```

修改任何数值的流程：改 `tools/balance_sim.py` → 重跑并更新 `docs/balance/sim_output.md` → 同步 PRD 表格 → 运行 `check_prd.py` 直到全部通过。

## 语言约定

- 文档、设计说明、开发任务、验收标准：中文。
- 所有玩家可见内容（界面、教程、对白、商品、商店页）：英文，统一登记在 [docs/prd/strings.md](docs/prd/strings.md)。
