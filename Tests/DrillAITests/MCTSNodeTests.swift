import XCTest
@testable import DrillAI


final class DummyState: MCTSState {
    typealias Action = Int
    func getLegalActions() -> [Int] {
        return [1, 2, 3]
    }
    func getNextState(for: Int) -> DummyState {
        return DummyState()
    }
}


final class MCTSNodeTests: XCTestCase {

    func testNodeWithExplicitParentCanTraceBackToParent() throws {
        let state = DummyState()
        let parent = MCTSNode(state: state)
        let child = MCTSNode(state: state, parent: parent, indexInParent: 0)

        XCTAssertIdentical(parent, child.parent)
    }

    func testNewNodesHaveNoAction() throws {
        let state = DummyState()
        let node = MCTSNode(state: state)
        XCTAssertFalse(node.isExpanded)
        XCTAssertEqual(node.children.count, 0)
    }

    func testNodesAreSetAsExpandedAfterExpand() throws {
        let state = DummyState()
        let node = MCTSNode(state: state)

        XCTAssertFalse(node.isExpanded)
        node.expand()
        XCTAssertTrue(node.isExpanded)
    }

    func testExpandedNodesHaveNextActions() throws {
        let state = DummyState()
        let node = MCTSNode(state: state)

        node.expand()
        XCTAssertTrue(node.nextActions.count > 0)
    }

    // TBD: value calculation and child selection testing
}
