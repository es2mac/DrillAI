//
//  MCTSNode.swift
//  
//
//  Created by Paul on 7/5/21.
//

import Foundation
import Accelerate


public final class MCTSNode<State: MCTSState> {
    public typealias Action = State.Action

    public enum Status {
        case initial, expanded, evaluated
    }

    /// State of the game at this node
    public let state: State

    /// We keep a reference of the parent to allow backward traversal, which happens
    /// when the node's evaluation is done, and the result is propagated back up the
    /// tree.
    private(set) weak var parent: MCTSNode?

    /// Remember the child's position/index in the parent for efficient lookup
    /// when propagating values backwards.
    let indexInParent: Int

    /// The next actions are found via calling `expand` and it prepares the node for
    /// evaluation, as well as setting up the associated children, priors, W and N.
    public private(set) var nextActions = [Action]()

    /// The children of a node are initialized very lazily as storing states might
    /// consume a lot of memory.
    /// The children array should be initialized with nil's of the correct count
    /// when we get the actions, and for each child, the state and node are generated
    /// only when we decide to explore it.
    public private(set) var children = [MCTSNode?]()

    /// Priors, like the Bayesian prior probability, can be thought of as a
    /// sense/intuition of how good an action is likely to be.  When there's no
    /// reasonable estimate for priors, it may help to set it to some noise to
    /// create randomness.
    public private(set) var priors = [Double]()

    /// W is the aggregate value of all the expanded (explored/evaluated) nodes under
    /// each children, including the children themselves.  Conversely we can say that
    /// for each node, its W and N values are stored in its parent, not itself.
    /// We can calculate an average value by dividing with N, getting a sense of how
    /// good an action is.
    public internal(set) var childW = [Double]()

    /// N is the aggregate visit counts of all the expanded nodes under each children,
    /// including the children themselves.  Because MCTS balances exploration and
    /// exploitation, it would visit nodes with good values more often, so the child
    /// with highest N is essentially the "best."
    public internal(set) var childN = [Double]()

    /// Here a node is expanded when the `expand()` method has been called, so that
    /// next actions have been found, and related fields are initialized.
    ///
    /// A node goes through several stages during tree search.
    ///
    /// - Initialized with a game state, when it gets selected for visiting.
    /// - Next legal actions figured out.  Each action would give a new state and
    ///   a new child, but those are instantiated lazily.  So at this point,
    ///   we say the node is expanded.
    /// - State evaluated, obtaining a value and priors.  Technically we don't need
    ///   the priors until we want to choose a children for further exploration,
    ///   but if we're using neural networks, the two are evaluated together.
    ///
    /// Because priors are tied with value evaluation, and next actions are needed to
    /// interpret priors, the node initialization - expansion - start evaluation
    /// happen in a row, and the node's status would be "expanded."  When the evaluation
    /// result comes back, it is "evaluated."
    private(set) var status: Status = .initial

    init(state: State, parent: MCTSNode? = nil, indexInParent: Int = 0) {
        self.state = state
        self.parent = parent
        self.indexInParent = indexInParent
    }
}


extension MCTSNode {

    /// Find all legal actions, and set up the corresponding children etc.
    /// Returns the next actions as a convenience.
    @discardableResult
    func expand() -> [Action] {
        guard case .initial = status else {
            return nextActions
        }

        nextActions = state.getLegalActions()

        let count = nextActions.count
        let zerosVector = [Double](repeating: 0, count: count)

        children = [MCTSNode?](repeating: nil, count: count)
        priors = zerosVector
        childW = zerosVector
        childN = zerosVector

        status = .expanded

        return nextActions
    }

    /// Set the node as evaluated, and the priors that result from the evaluation.
    /// The actual evaluated value is handled separately, because back-propagating the
    /// value with virtual loss etc. are better handled by the tree.
    /// If no priors are given, some default priors will be set (uniform with noise).
    func setEvaluated(priors: [Double]? = nil) {
        guard case .expanded = status else {
            assertionFailure()
            return
        }
        if let priors = priors {
            assert(priors.count == children.count)
            self.priors = priors
        } else {
            let weights = children.map { _ in Double.random(in: 99...101) }
            self.priors = vDSP.divide(weights, vDSP.sum(weights))
        }
        status = .evaluated
    }

    /// Get the child that corresponds to performing the best action.  Since MCTS
    /// visit nodes while balancing exploration & exploitation, the most visited
    /// child should end up being the one with the highest mean value.
    /// Returns nil if there's no children, or if no child has been visited and
    /// evaluated (N is incremented when back-propagating evaluation results).
    func getMostVisitedChild() -> MCTSNode? {
        let (index, N) = vDSP.indexOfMaximum(childN)
        return N > 0 ? children[Int(index)] : nil
    }

