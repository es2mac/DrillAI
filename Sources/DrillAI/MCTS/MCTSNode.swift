//
//  MCTSNode.swift
//  
//
//  Created by Paul on 7/5/21.
//

import Foundation


public class MCTSNode<State, Action> {
    // State of the game at this node
    var state: State

//    let field: Field
//    let hold: Tetromino
//    let step: Int
//    let garbageCleared: Int
//    var playPieceType: Tetromino? = nil // Not given until setting up children

    // The action that was taken to reach this state from the previous state
    // var action: Action

    // Tree structure: parent
    // Backward traversal happens when the node is evaluated,
    // and the result is propagated back up
    private(set) weak var parent: MCTSNode?
    // Want to remove this, maybe with OrderedSet as children
    let indexInParent: Int

    // Children
    var legalMoves = [Piece]()
    var children = [MCTSNode?]()
    var moveIndices = [Piece : Int]()

    // Evaluation
    //    var priors = Tensor<Double>.zero
    var priors = [Double]()
    //    var childW = Tensor<Double>.zero
    var childW = [Double]()
    //    var childN = Tensor<Double>.zero
    var childN = [Double]()

    // Initializer
//    init(field: Field,
//         hold: Tetromino,
//         step: Int = 0,
//         garbageCleared: Int = 0,
//         parent: MCTSNode? = nil,
//         indexInParent: Int = 0) {
    init(state: State,
         parent: MCTSNode? = nil,
         indexInParent: Int = 0) {
        self.state = state
//        self.field = field
//        self.hold = hold
//        self.step = step
//        self.garbageCleared = garbageCleared
        self.parent = parent
        self.indexInParent = indexInParent
    }
}

extension MCTSNode: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "MCTSNode(\(state), children: \(children.count)"
//        return "MCTSNode(hold: \(state.hold), cleared: \(state.garbageCleared), step: \(state.step), children: \(children.count))"
    }
}


//extension MCTSNode: Identifiable {}

//extension MCTSNode: Hashable {
//    // It seems likely that I might see collisions, because you can place
//    // pieces in different orders using hold to get to the same state,
//    // yet for nodes not yet evaluated, this is probably the most I can do.
//    static func ==(lhs: MCTSNode, rhs: MCTSNode) -> Bool {
//        return lhs.field == rhs.field
//        && lhs.hold == rhs.hold
//        && lhs.playPieceType == rhs.playPieceType
//        && lhs.step == rhs.step
//        && lhs.garbageCleared == rhs.garbageCleared
//        && lhs.indexInParent == rhs.indexInParent
//    }
//}
