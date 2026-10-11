# 分批素材清单

截至 2026-10-11，以下均为 **PLANNED**，没有最终文件或实际导入证据。A0 的“占位”也需制作后再标完成。完整状态流：`PLANNED → DRAFT → READY_FOR_IMPORT → INTEGRATED → ACCEPTED`；退回用 `REWORK`。这不是游戏内容新增清单，完整数量沿用 [PRD 10.1](../prd/10-content-art-tech.md#101-mvp-内容清单p0)。

| 批次 / 最晚接入 | 稳定 ID 或 ID 前缀 | 交付范围 | 制作 / 导入 | 初始状态 |
|---|---|---|---|---|
| A0 / M0 D2 | `char_pip`, `char_gristle` | 简单分层占位各 1，握柄/锤击点参考；不做最终动画 | Codex / Claude | PLANNED |
| A0 / M0 D3 | `weapon_needle`, `weapon_broad`, `weapon_great` | 3 刀身、柄与 Ember 标志；小尺寸轮廓明确 | Codex / Claude | PLANNED |
| A0 / M0 D3 | `enemy_mushling`, `enemy_shellback`, `enemy_sprite` | 3 静态占位，甲壳与护盾状态独立 | Codex / Claude | PLANNED |
| A0 / M0 D4 | `bg_workshop`, `bg_mossy_hollow`, `ui_forge_core` | 工坊/战场简底、三分区与按钮/预览状态 | Codex / Claude | PLANNED |
| A0 / M0 D4 | `fx_form_outline_*`, `fx_hit_count`, `sfx_hammer_*` | 3 程序轮廓规范、命中数字、可用敲击声音/触感 | Codex 规范/音频来源；Claude 实现 | PLANNED |
| A1 / M1 | `char_pip`, `char_gristle` | 正式角色、PRD 10.1 状态；3 套攻击、Brace、交付 | Codex / Claude | PLANNED |
| A1 / M1 | `weapon_parts_*`, `enemy_*` | 正式部件武器、3 敌人的移动/攻击/受击/死亡 | Codex / Claude | PLANNED |
| A1 / M1 | `bg_workshop`, `bg_mossy_hollow`, `boss_queen` | 主场景、Queen 与必要预警/召唤表现 | Codex / Claude | PLANNED |
| A1 / M1 | `ui_core_*`, `fx_forge_*`, `fx_ember_*` | 锻造、失败、Rack、教程、核心特效 | Codex / Claude | PLANNED |
| A2 / M2 | `boss_ironhide`, `ui_progress_*` | Ironhide、工坊/设施/Cart/设置/Codex 图鉴/Quick Forge | Codex / Claude | PLANNED |
| A2 / M2 | `audio_core_*` | 原型占位替换为已核实来源的音效、区域 1 音乐 | Codex 选型/处理或外包；Claude 导入 | PLANNED |
| A3 / M4 | `bg_bramble_deep`, `boss_thornwarden`, `boss_ironthorn` | 第二场景、其余 Boss 与复用变体、Boss Gate | Codex / Claude | PLANNED |
| A3 / M4 | `fx_frost_*`, `fx_spark_*`, `audio_full_*` | 其余符文反馈、完整特效与音乐/音效 | Codex / Claude | PLANNED |
| A3 / M5 | `ui_shop_*`, `skin_ember_anvil` | 商店图、商品/免广告状态、首购外观 | Codex / Claude | PLANNED |
| A4 / M6 | `store_icon`, `store_screenshot_01..06` | 图标定稿、6 张真实截图的商店排版；预览视频可选 | Codex；Claude 导出真机画面 | PLANNED |

带 `*` 的行是工作包，制作该批前拆成逐资源记录，不能把一整包标 ACCEPTED 来掩盖缺项。M0 不为了补齐 A1–A4 延期。

## 每个实际资源必须补全的记录

```text
asset_id:
batch / version:
status: PLANNED
maker / importer / reviewer:
source_file_or_accessible_index:
export_files:
sha256:
canvas / pivot / display_size:
states_and_animation_events:
license_or_generation_provenance:
engine_import_settings:
device_build_used_for_review:
screenshot_or_video_evidence:
known_issues:
accepted_by / accepted_at:
```

未实际发生的字段留空或填 `NOT RUN`。生成来源记录用于追溯，不自动替代权利核实。最终包必须能按 asset_id 追到实际文件、来源、导入版本及真机验收。
