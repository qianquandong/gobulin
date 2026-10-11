import XCTest

/// 冷启动冒烟：主持人设置页（英文），输入编号并选择题序后进入首分钟演示，可立即敲铁砧。
final class LaunchUITests: XCTestCase {
    func testColdLaunchShowsHostSetupThenDemo() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["host.title"].waitForExistence(timeout: 20))
        XCTAssertEqual(app.staticTexts["host.title"].label, "Session Setup")
        let field = app.textFields["host.participant"]
        field.tap()
        field.typeText("P99")
        app.buttons["host.proto_order_b"].tap()
        attach(app, "M0-host-setup")
        app.buttons["host.start"].tap()
        XCTAssertTrue(app.buttons["forge.zone.blade"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["hud.hp"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["hud.hp"].label, "HP 100/100")
        attach(app, "M0-demo-start")
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
