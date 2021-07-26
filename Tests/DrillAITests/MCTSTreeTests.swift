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

    func testGetUnevaluatedStatesWithExtendedInfo() async throws {
        let state = MockState()
        let tree = MCTSTree(initialState: state)

        let info = await tree.getNextUnevaluatedStatesWithExtendedInfo(targetCount: 32)
        let ids = Set(info.map(\.id))
        let lastActions = info.compactMap { $0.lastAction }

        XCTAssertEqual(info.count, 32)
        XCTAssertEqual(ids.count, 32)
        XCTAssertEqual(lastActions.count, 32 - 1)
    }

    func testGetOutstandingEvaluationsCount() async throws {
        let state = MockState()
        let tree = MCTSTree(initialState: state)

        _ = await tree.getNextUnevaluatedStatesWithExtendedInfo()
        let count1 = await tree.getOutstandingEvaluationsCount()
        XCTAssertEqual(count1, 1)

        _ = await tree.getNextUnevaluatedStatesWithExtendedInfo(targetCount: 32)
        let count2 = await tree.getOutstandingEvaluationsCount()
        XCTAssertEqual(count2, 33)

        _ = await tree.getNextUnevaluatedStatesWithExtendedInfo(targetCount: 32)
        let count3 = await tree.getOutstandingEvaluationsCount()
        XCTAssertEqual(count3, 65)

        async let x = tree.getOrderedRootActions()
        await print(x)
    }
}
