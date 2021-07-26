import XCTest
@testable import DrillAI

final class GameStateTests: XCTestCase {

    func testInitiatingStateWithLessThan8Garbages() throws {
        let state = GameState(garbageCount: 5)
        XCTAssertEqual(state.field.height, 5)
        XCTAssertEqual(state.field.garbageCount, 5)
    }

    func testInitiatingStateWithMoreThan8GarbagesHasFieldWith8Garbages() throws {
        let state = GameState(garbageCount: 12)
        XCTAssertEqual(state.field.height, 8)
        XCTAssertEqual(state.field.garbageCount, 8)
    }
}
