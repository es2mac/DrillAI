import XCTest
@testable import DrillAI


final class MockState: MCTSState {
    typealias Action = Int
    let value: Int
    func getLegalActions() -> [Int] {
        return [1, 2, 3].map { $0 + value * 10}
    }
    func getNextState(for action: Int) -> MockState {
        return MockState(value: action)
    }
    init(value: Int = 0) { self.value = value }
}

extension MockState: CustomDebugStringConvertible {
    var debugDescription: String {
        "Dummy State \(value)"
    }
}


final class MCTSNodeTests: XCTestCase {

    func testNodeWithExplicitParentCanTraceBackToParent() throws {
        let state = MockState()
        let parent = MCTSNode(state: state)
        let child = MCTSNode(state: state, parent: parent, indexInParent: 0)

        XCTAssertIdentical(parent, child.parent)
    }

    func testNewNodesHaveNoAction() throws {
        let state = MockState()
        let node = MCTSNode(state: state)
        XCTAssertEqual(node.status, .initial)
        XCTAssertEqual(node.children.count, 0)
    }

    func testNodesAreSetAsExpandedAfterExpand() throws {
        let state = MockState()
        let node = MCTSNode(state: state)

        XCTAssertEqual(node.status, .initial)
        node.expand()
        XCTAssertEqual(node.status, .expanded)
    }

    func testExpandedNodesHaveNextActions() throws {
        let state = MockState()
        let node = MCTSNode(state: state)

        node.expand()
        XCTAssertTrue(node.nextActions.count > 0)
    }

    func testExpandedNodesHaveStatisticsInitialized() throws {
        let state = MockState()
        let node = MCTSNode(state: state)

        node.expand()
        let count = node.nextActions.count
        XCTAssertTrue(count > 0)
        XCTAssertEqual(node.priors.count, count)
        XCTAssertEqual(node.childN.count, count)
        XCTAssertEqual(node.childW.count, count)
    }

    func testGetMostVisitedChildReturnsNilWhenNoVisit() throws {
        let state = MockState()
        let node = MCTSNode(state: state)
        node.expand()

        XCTAssertNil(node.getMostVisitedChild())
    }

    func testGetBestSearchTargetChildReturnsNilWhenNotExpanded() throws {
        let state = MockState()
        let node = MCTSNode(state: state)

        XCTAssertNil(node.getBestSearchTargetChild())
    }

    func testGetBestSearchTargetChildReturnsSomethingAfterExpanded() throws {
        let state = MockState()
        let node = MCTSNode(state: state)

        node.expand()
        XCTAssertNotNil(node.getBestSearchTargetChild())
    }

    func testGetBestSearchTargetWithoutEvaluationFindsRandomChild() throws {
        let state = MockState()
        let node = MCTSNode(state: state)

        node.expand()

        node.childW = [1, 1, 1]
        node.childN = [2, 1, 2]

        // Don't know what's a better way to test this, but if it's really random,
        // I should get different results if I run it a bunch of times
        var foundValues = Set<Int>()
        for _ in 0 ..< 20 {
            if let value = node.getBestSearchTargetChild()?.state.value {
                foundValues.insert(value)
            }
        }
        XCTAssertTrue(foundValues.count > 1)
    }

    func testSettingEvaluatedSetsNodeAsEvaluated() throws {
        let state = MockState()
        let node = MCTSNode(state: state)

        XCTAssertEqual(node.status, .initial)

        node.expand()
        XCTAssertEqual(node.status, .expanded)

        node.setEvaluated(priors: [1, 2, 3])
        XCTAssertEqual(node.status, .evaluated)
    }

    func testSettingEvaluatedWithoutPriorsGenerateDefaultPriors() throws {
        let state = MockState()
        let node = MCTSNode(state: state)
        node.expand()

        node.setEvaluated()
        XCTAssertEqual(node.priors.count, 3)
        for prior in node.priors {
            XCTAssertEqualWithAccuracy(prior, 0.333, accuracy: 0.01)
        }
    }

    func testGetBestSearchTargetFindsLeastVisitedChild() throws {
        let state = MockState()
        let node = MCTSNode(state: state)
        node.expand()

        node.childW = [1, 1, 1]
        node.childN = [2, 1, 2]
        node.setEvaluated(priors: [1, 1, 1])

        let target = node.getBestSearchTargetChild()
        XCTAssertEqual(target?.state.value, 2)
    }

    func testGetBestSearchTargetFindsHighestValuedChild() throws {
        let state = MockState()
        let node = MCTSNode(state: state)
        node.expand()

        node.childW = [1, 1, 2]
        node.childN = [2, 2, 2]
        node.setEvaluated(priors: [1, 1, 1])

        let target = node.getBestSearchTargetChild()
        XCTAssertEqual(target?.state.value, 3)
    }

    func testGetMostVisitedChildReturnsVisitedChild() throws {
        let state = MockState()
        let node = MCTSNode(state: state)
        node.expand()

        node.childW = [1, 2, 1]
        node.childN = [2, 2, 2]
        node.setEvaluated(priors: [1, 1, 1])

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
