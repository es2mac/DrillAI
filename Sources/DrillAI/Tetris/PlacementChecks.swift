//
//  PlacementChecks.swift
//  
//
//  Created by Paul on 7/5/21.
//

import Foundation


/// Check if a piece can be placed on the field.
/// Not useful for AI applications as there are more efficient ways to do it
/// when we perform a large number of checks during search, such as below.
extension Field {
    func canPlace(_ piece: Piece) -> Bool {
        let index = piece.bitmaskIndex
        let boundOffsets = pieceBoundOffsets[index]
        let pieceLeft = piece.x - boundOffsets.left
        let pieceRight = piece.x + boundOffsets.right
        let pieceBottom = piece.y - boundOffsets.bottom
        let pieceTop = piece.y + boundOffsets.top

        guard pieceLeft >= 0, pieceRight < 10, pieceBottom >= 0 else { return false }

        // Only need to check for obstruction in rows that
        // the storage & the piece have in common
        if pieceBottom >= storage.count { return true }

        let pieceMask = wholePieceBitmasks[index] << pieceLeft
        let topRow = min(pieceTop, storage.count - 1)

        let fieldLines = storage[pieceBottom...topRow].reversed().reduce(0) { (total, line) -> Int in
            (total << 10) | Int(line)
        }

        return (pieceMask & fieldLines) == 0
    }
}


/// Find all possible simple (hard-dropped from top) placements of tetrominos
extension Field {
    /// "Stack up" the lines so that each mask can be used to check
    /// the placement of a piece with a single operation.
    private func makeMultiLineMasks() -> [Int] {
        guard storage.count > 0 else { return [] }
        var masks = storage.map(Int.init)

        for i in (1 ..< masks.count).reversed() {
            masks[i - 1] |= (masks[i] << 10)
        }
        return masks
    }

    /// Simple placements are those reached by shifting & rotating first
    /// at the top of the field, then dropped straight down.
    /// That is, no soft-drop then shift or twist.
    func findAllSimplePlacements(for types: [Tetromino]) -> [Piece] {
        let lineMasks = makeMultiLineMasks()
        // Find all the starting positions (x & orientation) for all the pieces
        // (1 or 2, i.e. play & hold), before figuring out how far it can drop.
        var pieces: [Piece] = types.flatMap { type in
            getStartingPlacements(type: type).map {
                Piece(type: type, x: $0.x, y: 0, orientation: $0.orientation)
            }
        }
        // Find the lowest that the piece can drop.
        // Loop with index so we can set the y value in-place.
        for i in 0 ..< pieces.count {
            let index = pieces[i].bitmaskIndex
            let boundOffsets = pieceBoundOffsets[index]
            let pieceLeft = pieces[i].x - boundOffsets.left
            let pieceMask = wholePieceBitmasks[index] << pieceLeft
            var bottomRow = storage.count
            while bottomRow > 0, (lineMasks[bottomRow-1] & pieceMask) == 0 {
                bottomRow -= 1
            }
            pieces[i].y = bottomRow + boundOffsets.bottom
        }
        return pieces
    }
}


/// Find all possible placements (including slides and spins)

// Work in progress.  Need to implement spin rules, graph search all placements,
// and eliminate isomorphic results.


// extension Field {
//   func findAllPlacements(for types: [Tetromino]) -> [Piece] {
//     let lineMasks = makeMultiLineMasks
//     var allPlacements: [Piece] = []

//     for type in types {
//       var pieces = getStartingPlacements[type].map {
//         Piece(type: type, x: $0.x, y: 0, orientation: $0.orientation)
//       }
//       // Find all simple placements, remember their wholePieceMasks and bottomRoww
//       // From the simple placements, see if
//     }


//   }
// }
