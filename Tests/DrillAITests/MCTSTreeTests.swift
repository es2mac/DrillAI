import XCTest
@testable import DrillAI

final class MCTSTreeTests: XCTestCase {

    func testNewTreeGivesInitialStateForEvaluation() async throws {
        let state = DummyState()
        let tree = MCTSTree(initialState: state)

        let info = await tree.getNextUnevaluatedStates()
        XCTAssertIdentical(info[0].state, state)
    }
}
