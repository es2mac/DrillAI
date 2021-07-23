//
//  NodeFunctions.swift
//  
//
//  Created by Paul on 7/5/21.
//

import Foundation

extension MCTSNode {

    //    var move: Piece {
    //        guard let parent = parent else {
    //            fatalError("Can't get move if don't have parent")
    //        }
    //        return parent.legalMoves[indexInParent]
    //    }

    var hasChildren: Bool {
        return !children.isEmpty
    }

    func setupChildren(playPieceType: Tetromino) {
        assert(!hasChildren, "setupChildren should only need to be done once")

        // The node didn't need to know the play piece until this point, where it
        // needs the play piece to find all possible actions.  Save the play piece
        // for later when initiating child nodes (because the child node's hold
        // piece may be the current play piece or the current hold piece)
        self.playPieceType = playPieceType

        let availableTypes = (playPieceType == hold) ? [hold] : [hold, playPieceType]
        legalMoves = field.findAllSimplePlacements(for: availableTypes)

        let count = legalMoves.count
        moveIndices = Dictionary(uniqueKeysWithValues: zip(legalMoves, 0..<count))

        children = Array<MCTSNode?>.init(repeating: nil, count: count)
        //        priors = Tensor(randomUniform: [count]) * 0.01 + (1 / Double(count + 1))
        priors = [Double]()
        //        childW = Tensor(zeros: [count])
        childW = [Double]()
        //        childN = Tensor(zeros: [count])
        childN = [Double]()
    }

    func getHighestValuedChild() -> MCTSNode {
        assert(hasChildren, "Can't get highest valued child before having children")

        //        let bestIndex = Int(childrenActionScores.argmax().scalarized())
        let bestIndex = childrenActionScores.firstIndex(of: childrenActionScores.max()!)!

        return children[bestIndex] ?? initiateChildNode(bestIndex)
    }

    func initiateChildNode(_ index: Int) -> MCTSNode {
        let placedPiece = legalMoves[index]
        let (nextField, newGarbageCleared) = field.lockDown(placedPiece)
        let newHold = (placedPiece.type == playPieceType) ? hold : playPieceType!

        let childNode = MCTSNode(field: nextField,
                                 hold: newHold,
                                 step: step + 1,
                                 garbageCleared: garbageCleared + newGarbageCleared,
                                 parent: self,
                                 indexInParent: index)
        children[index] = childNode

        return childNode
    }

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


extension MCTSNode {
    /// Next move selection: Deterministic
    func getMostVisitedChild() -> MCTSNode? {
        guard hasChildren else { return nil }

        //    let index = Int(childN.argmax().scalarized())
        let index = childN.firstIndex(of: childN.max()!)!
        

        // This could still return nil, if no child has been visited
        return children[index]
    }

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
