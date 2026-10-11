import XCTest

/// M0-03 / QA T-03（模拟器部分）：首分钟锻出 Broad 并真实横扫 ≥ 3；锻造 Undo/Reset/Cancel 无残留；
/// 学习题失败显示方向，迁移题失败只保留主因、不显示任何提示。真机与真人部分不在此证明。
final class PrototypeUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    private func launch(_ caseID: String, startWeapon: String? = nil) {
        app.launchArguments = ["-gf-case", caseID, "-gf-participant", "UITEST"] + (startWeapon.map { ["-gf-rack", $0] } ?? [])
        app.launch()
        XCTAssertTrue(app.buttons["forge.zone.blade"].waitForExistence(timeout: 20))
    }

    private func strike(_ zone: String, _ times: Int) {
        for _ in 0..<times {
            app.buttons["forge.zone.\(zone)"].tap()
            usleep(180_000)   // 有效敲击最小间隔 0.15 s
        }
    }

    private func probe(_ key: String) -> String? {
        let label = app.staticTexts["debug.probe"].label
        return label.split(separator: " ").first { $0.hasPrefix("\(key)=") }.map { String($0.dropFirst(key.count + 1)) }
    }

    private func waitForProbe(_ key: String, _ value: String, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if probe(key) == value { return true }
            usleep(250_000)
        }
        return false
    }

    private func attach(_ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testDemoBroadsideSweepsAtLeastThree() {
        launch("demo")
        XCTAssertEqual(app.staticTexts["forge.remaining"].label, "7 strikes left")
        strike("blade", 3)
        XCTAssertTrue(app.staticTexts["forge.warn"].exists, "Blade 3 warns that the next strike changes the form")
        strike("blade", 1)
        XCTAssertEqual(app.staticTexts["forge.form"].label, "BROAD")
        strike("hilt", 3)
        attach("M0-demo-forge-preview")
        app.buttons["forge.deliver"].tap()
        XCTAssertTrue(waitForProbe("goal", "1", timeout: 90), "a delivered Broad must hit 3+ enemies in one swing")
        XCTAssertTrue(app.buttons["card.next"].waitForExistence(timeout: 5))
        attach("M0-demo-sweep")
    }

    func testForgeUndoResetCancelLeaveNoResidue() {
        launch("learn_swarm")
        XCTAssertEqual(app.staticTexts["forge.remaining"].label, "10 strikes left")
        strike("blade", 4)
        XCTAssertEqual(app.staticTexts["forge.remaining"].label, "6 strikes left")
        XCTAssertEqual(app.staticTexts["forge.form"].label, "BROAD")
        app.buttons["forge.undo"].tap()
        XCTAssertEqual(app.staticTexts["forge.remaining"].label, "7 strikes left")
        XCTAssertEqual(app.staticTexts["forge.form"].label, "NEEDLE")
        app.buttons["forge.reset"].tap()
        app.alerts.buttons["Reset"].tap()
        XCTAssertEqual(app.staticTexts["forge.remaining"].label, "10 strikes left")
        strike("rune", 1)
        XCTAssertEqual(app.staticTexts["forge.remaining"].label, "10 strikes left", "RUNE needs an element first")
        app.buttons["forge.rune.ember"].tap()
        strike("rune", 2)
        strike("hilt", 1)
        XCTAssertEqual(app.staticTexts["forge.remaining"].label, "7 strikes left")
        app.buttons["forge.cancel"].tap()
        XCTAssertEqual(app.staticTexts["forge.remaining"].label, "10 strikes left")
        XCTAssertEqual(app.buttons["forge.zone.rune"].value as? String, "0")
    }

    /// Great 打不破护盾：学习题失败报告显示方向，迁移题不显示任何提示（PRD 0.4、5.8 测试模式覆盖规则）。
    /// 起始武器直接设为 Great B8/H2（Debug 参数 -gf-rack），失败路径可确定复现；锻造交付由首分钟用例覆盖。
    func testDefeatTipShownInLearningButNotInTransfer() {
        for (caseID, expectTip) in [("learn_guard", true), ("transfer_guard_swarm", false)] {
            launch(caseID, startWeapon: "8/2/0")
            XCTAssertTrue(app.staticTexts["card.defeat"].waitForExistence(timeout: 120), caseID)
            XCTAssertTrue(app.staticTexts["card.cause"].label.hasPrefix("Guard blocked"), app.staticTexts["card.cause"].label)
            XCTAssertEqual(app.staticTexts["card.tip"].exists, expectTip, caseID)
            XCTAssertEqual(probe("hints"), expectTip ? "1" : "0", caseID)
            if !expectTip {
                XCTAssertFalse(app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH 'Good vs'")).firstMatch.exists)
                XCTAssertTrue(app.staticTexts["hud.try"].exists)
                XCTAssertEqual(app.staticTexts["hud.try"].label, "Try 1/3")
                attach("M0-defeat-\(caseID)")
                app.buttons["card.retry"].tap()
                XCTAssertTrue(waitForProbe("attempt", "2", timeout: 5))
                XCTAssertEqual(app.staticTexts["hud.try"].label, "Try 2/3")
                continue
            }
            attach("M0-defeat-\(caseID)")
            app.terminate()
        }
    }
}
