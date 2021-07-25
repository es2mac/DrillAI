import XCTest
@testable import DrillAI

final class MCTSTreeTests: XCTestCase {

    func testNewTreeGivesInitialStateForEvaluation() async throws {
        let state = MockState()
        let tree = MCTSTree(initialState: state)

        let info = await tree.getNextUnevaluatedStates()
        XCTAssertIdentical(info[0].state, state)
    }

//    func testGetUnevaluatedStateReceivesActions() async throws {
//        let state = MockState()
//        let tree = MCTSTree(initialState: state)
//
//        let info = await tree.getNextUnevaluatedStates()
//        XCTAssertEqual(info[0].nextActions, [1, 2, 3])
//    }
}
