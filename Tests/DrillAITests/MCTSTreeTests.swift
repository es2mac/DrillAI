import XCTest
@testable import DrillAI

final class MCTSTreeTests: XCTestCase {

    func testNewTreeGivesInitialStateForEvaluation() async throws {
        let state = MockState()
        let tree = MCTSTree(initialState: state)

        let info = await tree.getNextUnevaluatedStates(targetCount: 1)
        XCTAssertEqual(info.count, 1)
        XCTAssertIdentical(info[0].state, state)
    }

    func testGetUnevaluatedStateReceivesActions() async throws {
        let state = MockState()
        let tree = MCTSTree(initialState: state)

        let info = await tree.getNextUnevaluatedStates()
        XCTAssertEqual(info[0].nextActions, [1, 2, 3])
    }

    func testGetMultipleUnevaluatedStates() async throws {
        let state = MockState()
        let tree = MCTSTree(initialState: state)

        let info = await tree.getNextUnevaluatedStates(targetCount: 32)
        let ids = Set(info.map(\.id))
//        info.forEach { print($0) }
        XCTAssertEqual(info.count, 32)
        XCTAssertEqual(ids.count, 32)
    }

    func testOrderedRootActionsHaveCorrectForm() async throws {
        let state = MockState()
        let tree = MCTSTree(initialState: state)

        _ = await tree.getNextUnevaluatedStates(targetCount: 32)
        let orderedActions = await tree.getOrderedRootActions()
        XCTAssertEqual(orderedActions.count, 3)
        XCTAssertGreaterThanOrEqual(orderedActions[0].visits, orderedActions[1].visits)
        XCTAssertGreaterThanOrEqual(orderedActions[1].visits, orderedActions[2].visits)
        XCTAssertEqual(orderedActions.map(\.visits).reduce(0, +), 32 - 1)
    }
}