    /// Get the child with the best action score, i.e. best target to explore,
    /// balancing exploration & exploitation.
    /// If this node has not been evaluated, then normally the children won't be either,
    /// in which case a random index is returned.
    /// Returns nil if there's no children.
    func getBestSearchTargetChild() -> MCTSNode? {
        bestActionValuedChildIndex.map(getOrInitializeChildNode)
    }

    /// Get a child node, initialize the node if it hasn't been already.
    func getOrInitializeChildNode(at index: Int) -> MCTSNode {
        if let childNode = children[index] {
            return childNode
        }

        let action = nextActions[index]
        let newState = state.getNextState(for: action)
        let childNode = MCTSNode(state: newState, parent: self, indexInParent: index)

        children[index] = childNode
        return childNode
    }

    func removeParent() {
        parent = nil
    }
}


private extension MCTSNode {

    /// Index of the child node with the best action score.
    /// If this node has not been evaluated, then normally the children won't be either,
    /// in which case a random child index is returned.
    /// Returns nil if there's no children.
    var bestActionValuedChildIndex: Int? {
        guard !children.isEmpty else {
            return nil
        }
        switch status {
        case .initial: return nil
        case .expanded: return Int.random(in: 0..<children.count)
        case .evaluated: return getBestActionValuedChildIndex()
        }
    }

    /// By informal testing, this is 2.5x speedup from doing
    /// ```Int(vDSP.indexOfMaximum(actionScores).0)```
    /// The logic is the same, just avoiding array allocations.
    /// Keeping the actionScore & dependent values code as documentation.
    func getBestActionValuedChildIndex() -> Int {
        // Scalar values
        let totalN = max(1, vDSP.sum(childN) - 1)
        let puctConstant = 2.5
        let C = 1.25 + log((1 + totalN + 19652.0) / 19652.0)
        let scalars = puctConstant * C * sqrt(totalN)

        // Mean action values
        var result = vDSP.add(1, childN)                        // 1 + N
        vDSP.divide(1, result, result: &result)                 // 1 / (1 + N)

        let meanActionValues = vDSP.multiply(childW, result)    // W / (1 + N)

        // PUCT values
        vDSP.multiply(priors, result, result: &result)          // priors / (1 + N)
        vDSP.multiply(scalars, result, result: &result)         // scalars * priors / (1 + N)

        // Mean action values + PUCT values = action score
        vDSP.add(meanActionValues, result, result: &result)

        return Int(vDSP.indexOfMaximum(result).0)
    }


    /// The PUCT action scores of all children, i.e. sum of the exploitation scores
    /// (Q) and exploration scores (U).
    /// Q = meanActionValues, U = puctValues, return Q + U
    var actionScores: [Double] {
        vDSP.add(meanActionValues, puctValues)
    }

    /// The "Exploitation" part of the score
    /// Returns Q = W / (1 + N)
    var meanActionValues: [Double] {
        vDSP.divide(childW, vDSP.add(1, childN))
    }

    /// The "Exploration" part of the score
    /// Returns U = some constants \* priors \* sqrt(totalN) / (1 / N)
    /// Constants here needs tuning as training progress, e.g. when the model is
    /// still really bad, Q is uselessly small, so we might need a smaller U.
    var puctValues: [Double] {

        // Tune this multiple -- MiniGo uses 2.0.
        let puctConstant = 2.5

        let totalN = max(1, vDSP.sum(childN) - 1)

        // C: Exploration Rate, grows pretty slowly over time
        let cBase = 19652.0
        let cInitial = 1.25
        let C = cInitial + log((1 + totalN + cBase) / cBase)

        // puctConstant * C * priors * sqrt(totalN) / (1 + N)
        let scalars = puctConstant * C * sqrt(totalN)
        return vDSP.divide(
            vDSP.multiply(scalars, priors),
            vDSP.add(1, childN)
        )
    }

//    /// Next move selection: Probabilistic (using softmax of visit counts)
//    func getChildWithWeightedProbability() -> MCTSNode? {
//        guard hasChildren else { return nil }
//
//        //    let distribution = softmax(childN)
//        let distribution = childN
//        //    var randomTarget = Tensor(Double.random(in: 0..<1))
//        var randomTarget = Double.random(in: 0.0..<1.0)
//
//        for index in 0 ..< children.count {
//            let probability = distribution[index]
//            if randomTarget < probability {
//                return children[index]
//            }
//            randomTarget -= probability
//        }
//        return nil
//    }
}


extension MCTSNode: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "MCTSNode(\(state), children: \(children.count)"
    }
}


extension MCTSNode: Identifiable {}

