//
//  MCTSTree.swift
//
//
//  Created by Paul on 7/23/21.
//

import Foundation


public actor MCTSTree<State: MCTSState, Action> where State.Action == Action {
    typealias Node = MCTSNode<State, Action>

    private var root: Node
    private var virtualLosses: [ObjectIdentifier : (Node, Double)] = [:]

    public init(initialState: State) {
        root = Node(state: initialState)
    }
}


extension MCTSTree {
    typealias StatesInfo = [
        (id: ObjectIdentifier, state: State, nextActions: [Action])
    ]
    typealias ExtendedStatesInfo = [
        (id: ObjectIdentifier, state: State, nextActions: [Action],
         lastState: State?, lastAction: Action?)
    ]
    typealias EvaluationResults = [
        (id: ObjectIdentifier, value: Double, priors: [Double]?)
    ]

    /// Find a collection of unevaluated states most worth evaluating.  Any state
    /// returned from here has an ID, and expects the evaluation result for the state
    /// to return with that ID.  In the tree, the node corresponding to the state would
    /// have a virtual loss recorded, which is reverted once the results come back.
    func getNextUnevaluatedStates(targetCount: Int = 1) -> StatesInfo {
        let nodes = getNextUnevaluatedNodes(targetCount: targetCount)
        return nodes.map { node in
            (id: node.id, state: node.state, nextActions: node.nextActions)
        }
    }

    /// Same as `getNextUnevaluatedStates` but including the parent's state, and the
    /// action taken to get from the parent state to this state.
    func getNextUnevaluatedStatesWithExtendedInfo(targetCount: Int = 1) -> ExtendedStatesInfo {
        let nodes = getNextUnevaluatedNodes(targetCount: targetCount)
        return nodes.map { node in
            (id: node.id, state: node.state, nextActions: node.nextActions,
             lastState: node.parent?.state,
             lastAction: node.parent?.nextActions[node.indexInParent])
        }
    }

    /// Update the tree with evaluation results.  Each result should be associated with
    /// a state that was gotten via the "get next unevaluated state" methods.
    /// Conversely, each state that went out from there is expected to come back with
    /// an evaluation.
    /// The evaluation may have just a value and no priors, in which case some default
    /// priors will be set (uniform with noise).
    func updateWithEvaluationResults(_ results: EvaluationResults) {
       fatalError("Not implemented")
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
                addVirtualVisit(node)
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
        while let nextNode = node.getBestSearchTargetChild() {
            node = nextNode
        }
        return node
    }

    /// Give a virtual "lost" result to a node, when we've decided to evaluate it but
    /// haven't gotten the evaluation result.  This should discourage the tree search
    /// to go down this path, so that we can find new nodes for evaluation.  The virtual
    /// losses are recorded, so they can be reverted when the results come back.
    func addAndRecordVirtualLoss(_ node: Node) -> (isNew: Bool, loss: Double) {
        backPropagate(from: node, value: -1, visits: 1)

        if let (_, previousLoss) = virtualLosses[node.id] {
            let loss = previousLoss - 1.0
            virtualLosses[node.id] = (node, loss)
            return (isNew: false, loss: loss)
        } else {
            virtualLosses[node.id] = (node, -1.0)
            return (isNew: true, loss: -1.0)
        }
    }

    /// Give one visit and neutral value (0) to a node.  This should mildly discourage
    /// the tree search to go down this path, but not influence the results too much,
    /// because more visits are considered good.  Irreversible.
    func addVirtualVisit(_ node: Node) {
        backPropagate(from: node, value: 0, visits: 1)
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

