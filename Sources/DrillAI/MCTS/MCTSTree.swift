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
    private var virtualLosses: [ObjectIdentifier : Double] = [:]

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
        (id: ObjectIdentifier, value: Double, priors: [Double])
    ]

    func getNextUnevaluatedStates(targetCount: Int = 1) -> StatesInfo {
        let nodes = getNextUnevaluatedNodes(targetCount: targetCount)
        return nodes.map { node in
            (id: node.id, state: node.state, nextActions: node.nextActions)
        }
    }

    func getNextUnevaluatedStatesWithExtendedInfo(targetCount: Int = 1) -> ExtendedStatesInfo {
        let nodes = getNextUnevaluatedNodes(targetCount: targetCount)
        return nodes.map { node in
            (id: node.id, state: node.state, nextActions: node.nextActions,
             lastState: node.parent?.state,
             lastAction: node.parent?.nextActions[node.indexInParent])
        }
    }

    func updateWithEvaluationResults(_ results: EvaluationResults) {
       fatalError("Not implemented")
    }
}


private extension MCTSTree {

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

    func addAndRecordVirtualLoss(_ node: Node) -> (isNew: Bool, loss: Double) {
        backPropagate(from: node, value: -1, visits: 1)

        if let previousLoss = virtualLosses[node.id] {
            let loss = previousLoss - 1.0
            virtualLosses[node.id] = loss
            return (isNew: false, loss: loss)
        } else {
            virtualLosses[node.id] = -1.0
            return (isNew: true, loss: -1.0)
        }
    }

    func addVirtualVisit(_ node: Node) {
        backPropagate(from: node, value: 0, visits: 1)
    }

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

