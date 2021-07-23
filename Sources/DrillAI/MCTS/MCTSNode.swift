//
//  MCTSNode.swift
//  
//
//  Created by Paul on 7/5/21.
//

import Foundation


public class MCTSNode<State, Action> {

    /// State of the game at this node
    public var state: State

    /// We keep a reference of the parent to allow backward traversal, which happens
    /// when the node's evaluation is done, and the result is propagated back up the tree
    private(set) weak var parent: MCTSNode?

    /// Remember the child's position/index in the parent for efficient lookup when propagating values backwards.
    let indexInParent: Int

    /// As finding all valid next actions might be an expensive operation, this doesn't need to be computed
    /// until we want to expand (explore/evaluate) this node.
    /// The next few properties are all tied to actions, so these arrays are all implicitly matched:
    /// Each action leads to a child, which has a prior, W, and N.
    public var nextActions = [Action]()

    /// The children of a node are initialized very lazily as storing states might consume a lot of memory.
    /// The children array should be initialized with nil's of the correct count when we get the actions,
    /// and for each child, the state and node are generated only when we decide to expand it.
    public var children = [MCTSNode?]()

    // MARK: Evaluation statistics

    /// Priors, like the Bayesian prior probability, can be thought of as a sense/intuition
    /// of how good a child is likely to be.
    public var priors = [Double]()

    /// W is the aggregate value of all the expanded (explored/evaluated) nodes under each children,
    /// including the children themselves.  We can calculate an average value by dividing with N, getting a sense
    /// of how good an action is.
    public var childW = [Double]()

    /// N is the aggregate visit counts of all the expanded nodes under each children,
    /// including the children themselves.  Because MCTS balances exploration and exploitation,
    /// it would visit nodes with good values more often, so the child with highest N is essentially "best."
    public var childN = [Double]()

    init(state: State, parent: MCTSNode? = nil, indexInParent: Int = 0) {
        self.state = state
        self.parent = parent
        self.indexInParent = indexInParent
    }
}


extension MCTSNode: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "MCTSNode(\(state), children: \(children.count)"
    }
}


extension MCTSNode: Identifiable {}

