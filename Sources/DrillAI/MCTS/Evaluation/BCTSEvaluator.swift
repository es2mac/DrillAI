//
//  BCTSEvaluator.swift
//
//
//  Created by Paul on 7/23/21.
//

import Foundation


struct InternalState: Hashable {
    let field: Field
    let hold: Tetromino?
    let dropCount: Int
    let garbageCleared: Int

    func hash(into hasher: inout Hasher) {
        hasher.combine(field.storage)
        hasher.combine(field.garbageCount)
        hasher.combine(hold)
        hasher.combine(dropCount)
        hasher.combine(garbageCleared)
    }

    init(_ gameState: GameState) {
        self.field = gameState.field
        self.hold = gameState.hold
        self.dropCount = gameState.dropCount
        self.garbageCleared = gameState.garbageCleared
    }
}


public final class BCTSEvaluator {

    private var count: Int = 0
    private var lastPrint: Int = 0
//    private var seenStates: Set<InternalState> = Set()
//    private var dropCountTally: [Int] = [Int](repeating: 0, count: 60)
    private var doneStateDepths: [Int: Int] = [:]

    public init() {}
}

extension BCTSEvaluator: MCTSEvaluator {}
public extension BCTSEvaluator {
    typealias State = GameState
    typealias Action = Piece
    typealias Info = MCTSTree<GameState>.StatesInfo
    typealias Results = MCTSTree<GameState>.EvaluationResults

    func evaluate(info: MCTSTree<GameState>.StatesInfo) async -> Results {
        info.forEach { item in
//            seenStates.insert(InternalState(item.state))
//            dropCountTally[item.state.dropCount] += 1
            if item.state.field.garbageCount == 0 {
                doneStateDepths[item.state.dropCount, default: 0]  += 1
            }
        }
        count += info.count

        if count - lastPrint >= 10000 {
//            let ratio = (seenStates.count * 100 / count)
            print("***********************************")
            print("BCTSEvaluator states count:")
            print("    \(count) evaluations")
//            print("    \(seenStates.count) unique states (\(ratio)%)")
            print("    done states: \(doneStateDepths.sorted(by: {$0.key < $1.key }))")
//            print("    tally: \(dropCountTally)")
            print("***********************************")
            lastPrint += 10000
//            count = 0
//            seenStates.removeAll(keepingCapacity: true)
        }

        return info.map(evaluate)
    }
}

private extension BCTSEvaluator {

    func evaluate(_ entry: (id: ObjectIdentifier,
                            state: State, nextActions: [Action])) -> (id: ObjectIdentifier,
                                                                      value: Double, priors: [Double]?) {
        let (id, state, nextActions) = entry
        let field = state.field

        // How to use BCTS for a good evaluation is still TBD, can factor in
        // how many pieces are placed so far vs. how many garbages cleared so far,
        // while BCTS, like neural network, gives an assessment of the current
        // field as it is.  Although, BCTS does take a little bit of history into
        // account, that is, it evaluates the action itself as well as the
        // resulting field.

        // Also, we might also think of a reasonable heuristic for priors.
        // What if I split the BCTS components, use the field parts for state eval
        // and the action parts for prior?

        // Assume (-4000 ~ 0)
        let rawFieldValue = evaluateField(field)
        let fieldValue = (rawFieldValue / 2000) + 1
        // Assume (0 ~ 0.5)
        let rawPastValue = Double(state.garbageCleared) / Double(state.dropCount + 1)
        let pastValue = rawPastValue * 4 - 1
        // Arbitrary interpolation & clamping
        let value = max(-1, min(1, (0.7 * fieldValue + 0.3 * pastValue)))

        // If the field has no more garbage, give it a boost and don't need priors
        if field.garbageCount == 0 {
            return (id: id, value: (0.5 + 0.5 * value), priors: nil)
        }

        // Assume evaluateMove in (-150 ~ 50)
        let rawPriors = nextActions.map { piece in
            evaluateMove(field: field, piece: piece) + 500
        }
        let rawSum = rawPriors.reduce(0, +)
        let priors = rawPriors.map { $0 / rawSum }

        return (id: id, value: value, priors: priors)
    }
}


