import GoblinForgeCore
import XCTest
@testable import GoblinForge

/// 宿主 App 内的集成测试：规则包已链接、文案表已打包且按 PRD 规则取值。
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
}
