//
//  MCTSNode.swift
//  
//
//  Created by Paul on 7/5/21.
//

import Foundation
import Accelerate


public final class MCTSNode<State, Action> {

    /// State of the game at this node
    public let state: State

    /// We keep a reference of the parent to allow backward traversal, which happens
    /// when the node's evaluation is done, and the result is propagated back up the
    /// tree.
    private(set) weak var parent: MCTSNode?

    /// Remember the child's position/index in the parent for efficient lookup
    /// when propagating values backwards.
    let indexInParent: Int

    /// As finding all valid next actions might be an expensive operation,this
    /// doesn't need to be computed until we want to expand this node.
    /// The next few properties are all tied to actions, so they are all implicitly
    /// matched: Each action has a prior and a child, and W & N associated with
    /// each child.
    public var nextActions = [Action]()

    /// The children of a node are initialized very lazily as storing states might
    /// consume a lot of memory.
    /// The children array should be initialized with nil's of the correct count
    /// when we get the actions, and for each child, the state and node are generated
    /// only when we decide to explore it.
    public var children = [MCTSNode?]()

    /// Priors, like the Bayesian prior probability, can be thought of as a
    /// sense/intuition of how good an action is likely to be.
    public var priors = [Double]()

    /// W is the aggregate value of all the expanded (explored/evaluated) nodes under
    /// each children, including the children themselves.  Conversely we can say that
    /// for each node, its W and N values are stored in its parent, not itself.
    /// We can calculate an average value by dividing with N, getting a sense of how
    /// good an action is.
    public var childW = [Double]()

    /// N is the aggregate visit counts of all the expanded nodes under each children,
    /// including the children themselves.  Because MCTS balances exploration and
    /// exploitation, it would visit nodes with good values more often, so the child
    /// with highest N is essentially the "best."
    public var childN = [Double]()

    /// A node goes through several stages during tree search.
    ///
    /// - Initialized with a game state
    /// - State evaluated, obtaining a value and priors.  Technically we don't need
    ///   the priors until we decide to choose a children for further exploration,
    ///   but if we're using neural networks, the two are evaluated together.
    /// - Actions figured out.  This should happen alongside state evaluation,
    ///   because we only want to keep the priors for valid actions.
    ///
    /// Since evaluating state & prior and finding actions are all tied together,
    /// we refer to this group of actions as "expanding" the node.
    var isExpanded: Bool = false

    public init(state: State, parent: MCTSNode? = nil, indexInParent: Int = 0) {
        self.state = state
        self.parent = parent
        self.indexInParent = indexInParent
    }
}

@available(macOSApplicationExtension 10.15, *)
extension MCTSNode where State == GameState, Action == Piece {
    func getHighestValuedChild() -> MCTSNode {
        assert(hasChildren, "Can't get highest valued child before having children")
        let bestIndex = bestValuedChildIndex
        return children[bestIndex] ?? initiateChildNode(bestIndex)
    }

    func setupChildren(playPieceType: Tetromino) {
        assert(!hasChildren, "setupChildren should only need to be done once")

        // The node didn't need to know the play piece until this point, where it
        // needs the play piece to find all possible actions.  Save the play piece
        // for later when initiating child nodes (because the child node's hold
        // piece may be the current play piece or the current hold piece)
//        self.state.playPieceType = playPieceType

        let availableTypes = (playPieceType == state.hold) ? [state.hold] : [state.hold, playPieceType]
        nextActions = state.field.findAllSimplePlacements(for: availableTypes)

        let count = nextActions.count

        children = Array<MCTSNode?>.init(repeating: nil, count: count)
        //        priors = Tensor(randomUniform: [count]) * 0.01 + (1 / Double(count + 1))
        priors = [Double]()
        //        childW = Tensor(zeros: [count])
        childW = [Double]()
        //        childN = Tensor(zeros: [count])
        childN = [Double]()
    }

    func initiateChildNode(_ index: Int) -> MCTSNode {
        let placedPiece = nextActions[index]
        let (nextField, newGarbageCleared) = state.field.lockDown(placedPiece)
        let newHold = (placedPiece.type == state.playPieceType) ? state.hold : state.playPieceType!

        let newState = GameState(field: nextField,
                                 hold: newHold,
                                 step: state.step + 1,
                                 garbageCleared: state.garbageCleared + newGarbageCleared)
        let childNode = MCTSNode(state: newState, parent: self, indexInParent: index)

        children[index] = childNode
        return childNode
    }
}


@available(macOSApplicationExtension 10.15, *)
extension MCTSNode where State == GameState, Action == Piece {

    /// Next move selection: Probabilistic (using softmax of visit counts)
    func getChildWithWeightedProbability() -> MCTSNode? {
        guard hasChildren else { return nil }

        //    let distribution = softmax(childN)
        let distribution = childN
        //    var randomTarget = Tensor(Double.random(in: 0..<1))
        var randomTarget = Double.random(in: 0.0..<1.0)

        for index in 0 ..< children.count {
            let probability = distribution[index]
            if randomTarget < probability {
                return children[index]
            }
            randomTarget -= probability
        }
        return nil
    }
}



@available(macOSApplicationExtension 10.15, *)
extension MCTSNode {
    var hasChildren: Bool {
        return !children.isEmpty
    }

    /* Note: this should be like the most visited below, but I can't move
     `getHighestValuedChild` because it also instantiate the child.
     The logic here is vague.  The children can be in several states:
     - un-initialized, because actions have not been figured out
     - empty, there is no action (though for Tetris, this is rare)
     - particular child is nil
     -
     */
    var bestValuedChildIndex: Int {
        Int(vDSP.indexOfMaximum(childrenActionScores).0)
    }

    /// Next move selection: Deterministic
    func getMostVisitedChild() -> MCTSNode? {
        guard hasChildren else { return nil }
        let index = Int(vDSP.indexOfMaximum(childN).0)

        // This could still return nil, if no child has been visited
        return children[index]
    }


    // Wish: Use normal arrays to do these vector calculations
    // but use Accelerate (vDSP?) to speed it up!

    //    var childrenActionScores: Tensor<Double> {
    //        let Q = meanActionValue
    //        let U = puctValue
    //        return Q + U
    //    }
    var childrenActionScores: [Double] {
        zip(meanActionValue, puctValue).map { Q, U in Q + U }
    }

    //    var meanActionValue: Tensor<Double> {
    //        return childW / (1 + childN)
    //    }
    var meanActionValue: [Double] {
        zip(childW, childN).map { W, N in W / (1 + N) }
    }

    var puctValue: [Double] {
        // The exploration constant may need some tuning as training progress,
        // because so far the model is so bad it rarely clears lines,
        // so the Q value is always very small.
        //     let puctConstant = 0.5
        let puctConstant = 2.0 // MiniGo uses 2.0

        // C: Exploration Rate, grows pretty slowly over time
        let cBase = 19652.0
        let cInitial = 1.25

        let totalN = childN.reduce(0, +)
        let adjustedTotalN = max(1, totalN - 1)

        let C = cInitial + log((1 + totalN + cBase) / cBase)

        //        return puctConstant * C * priors * sqrt(adjustedTotalN) / (1 + childN)
        return zip(priors, childN).map { prior, N in
            puctConstant * C * prior * sqrt(adjustedTotalN) / ( 1 + N)
        }
    }
}


extension MCTSNode: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "MCTSNode(\(state), children: \(children.count)"
    }
}


extension MCTSNode: Identifiable {}