/// BCTS value, according to the Building Controllers for Tetris paper
/// Thiery & Scherrer
/// This value seems basically always in the negatives, from minus a few hundred
/// to >3000 in utterly terrible fields
func calculateBCTSValue(field: Field, piece: Piece, parentField: Field) -> Double {
    let lines = field.storage

    // Landing height
    let landingHeight = Double(piece.y - field.garbageCount)

    // Eroded piece cells
    // (similar to locking down a piece on field)
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
    let rowTransitions: Double = lines.reduce(0.0) {
        let left = ($1 << 1) + 1
        let right = $1 + 1024
        return $0 + Double((left ^ right).nonzeroBitCount)
    }

    // Column transitions
    let columnTransitions: Double = zip(lines, lines.dropFirst() + [0]).reduce(0.0) {
        $0 + Double(($1.0 ^ $1.1).nonzeroBitCount)
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

    // Indices of top filled cell of each column, -1 if empty (not used in score)
    let columnTops: [Int] = (0 ..< 10).map { (index) -> Int in
        let mask: Int16 = 1 << index
        return lines.lastIndex { $0 & mask != 0 } ?? -1
    }

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


/// The part of BCTS that only concerns the current field.
/// TBD:  How to normalize to between -1 and 1.
private func evaluateField(_ field: Field) -> Double {
    let lines = field.storage

    // Row transitions
    let rowTransitions: Double = lines.reduce(0.0) {
        let left = ($1 << 1) + 1
        let right = $1 + 1024
        return $0 + Double((left ^ right).nonzeroBitCount)
    }

    // Column transitions
    let columnTransitions: Double = zip(lines, lines.dropFirst() + [0]).reduce(0.0) {
        $0 + Double(($1.0 ^ $1.1).nonzeroBitCount)
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

    // Indices of top filled cell of each column, -1 if empty (not used in score)
    let columnTops: [Int] = (0 ..< 10).map { (index) -> Int in
        let mask: Int16 = 1 << index
        return lines.lastIndex { $0 & mask != 0 } ?? -1
    }

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

    return ( -9.22 * rowTransitions) +
           (-19.77 * columnTransitions) +
           (-13.08 * holes) +
           (-10.49 * cumulativeWells) +
           ( -1.61 * holeDepth) +
           (-24.04 * rowsWithHoles)
}

/// The part of BCTS that only concerns the piece placement.
/// In BCTS it uses the last field and last piece, but it makes sense
/// to be used for this field and next pieces as well.
/// Normalization / turning to priors is also TBD.
private func evaluateMove(field: Field, piece: Piece) -> Double {
    
    // Landing height
    let landingHeight = Double(piece.y - field.garbageCount + 1)

    // Eroded piece cells
    // (similar to locking down a piece on field)
    let pieceIndex = piece.bitmaskIndex
    let pieceMasks = pieceBitmasks[pieceIndex]
    let boundOffsets = pieceBoundOffsets[pieceIndex]
    let pieceLeft = piece.x - boundOffsets.left
    let bottomRow = piece.y - boundOffsets.bottom

    var linesCleared = 0
    var cellsEroded = 0
    for (i, mask) in pieceMasks.enumerated() {
        let row = bottomRow + i
        if row < field.height {
            let line = field.storage[row]
            if line | (mask << pieceLeft) == 0b11111_11111 {
                linesCleared += 1
                cellsEroded += (10 - line.nonzeroBitCount)
            }
        }
    }

    let erodedPieceCells = Double(linesCleared * cellsEroded)

    return (-12.63 * landingHeight) +
           (  6.60 * erodedPieceCells)
}

