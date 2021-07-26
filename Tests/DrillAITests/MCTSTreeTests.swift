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

        _ = await tree.getNextUnevaluatedStates(targetCount: 32)
        let count2 = await tree.getOutstandingEvaluationsCount()
        XCTAssertEqual(count2, 33)

        _ = await tree.getNextUnevaluatedStatesWithExtendedInfo(targetCount: 32)
        let count3 = await tree.getOutstandingEvaluationsCount()
        XCTAssertEqual(count3, 65)
    }

    func testSettingEvaluationForRootNodeRemovesOutstandingCount() async throws {
        let state = MockState()
        let tree = MCTSTree(initialState: state)

        let info = await tree.getNextUnevaluatedStates()

        let results: MCTSTree.EvaluationResults = [(id: info[0].id, value: 1.0, priors: nil)]
        await tree.updateWithEvaluationResults(results)

        let count = await tree.getOutstandingEvaluationsCount()
        XCTAssertEqual(count, 0)
    }

    func testGettingEvaluationTargetForActionlessRootGivesNothing() async throws {
        let state = MockState()
        state.makeActionsAction = { _ in [] }
        let tree = MCTSTree(initialState: state)

        // First call gets root
        _ = await tree.getNextUnevaluatedStates()

        // Second call should have nothing
        let info2 = await tree.getNextUnevaluatedStates()
        XCTAssertEqual(info2.count, 0)
    }

    func testSettingEvaluationResultsRevertsVisitCounts() async throws {
        let state = MockState()
        // Mock will only have one level of children
        state.makeActionsAction = { key in
            if key == 0 {
                return [1, 2, 3]
            } else {
                return []
            }
        }
        let tree = MCTSTree(initialState: state)

        // We should find all 4 nodes in the tree, but internally it'll attempt
        // more than 32 searches (74 to be exact, so totalVisitCount would be 73)
        let info = await tree.getNextUnevaluatedStates(targetCount: 32)
        XCTAssertEqual(info.count, 4)

        let orderedActions = await tree.getOrderedRootActions()
        let totalVisitCount = orderedActions.map(\.1).reduce(0, +)
        XCTAssertGreaterThanOrEqual(totalVisitCount, 31)

        // Set evaluations for all 4 nodes and we should none outstanding
        let results: MCTSTree.EvaluationResults = info.map { item in
            (id: item.id, value: 0.2, priors: nil)
        }

        await tree.updateWithEvaluationResults(results)
        let outstanding = await tree.getOutstandingEvaluationsCount()
        XCTAssertEqual(outstanding, 0)

        // ...and the visit counts are properly reverted
        let updatedActions = await tree.getOrderedRootActions()
        XCTAssertEqual(updatedActions.count, 3)
        XCTAssertEqual(updatedActions.map(\.1), [1.0, 1.0, 1.0])
    }
}
