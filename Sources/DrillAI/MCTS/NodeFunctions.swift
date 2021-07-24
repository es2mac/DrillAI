//
//  NodeFunctions.swift
//  
//
//  Created by Paul on 7/5/21.
//

import Foundation
import Accelerate


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
