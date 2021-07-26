//
//  PrintTree.swift
//
//
//  Created by Paul on 7/23/21.
//

//import Foundation


//extension MCTSTree {
//  func printMove(childNode: MCTSNode) {
//    // Lots of duplicate printing logic, but it'll do for now
//
//    var lines = root.field.storage
//
//    let piece = root.nextActions[childNode.indexInParent]
//    let pieceIndex = piece.bitmaskIndex
//    let boundOffsets = pieceBoundOffsets[pieceIndex]
//    let pieceLeft = piece.x - boundOffsets.left
//    let pieceMasks = pieceBitmasks[pieceIndex].map { $0 << pieceLeft}
//    let pieceBottomRow = piece.y - boundOffsets.bottom
//    let pieceTopRow = piece.y + boundOffsets.top
//
//    while lines.count <= pieceTopRow {
//      lines.append(0)
//    }
//
//    var stringField: [[String]] = lines.map { _ in
//      Array(repeating: " ", count: 10)
//    }
//
//    for (y, line) in lines.enumerated() {
//      for x in 0 ..< 10 {
//        if line & (1 << x) != 0 {
//          stringField[y][x] = "O"
//        }
//      }
//    }
//
//    for (y, mask) in zip(pieceBottomRow ... pieceTopRow, pieceMasks) {
//      for x in 0 ..< 10 {
//        if mask & (1 << x) != 0 {
//          stringField[y][x] = "X"
//        }
//      }
//    }
//
//    let stringLines = stringField.reversed().map { "  " + $0.joined(separator: " ")}
//    print(stringLines.joined(separator: "\n"))
//
//  }
//}
//
//
//// See the basic tree structure
//func printTree(node: MCTSNode, depth: Int = 0) {
//  print(String(repeating: "    ", count: depth) + "\(node)")
//  for child in node.children {
//    child.map { printTree(node: $0, depth: depth + 1) }
//  }
//}
