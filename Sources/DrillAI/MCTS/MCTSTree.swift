//
//  MCTSTree.swift
//
//
//  Created by Paul on 7/23/21.
//

import Foundation


public actor MCTSTree<State: MCTSState, Action> where State.Action == Action {

    private var root: MCTSNode<State, Action>

    public init(initialState: State) {
        root = MCTSNode(state: initialState)
    }
}


extension MCTSTree {
    typealias StatesInfo = [
        (id: ObjectIdentifier, state: State, nextActions: [Action])
    ]
    typealias ExtendedStatesInfo = [
        (id: ObjectIdentifier, state: State, nextActions: [Action],
         lastState: State, lastAction: Action)
    ]
    typealias EvaluationResults = [
        (id: ObjectIdentifier, value: Double, priors: [Double])
    ]

    func getNextUnevaluatedStates(targetCount: Int = 1) -> StatesInfo {
        return [(id: root.id, state: root.state, nextActions: root.nextActions)]
//       fatalError("Not implemented")
    }

    func getNextUnevaluatedStatesWithExtendedInfo(targetCount: Int = 1) -> ExtendedStatesInfo {
       fatalError("Not implemented")
    }

    func updateWithEvaluationResults(_ results: EvaluationResults) {
       fatalError("Not implemented")
    }
}


//extension MCTSTree {
//
//  /// Do MCTS selection to find a new node to evaluate.
//  /// Here, I use whether the node's children has been set up to decide
//  /// whether I can go deeper.  The search sequence is responsible to set up
//  /// a node with children, and evaluate the node, in the right order.
//  func selectBestUnevaluatedNode() -> MCTSNode {
//    var node = root
//    while node.hasChildren {
//      node = node.getBestSearchTargetChild()
//    }
//    return node
//  }
//
//  func backPropagate(from node: MCTSNode, value: Double, visits: Double = 1) {
//    var childNode = node
//    while let parentNode = childNode.parent {
//      parentNode.childW[childNode.indexInParent] += value
//      parentNode.childN[childNode.indexInParent] += visits
//      childNode = parentNode
//    }
//  }
//
//}

