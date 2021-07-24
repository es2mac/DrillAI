//
//  MCTSTree.swift
//
//
//  Created by Paul on 7/23/21.
//

import Foundation


// Need to fix: TetrisModel dependency.


//class MCTSTree {
//  let pieceSequence: PieceGenerator
//  let garbages: GarbageGenerator
//
//  let model: TetrisModel
//
//  var root: MCTSNode
//
//  init(field: Field,
//       pieceSequence: PieceGenerator,
//       garbages: GarbageGenerator,
//       model: TetrisModel) {
//    self.pieceSequence = pieceSequence
//    self.garbages = garbages
//    self.model = model
//    self.root = MCTSNode(field: field,
//                         hold: pieceSequence[0],
//                         garbageCleared: 0)
//    pieceSequence.offset += 1
//  }
//}
//
//extension MCTSTree {
//  convenience init(model: TetrisModel = TetrisModel()) {
//
//    let pieceSequence = PieceGenerator()
//    let garbages = GarbageGenerator()
//    let field = Field.init(storage: (0 ..< 10).map { garbages[$0] },
//                           garbageCount: 10)
//
//    self.init(field: field,
//              pieceSequence: pieceSequence,
//              garbages: garbages,
//              model: model)
//  }
//}

/*
 Tree climbing, er, traversal
 */
//extension MCTSTree {
//
//  /// Do MCTS selection to find a new node to evaluate.
//  /// Here, I use whether the node's children has been set up to decide
//  /// whether I can go deeper.  The search sequence is responsible to set up
//  /// a node with children, and evaluate the node, in the right order.
//  func selectBestUnevaluatedNode() -> MCTSNode {
//    var node = root
//    while node.hasChildren {
//      node = node.getHighestValuedChild()
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

//extension MCTSTree {
//
//    func getMostTraveledPath() -> [MCTSNode] {
//    var path = [root]
//    var node = root
//    while let child = node.getMostVisitedChild() {
//      path.append(child)
//      node = child
//    }
//    return path
//  }
//
//  func getReversePath(leaf: MCTSNode) -> [MCTSNode] {
//    var path = [leaf]
//    var node = leaf
//    while let parent = node.parent {
//      path.insert(parent, at: 0)
//      node = parent
//    }
//    return path
//  }
//
//}



