import XCTest
@testable import GoblinForgeCore

final class CoreInfoTests: XCTestCase {
    func testLogicRunsAtTwentyHertz() {
        XCTAssertEqual(CoreInfo.logicStep, 0.05)
        XCTAssertEqual(CoreInfo.calcVersion, 1)
    }
}
