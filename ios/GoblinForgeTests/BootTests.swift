import GoblinForgeCore
import XCTest
@testable import GoblinForge

/// 宿主 App 内的集成测试：规则包已链接、文案表与场景配置已打包、交付卡片文案按 PRD 8.6。
@MainActor
final class BootTests: XCTestCase {
    func testCorePackageIsLinked() {
        XCTAssertEqual(CoreInfo.logicStep, 0.05)
    }

    func testStringTableComesFromPRD() {
        XCTAssertEqual(L10n.text("app_name"), "Goblin Forge")
        XCTAssertEqual(L10n.text("hud_hp", ["hp": "112", "max": "139"]), "HP 112/139")
        XCTAssertEqual(L10n.plural("forge_strikes_left", count: 1), "1 strike left")
        XCTAssertEqual(L10n.plural("forge_strikes_left", count: 0), "0 strikes left")
        XCTAssertEqual(L10n.text("no_such_id"), "‹no_such_id›")
    }

    func testEveryStringIDUsedByThePrototypeExists() {
        let ids = ["proto_host_title", "proto_participant", "proto_order", "proto_order_a", "proto_order_b", "proto_start",
                   "proto_resume", "proto_next", "proto_try", "proto_host_menu", "proto_skip", "proto_end", "proto_export",
                   "proto_interview", "proto_free_play", "proto_finish", "proto_done", "prototype_reason", "prototype_continue",
                   "hud_hp", "hud_wave", "time_left", "seam_next_wave", "smith_name", "deliver_changed", "victory_title",
                   "defeat_title", "btn_retry", "btn_undo", "btn_reset", "btn_cancel", "btn_deliver", "btn_finish", "btn_ok",
                   "btn_close", "btn_keep_forging", "rack_full_pick", "forge_reset_confirm", "forge_unused_confirm#one",
                   "forge_unused_confirm#other", "forge_strikes_left#other", "forge_zone_blade", "forge_zone_hilt",
                   "forge_zone_rune", "forge_zone_count", "forge_zone_max", "forge_rune_none", "forge_rune_pick_hint",
                   "forge_form_change_warn", "forge_form_broad", "forge_form_great", "forge_form_needle", "forge_compare_now",
                   "forge_compare_new", "stat_form", "stat_hits", "stat_hits_upto", "stat_damage", "stat_swing",
                   "stat_swing_value", "stat_rune", "rune_ember", "rune_effect_burn", "forge_rune_every#one",
                   "forge_rune_every#other", "weapon_equipped", "swap_cooldown", "hint_suggested", "combat_blocked",
                   "combat_hit_count", "weapon_name_pattern", "change_hits_more", "change_slower", "change_rune_new",
                   "tut_04", "tut_07", "tut_08", "tut_09", "tut_10", "defeat_cause_guard", "defeat_cause_armor",
                   "defeat_cause_swarm", "defeat_cause_timeout", "defeat_cause_outmatched", "defeat_tip_guard",
                   "defeat_tip_armor", "defeat_tip_wider", "defeat_tip_damage", "defeat_tip_upgrade",
                   "trait_swarm", "trait_armor", "trait_guard", "form_needle", "form_broad", "form_great",
                   "form_needle_noun", "form_broad_noun", "form_great_noun", "metal_copper", "metal_iron"]
        for id in ids { XCTAssertTrue(L10n.has(id), "missing \(id) in strings.json") }
    }

    func testBundledPrototypeConfig() {
        let config = PrototypeController.loadBundledConfig()
        XCTAssertEqual(config.cases.count, 6)
        XCTAssertEqual(config.demo?.id, "demo")
        XCTAssertEqual(config.transferOrders.count, 2)
    }

    func testDeliverCardLinesFollowPRD86() {
        let needle = Weapon(md: 10, blade: 2, hilt: 2, temper: 3)
        let broad = Weapon(md: 10, blade: 4, hilt: 3, temper: 3)
        XCTAssertEqual(PrototypeController.changeLines(from: needle, to: broad), ["Sweeps up to 6 enemies.", "Swings slower."])
        let ember = Weapon(md: 20, blade: 3, hilt: 4, runePoints: 3, rune: .ember, temper: 3)
        XCTAssertTrue(PrototypeController.changeLines(from: Weapon(md: 20, blade: 3, hilt: 6, temper: 3), to: ember)
            .contains("New: Burn every 3 swings"))
        XCTAssertEqual(WeaponText.name(broad), "Copper Broadsword")
    }
}
