//
//  BCTSEvaluation.swift
//
//
//  Created by Paul on 7/23/21.
//

import Foundation


/*
 Refactoring note:  For BCTS, looks like I need the parent's state & action that
 resulted in the current state, i.e. a short history.
 */

/// BCTS value, according to the Building Controllers for Tetris paper
/// Thiery & Scherrer
/// This value seems basically always in the negatives, from minus a few hundred
/// to >3000 in utterly terrible fields
func calculateBctsValue(_ node: MCTSNode<GameState, Piece>) -> Double {
    guard let parent = node.parent else { return 0 }

    let field = node.state.field
    let piece = parent.nextActions[node.indexInParent]
    let lines = field.storage

    // Landing height
    let landingHeight = Double(piece.y - field.garbageCount)

    // Eroded piece cells
    // (similar to locking down a piece on field)
    let parentField = parent.state.field

    let pieceIndex = piece.bitmaskIndex
    let pieceMasks = pieceBitmasks[pieceIndex]
    let boundOffsets = pieceBoundOffsets[pieceIndex]
    let pieceLeft = piece.x - boundOffsets.left
    let bottomRow = piece.y - boundOffsets.bottom

    var linesCleared = 0
    var cellsEroded = 0
    for (i, mask) in pieceMasks.enumerated() {
        let row = bottomRow + i
        if row < parentField.height {
            let line = parentField.storage[row]
            if line | (mask << pieceLeft) == 0b11111_11111 {
                linesCleared += 1
                cellsEroded += (10 - line.nonzeroBitCount)
            }
        }
    }

    let erodedPieceCells = Double(linesCleared * cellsEroded)

    // Row transitions
    let rowTransitions: Double = lines
        .reduce(0.0) {
            let left = ($1 << 1) + 1
            let right = $1 + 1024
            return $0 + Double((left ^ right).nonzeroBitCount)
        }

    // Column transitions
    let columnTransitions: Double = zip(lines, lines.dropFirst() + [0])
        .reduce(0.0) {
            $0 + Double(($1.0 ^ $1.1).nonzeroBitCount)
        }

    // Indices of top filled cell of each column, -1 if empty (not used in score)
    let columnTops: [Int] = (0 ..< 10).map { (index) -> Int in
        let mask: Int16 = 1 << index
        return lines.lastIndex { $0 & mask != 0 } ?? -1
    }

    // Holes
    var holeMask: Int16 = 0
    var holeCount = 0
    var rowsWithHolesCount = 0
    var rowsWithHolesMask: Int16 = 0
    for line in lines.reversed() {
        let maskedLine = holeMask & ~line
        holeMask |= line
        if maskedLine != 0 {
            holeCount += maskedLine.nonzeroBitCount
            rowsWithHolesCount += 1
            rowsWithHolesMask |= maskedLine
        }
    }

    let holes = Double(holeCount)

    // Cumulative wells
    // Cheat a little and assume the first found well entrance "X.X" extends
    // all the way to filled top, skip further checking
    let walledLines = lines.map { ($0 << 1) | 0b1_00000_00000_1 }
    let columnWellSums: [Int] = (0 ..< 10).map { (column) -> Int in
        // Calculation first "AND" left side of the column, then shift it to "AND"
        // right side of column.  Watch out that walledLines is shifted by 1
        let columnTopIndex = columnTops[column]
        let mask: Int16 = 1 << Int16(column)

        var wellSum = 0
        var index = walledLines.count - 1
        while index > columnTopIndex {
            let line = walledLines[index]
            if ((line & mask) << 2) & line != 0 {
                let wellHeight = index - columnTopIndex
                wellSum = wellHeight * (wellHeight + 1) / 2
                break
            }
            index -= 1
        }
        return wellSum
    }

    let cumulativeWells = Double(columnWellSums.reduce(0, +))

    // Hole depth
    let holeDepths: [Int] = (0 ..< 10).map { (column) -> Int in
        let mask: Int16 = 1 << Int16(column)
        if mask & rowsWithHolesMask == 0 {
            return 0
        }
        // Find the last filled cell from the top filled cell, then down by 1
        let columnTopIndex = columnTops[column]
        let topHoleIndex = lines[...columnTopIndex].lastIndex { $0 & mask == 0 }!
        return columnTopIndex - topHoleIndex
    }

    let holeDepth = Double(holeDepths.reduce(0, +))

    // Rows with holes
    let rowsWithHoles = Double(rowsWithHolesCount)

    // These are ordered as in the Thiery & Scherrer paper, and the first 6 are
    // used by Dellacherie
    return (-12.63 * landingHeight) +
    (  6.60 * erodedPieceCells) +
    ( -9.22 * rowTransitions) +
    (-19.77 * columnTransitions) +
    (-13.08 * holes) +
    (-10.49 * cumulativeWells) +
    ( -1.61 * holeDepth) +
    (-24.04 * rowsWithHoles)
}


/// Simple old-school evaluation to make things work ok
/// Good for testing without the neural network evaluation
//func bctsEvaluate(_ node: MCTSNode, depth: Int) -> (value: Double, priors: Tensor<Double>) {
func bctsEvaluate(_ node: MCTSNode<GameState, Piece>, depth: Int) -> (value: Double, priors: [Double]) {

    var value: Double

    if depth == 0 {
        value = 1
    } else {
        value = Double(node.state.garbageCleared) / Double(depth + 10)
    }

    // Try: adding BCTS
    let bcts = 3.5 + calculateBctsValue(node) / 300

    if bcts > 0 {
        value = bcts * (1 + value)
    } else {
        value = bcts
    }

    // Try: "Winning" is a special case
    if node.state.field.garbageCount == 0 {
        value += 2
    }

    //      data1.append(value)
    //      data2.append(bcts)


    // Priors: Placements that clears a garbage line is given preference
    let childrenGarbageCleared: [Double] = node.nextActions.map {
        return Double(node.state.field.lockDown($0).garbageCleared)
    }

    //  var priors = Tensor(childrenGarbageCleared) * 0.01
    let priors = childrenGarbageCleared.map { $0 * 0.01 }

    // Try: Add some noise
    //  let noise = Tensor<Double>(randomUniform: priors.shape) * 0.02
    //  priors += noise

    // Try: Add a uniform prior
    //  priors += 0.2

    // Try: Just don't give a prior.  Make it a flat value.
    //   priors = priors * 0 + 0.2

    return (value: value, priors: priors)
}
