//
//  MCTSNode.swift
//  
//
//  Created by Paul on 7/5/21.
//

import Foundation


/// Placeholder: Need to find a replacement for Tensor, maybe MLMultiArray?
//class Tensor<Value> {
//    static var zero: Tensor { .init() }
//
//    init() { }
//    convenience init(randomUniform dimensions: [Int]) where Value == Double { self.init() }
//    convenience init(zeros dimensions: [Int]) where Value == Double { self.init() }
//
//    func argmax() -> Tensor<Value> { self }
//    func sum() -> Tensor<Value> { self }
//    func scalarized() -> Double { 0 }
//}
//
//func *(lhs: Tensor<Double>, rhs: Double) -> Tensor<Double> {
//    lhs
//}
//func /(lhs: Tensor<Double>, rhs: Tensor<Double>) -> Tensor<Double> {
//    lhs
//}
//func /(lhs: Tensor<Double>, rhs: Double) -> Tensor<Double> {
//    lhs
//}
//func +(lhs: Tensor<Double>, rhs: Tensor<Double>) -> Tensor<Double> {
//    lhs
//}
//func +(lhs: Tensor<Double>, rhs: Double) -> Tensor<Double> {
//    lhs
//}
//func +(lhs: Double, rhs: Tensor<Double>) -> Tensor<Double> {
//    rhs
//}
//func +(lhs: Int, rhs: Tensor<Double>) -> Tensor<Double> {
//    rhs
//}


class MCTSNode {
    // Game state
    let field: Field
    let hold: Tetromino
    let step: Int
    let garbageCleared: Int
    var playPieceType: Tetromino? = nil // Not given until setting up children

    // Tree structure: parent
    private(set) weak var parent: MCTSNode?
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
    init(field: Field,
         hold: Tetromino,
         step: Int = 0,
         garbageCleared: Int = 0,
         parent: MCTSNode? = nil,
         indexInParent: Int = 0) {
        self.field = field
        self.hold = hold
        self.step = step
        self.garbageCleared = garbageCleared
        self.parent = parent
        self.indexInParent = indexInParent
    }
}

extension MCTSNode: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "MCTSNode(hold: \(hold), cleared: \(garbageCleared), step: \(step), children: \(children.count))"
    }
}

//extension MCTSNode: Hashable {
extension MCTSNode {

    // It seems likely that I might see collisions, because you can place
    // pieces in different orders using hold to get to the same state,
    // yet for nodes not yet evaluated, this is probably the most I can do.
    static func ==(lhs: MCTSNode, rhs: MCTSNode) -> Bool {
        return lhs.field == rhs.field
        && lhs.hold == rhs.hold
        && lhs.playPieceType == rhs.playPieceType
        && lhs.step == rhs.step
        && lhs.garbageCleared == rhs.garbageCleared
        && lhs.indexInParent == rhs.indexInParent
    }
}
