import XCTest

/// BOOT-01 冒烟：冷启动显示英文标题与开始提示，战场 SpriteKit 视图存在；截图作为附件保存。
final class LaunchUITests: XCTestCase {
    func testColdLaunchShowsEnglishTitle() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["title.name"].waitForExistence(timeout: 20))
        XCTAssertEqual(app.staticTexts["title.name"].label, "Goblin Forge")
        XCTAssertEqual(app.staticTexts["title.tap"].label, "Tap to start")
        XCTAssertTrue(app.otherElements["battlefield"].exists || app.images["battlefield"].exists
                      || app.descendants(matching: .any)["battlefield"].exists)
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "BOOT-01-launch"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
