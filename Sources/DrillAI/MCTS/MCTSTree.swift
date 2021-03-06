//
//  MCTSTree.swift
//
//
//  Created by Paul on 7/23/21.
//

import Foundation


public actor MCTSTree<State: MCTSState> {
    public typealias Action = State.Action
    typealias Node = MCTSNode<State>

    /// The root should always be at least expanded
    private var root: Node

    /// Virtual loss is added for a node (using its id as key) every time it is
    /// selecetd for evaluation.  The virtual loss is reversed when the
    /// evaluation comes back.  This can also be thought of as a record of all
    /// nodes waiting for evaluation.
    private var virtualLosses: [ObjectIdentifier : (Node, Double)] = [:]

    public init(initialState: State) {
        root = Node(state: initialState)
        root.expand()
    }
}


extension MCTSTree {

    public struct ActionVisits {
        public let action: Action
        public let visits: Int
        public init(action: Action, visits: Int) {
            self.action = action
            self.visits = visits
        }
    }
    
    /// See the best actions so far, ordered by visit counts.  Empty when there is
    /// no action, i.e. terminal state.
    func getOrderedRootActions() -> [ActionVisits] {
        return zip(root.nextActions, root.childN)
            .sorted { $0.1 > $1.1 }
            .map { ActionVisits(action: $0, visits: Int($1)) }
    }

    /// See how many outstanding evaluations we're still expecting to get back, which
    /// is exactly the nodes that has a virtual loss waiting to be reverted.
    func getOutstandingEvaluationsCount() -> Int {
        virtualLosses.count
    }

    func promoteRoot(action: Action) -> State where Action: Equatable {
        cancelOutstandingEvaluations()

        if let index = root.nextActions.index(of: action) {
            let child = root.getOrInitializeChildNode(at: index)
            // Hackery to move large tree deallocation to the background
            let oldRoot = root
            Task.detached(priority: .medium) { _ = oldRoot }
            root = child
            root.removeParent()
            if case .initial = root.status {
                root.expand()
            }
        } else {
            assertionFailure("Not a valid next action")
        }
        return root.state
    }
}


public extension MCTSTree {
    typealias StatesInfo = [
        (id: ObjectIdentifier, state: State, nextActions: [Action])
    ]
    typealias EvaluationResults = [
        (id: ObjectIdentifier, value: Double, priors: [Double]?)
    ]

    /// Find a collection of unevaluated states most worth evaluating.  Any state
    /// returned from here has an ID, and expects the evaluation result for the state
    /// to return with that ID.  In the tree, the node corresponding to the state would
    /// have a virtual loss recorded, which is reverted once the results come back.
    /// The tree will try to find as many as `targetCount` nodes, but it might not
    /// find that many.
    func getNextUnevaluatedStates(targetCount: Int = 1) -> StatesInfo {
        let nodes = getNextUnevaluatedNodes(targetCount: targetCount)
        return nodes.map { node in
            (id: node.id, state: node.state, nextActions: node.nextActions)
        }
    }

    /// Update the tree with evaluation results.  Each result should be associated with
    /// a state that was gotten via the "get next unevaluated state" methods.
    /// Conversely, each state that went out from there is expected to come back with
    /// an evaluation.
    /// The evaluation may have just a value and no priors, in which case some default
    /// priors will be set (uniform with noise).
    func updateWithEvaluationResults(_ results: EvaluationResults) {
        for (id: id, value: value, priors: priors) in results {
            if let (node, virtualLoss) = virtualLosses.removeValue(forKey: id) {
                backPropagate(from: node,
                              value: -virtualLoss + value,
                              visits: 0)
                node.setEvaluated(priors: priors)
            } else { assertionFailure() }
        }
    }
}


private extension MCTSTree {

    /// Find leaf nodes for evaluation.  Since we want to get multiple nodes for
    /// parallel evaluation, each time we find a node we add either a virtual loss, or
    /// just a virtual visit, to encourage the next search to find something else.
    /// Keeping track of virtual losses also implies that once a node has been sent
    /// out here, it will not be sent out again until the evaluation result comes back
    /// and reverts the virtual loss.
    func getNextUnevaluatedNodes(targetCount: Int) -> [Node] {
        var nodes = [Node]()

        let maxAttemptCount = 10 + 2 * targetCount
        loop: for _ in 0 ..< maxAttemptCount {
            let node = getBestSearchTargetNode()
            switch node.status {
            case .initial:
                node.expand()
                fallthrough
            case .expanded:
                let (isNew, _) = addAndRecordVirtualLoss(node)
                if isNew {
                    nodes.append(node)
                    if nodes.count == targetCount {
                        break loop
                    }
                }
            case .evaluated:
                propagateOldValue(node)
            }
        }

        return nodes
    }

    /// Start from the root, drill down to find the most promising leaf for evaluation.
    /// This should generally return a node that is unevaluated (and often not expanded),
    /// but there is no guarantee.  We may find an evaluated node that is terminal and
    /// has no child.
    func getBestSearchTargetNode() -> Node {
        var node = root

        loop: while true {
            switch node.status {
            case .initial:
                break loop
            case .expanded:
                if let _ = virtualLosses[node.id] {
                    fallthrough
                } else {
                    break loop
                }
            case .evaluated:
                if let nextNode = node.getBestSearchTargetChild() {
                    node = nextNode
                } else {
                    break loop
                }
            }
        }

        return node
    }

    /// Give a virtual "lost" result to a node, when we've decided to evaluate it but
    /// haven't gotten the evaluation result.  This should discourage the tree search
    /// to go down this path, so that we can find new nodes for evaluation.  The virtual
    /// losses are recorded, so they can be reverted when the results come back.
    /// Visit count is only incremented once.
    func addAndRecordVirtualLoss(_ node: Node) -> (isNew: Bool, loss: Double) {
        let isNew: Bool
        let loss: Double
        if let (_, previousLoss) = virtualLosses[node.id] {
            isNew = false
            loss = previousLoss - 1.0
        } else {
            isNew = true
            loss = -1.0
        }
        virtualLosses[node.id] = (node, loss)
        backPropagate(from: node, value: -1, visits: isNew ? 1 : 0)
        return (isNew: isNew, loss: loss)
    }

    /// When an evaluated node is selected, propagate with its old evaluated value.
    /// This should mildly discourage the tree search to go down this path, because
    /// Q will remain the same while U goes down.
    func propagateOldValue(_ node: Node) {
        guard let parent = node.parent else { return }
        let index = node.indexInParent
        let value = parent.childW[index] / parent.childN[index]
        backPropagate(from: node, value: value, visits: 1)
    }

    /// Revert virtual losses, forget about evaluations that haven't come back
    /// so that we can move the root down and start searching again.
    func cancelOutstandingEvaluations() {
        while let (_, entry) = virtualLosses.popFirst() {
            backPropagate(from: entry.0,
                          value: -entry.1,
                          visits: -1)
        }
    }

    /// Propagate the evaluated value from the leaf node back up the tree.  Every node
    /// in the path receives the updated information about its descendants.
    func backPropagate(from leaf: Node, value: Double, visits: Double) {
        var node = leaf
        while let parent = node.parent {
            let index = node.indexInParent
            parent.childW[index] += value
            parent.childN[index] += visits
            node = parent
        }
    }
}

