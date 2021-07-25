import XCTest
@testable import DrillAI


final class DummyState: MCTSState {
    typealias Action = Int
    let value: Int
    func getLegalActions() -> [Int] {
        return [10, 11, 12]
    }
    func getNextState(for action: Int) -> DummyState {
        return DummyState(value: action)
    }
    init(value: Int = 0) { self.value = value }
}

extension DummyState: CustomDebugStringConvertible {
    var debugDescription: String {
        "Dummy State \(value)"
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
        XCTAssertEqual(node.status, .initial)
        XCTAssertEqual(node.children.count, 0)
    }

    func testNodesAreSetAsExpandedAfterExpand() throws {
        let state = DummyState()
        let node = MCTSNode(state: state)

        XCTAssertEqual(node.status, .initial)
        node.expand()
        XCTAssertEqual(node.status, .expanded)
    }

    func testExpandedNodesHaveNextActions() throws {
        let state = DummyState()
        let node = MCTSNode(state: state)

        node.expand()
        XCTAssertTrue(node.nextActions.count > 0)
    }

    func testExpandedNodesHaveStatisticsInitialized() throws {
        let state = DummyState()
        let node = MCTSNode(state: state)

        node.expand()
        let count = node.nextActions.count
        XCTAssertTrue(count > 0)
        XCTAssertEqual(node.priors.count, count)
        XCTAssertEqual(node.childN.count, count)
        XCTAssertEqual(node.childW.count, count)
    }

    func testGetMostVisitedChildReturnsNilWhenNoVisit() throws {
        let state = DummyState()
        let node = MCTSNode(state: state)
        node.expand()

        XCTAssertNil(node.getMostVisitedChild())
    }

    func testGetBestSearchTargetChildReturnsNilWhenNotExpanded() throws {
        let state = DummyState()
        let node = MCTSNode(state: state)

        XCTAssertNil(node.getBestSearchTargetChild())
    }

    func testGetBestSearchTargetChildReturnsSomethingAfterExpanded() throws {
        let state = DummyState()
        let node = MCTSNode(state: state)

        node.expand()
        XCTAssertNotNil(node.getBestSearchTargetChild())
    }

    func testGetBestSearchTargetFindsLeastVisitedChild() throws {
        let state = DummyState()
        let node = MCTSNode(state: state)
        node.expand()

        node.childW = [1, 1, 1]
        node.childN = [2, 1, 2]

        let target = node.getBestSearchTargetChild()
        XCTAssertEqual(target?.state.value, 11)
    }

    func testGetBestSearchTargetFindsHighestValuedChild() throws {
        let state = DummyState()
        let node = MCTSNode(state: state)
        node.expand()

        node.childW = [1, 1, 2]
        node.childN = [2, 2, 2]

        let target = node.getBestSearchTargetChild()
        XCTAssertEqual(target?.state.value, 12)
    }

    func testGetMostVisitedChildReturnsVisitedChild() throws {
        let state = DummyState()
        let node = MCTSNode(state: state)
        node.expand()

        node.childW = [1, 2, 1]
        node.childN = [2, 2, 2]

        let target = node.getMostVisitedChild()
        // actually have not done any visit, despite having scores
        XCTAssertNil(target)

        // this should attempt to visit, and so initialize node 1
        let target2 = node.getBestSearchTargetChild()

        // Assume backprop happens, and this node's N increase by 1
        // which makes it the most visited child
        node.childN = [2, 3, 2]

        XCTAssertIdentical(node.getMostVisitedChild(), target2)
    }
}
