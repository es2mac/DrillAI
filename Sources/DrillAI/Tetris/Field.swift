//
//  Field.swift
//  
//
//  Created by Paul on 7/5/21.
//

import Foundation


/// A Field can have an arbitrary number of rows.
/// This Field implementation is specifically meant for the dig race AI application,
/// with small memory footprint and fast "path-finding."
/// In particular, it keeps a count of the original garbage lines,
/// but otherwise does not remember the original form of each block
/// (i.e. which tetromino it was).
public struct Field {
    /// Each row is stored as bits in an Int16.
    /// By convention, empty top rows should be removed.
    /// That is, the last element should not be 0.
    public let storage: [Int16]
    /// As garbage rows and player-placed rows cannot be differentiated otherwise,
    /// we need to keep track of how many garbage rows there are.
    public let garbageCount: Int

    public var height: Int { return storage.count }

    public init(storage: [Int16] = [], garbageCount: Int = 0) {
        assert(storage.count >= garbageCount)
        self.storage = storage
        self.garbageCount = garbageCount
    }
}


public extension Field {
    /// Check if a piece can be placed on the field.
    /// Not useful for AI applications as there are more efficient ways to do it
    /// when we perform a large number of checks during search, such as below.
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

    func makeGhost(of piece: Piece) -> Piece {
        var ghostPiece = piece

        ghostPiece.y -= 1
        while canPlace(ghostPiece) {
            ghostPiece.y -= 1
        }
        ghostPiece.y += 1

        return ghostPiece
    }
}


public extension Field {
    /// Place (lock down) a piece.
    /// Returns a copy of the field with a piece placed in, and lines cleared.
    /// "Paste" the piece right onto the field, does not check if it's legal.
    /// However, it is assumed that e.g. if the piece spans rows 7~9, then
    /// the field must already have at least 6 rows.  This would be true if
    /// the piece locked legally.
    func lockDown(_ piece: Piece) -> (newField: Field, garbageCleared: Int) {
        let index = piece.bitmaskIndex
        let boundOffsets = pieceBoundOffsets[index]
        let pieceLeft = piece.x - boundOffsets.left
        let pieceMasks = pieceBitmasks[index]
        let bottomRow = piece.y - boundOffsets.bottom

        var newStorage = storage

        // Append or "OR" in the mask
        for (i, mask) in pieceMasks.enumerated() {
            let row = bottomRow + i
            if row >= newStorage.count {
                newStorage.append(mask << pieceLeft)
            } else {
                newStorage[row] |= (mask << pieceLeft)
            }
        }

        // Remove filled rows
        var garbageCleared = 0
        var newGarbageCount = garbageCount
        var checkRow = bottomRow
        for _ in 0 ..< pieceMasks.count {
            if newStorage[checkRow] == 0b11111_11111 {
                newStorage.remove(at: checkRow)
                if (checkRow < newGarbageCount) {
                    garbageCleared += 1
                    newGarbageCount -= 1
                }
            } else {
                checkRow += 1
            }
        }

        let newField = Field(storage: newStorage, garbageCount: newGarbageCount)
        return (newField: newField, garbageCleared: garbageCleared)
    }

    func findAllPlacements(for types: [Tetromino], slidesAndTwists: Bool = false) -> [Piece] {
        let lineMasks = makeMultiLineMasks()
        var placements = types.flatMap { findAllSimplePlacements(for: $0, lineMasks: lineMasks) }
        if slidesAndTwists, hasHinge(lineMasks: lineMasks) {
            // Hack: piece may be entirely above existing cells, and kicking
            // could raise bottom of piece by up to 3 cells, so pre-pad the masks
            appendSlideAndTwistPlacements(to: &placements, lineMasks: lineMasks + [0, 0, 0, 0])
        }
        return placements
    }
}

internal extension Field {
    /// Find all possible simple (hard-dropped from top) placements of a tetromino.
    ///
    /// Simple placements are those reached by shifting & rotating first
    /// at the top of the field, then dropped straight down.
    /// That is, no soft-drop then slide or twist.
    func findAllSimplePlacements(for type: Tetromino, lineMasks: [Int]) -> [Piece] {
        // Find all the starting positions (x & orientation) for all the pieces
        // (1 or 2, i.e. play & hold), before figuring out how far it can drop.
        var pieces: [Piece] = getStartingPlacements(type: type).map {
                Piece(type: type, x: $0.x, y: 0, orientation: $0.orientation)
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

    /// Search for additional valid placements that are a slide away (any
    /// distace), or one spin away from the given ones.
    func appendSlideAndTwistPlacements(to placements: inout [Piece], lineMasks: [Int]) {
        var foundPlacementCodes = Set(placements.map(\.isomorphicCode))
        let originalCount = placements.count

        for i in 0 ..< originalCount {
            let piece = placements[i]
            // slides
            do {
                let bitmaskIndex = piece.bitmaskIndex
                let boundOffsets = pieceBoundOffsets[bitmaskIndex]
                let pieceMask = wholePieceBitmasks[bitmaskIndex] << (piece.x - boundOffsets.left)
                let pieceBottomRowIndex = piece.y - boundOffsets.bottom
                let pieceBottomRowMask = lineMasks[pieceBottomRowIndex]

                // slide left
                var shift = -1
                var newPiece = piece
                newPiece.x -= 1
                // Is it in-bound?  Is there collision?  Is it already seen?
                while newPiece.x - boundOffsets.left >= 0,
                      ((pieceMask << shift) & pieceBottomRowMask) == 0,
                      case (true, _) = foundPlacementCodes.insert(newPiece.isomorphicCode) {
                    // is it landed?
                    if pieceBottomRowIndex == 0 || ((pieceMask << shift) & lineMasks[pieceBottomRowIndex - 1]) != 0 {
                        placements.append(newPiece)
                    }
                    shift -= 1
                    newPiece.x -= 1
                }

                // slide right
                shift = 1
                newPiece.x = piece.x + 1
                // Is it in-bound?  Is there collision?  Is it already seen?
                while newPiece.x + boundOffsets.right < 10,
                      ((pieceMask << shift) & pieceBottomRowMask) == 0,
                      case (true, _) = foundPlacementCodes.insert(newPiece.isomorphicCode) {
                    // is it landed?
                    if pieceBottomRowIndex == 0 || ((pieceMask << shift) & lineMasks[pieceBottomRowIndex - 1]) != 0 {
                        placements.append(newPiece)
                    }
                    shift += 1
                    newPiece.x += 1
                }
            }

            // twists
            // turn right
            // For rotations, we do want to check double rotations
            var stack = [piece]
            if let isomorphicPiece = piece.isomorphicPiece {
                stack.append(isomorphicPiece)
            }
            while var piece = stack.popLast() {
                // Get the kicks before changing piece orientation
                let kickOffsets = rightKickOffsets[piece.bitmaskIndex]
                piece.orientation = piece.orientation.rotatedRight()
                let bitmaskIndex = piece.bitmaskIndex
                let pieceMask = wholePieceBitmasks[bitmaskIndex]
                let boundOffsets = pieceBoundOffsets[bitmaskIndex]

                var pieceLeft = piece.x - boundOffsets.left
                var pieceRight = piece.x + boundOffsets.right
                var pieceBottomRowIndex = piece.y - boundOffsets.bottom

                for (offsetX, offsetY) in kickOffsets {
                    piece.x += offsetX
                    piece.y += offsetY
                    pieceLeft += offsetX
                    pieceRight += offsetX
                    pieceBottomRowIndex += offsetY
                    // Is it in-bound?  Is there collision?
                    // Then it's a successful spin
                    if pieceBottomRowIndex >= 0,
                       pieceLeft >= 0,
                       pieceRight < 10,
                       (pieceMask << pieceLeft) & lineMasks[pieceBottomRowIndex] == 0 {
                        // Is it already seen?  Is it landed?
                        if case (true, _) = foundPlacementCodes.insert(piece.isomorphicCode),
                           (pieceBottomRowIndex == 0 ||
                            ((pieceMask << pieceLeft) & lineMasks[pieceBottomRowIndex - 1]) != 0) {
                            placements.append(piece)
                            stack.append(piece)
                        }
                        break
                    }
                }
            }

            // turn left
            stack.append(piece)
            if let isomorphicPiece = piece.isomorphicPiece {
                stack.append(isomorphicPiece)
            }
            while var piece = stack.popLast() {
                // Get the kicks before changing piece orientation
                let kickOffsets = leftKickOffsets[piece.bitmaskIndex]
                piece.orientation = piece.orientation.rotatedLeft()
                let bitmaskIndex = piece.bitmaskIndex
                let pieceMask = wholePieceBitmasks[bitmaskIndex]
                let boundOffsets = pieceBoundOffsets[bitmaskIndex]

                var pieceLeft = piece.x - boundOffsets.left
                var pieceRight = piece.x + boundOffsets.right
                var pieceBottomRowIndex = piece.y - boundOffsets.bottom

                for (offsetX, offsetY) in kickOffsets {
                    piece.x += offsetX
                    piece.y += offsetY
                    pieceLeft += offsetX
                    pieceRight += offsetX
                    pieceBottomRowIndex += offsetY
                    // Is it in-bound?  Is there collision?
                    // Then it's a successful spin
                    if pieceBottomRowIndex >= 0,
                       pieceLeft >= 0,
                       pieceRight < 10,
                       (pieceMask << pieceLeft) & lineMasks[pieceBottomRowIndex] == 0 {
                        // Is it already seen?  Is it landed?
                        if case (true, _) = foundPlacementCodes.insert(piece.isomorphicCode),
                           (pieceBottomRowIndex == 0 ||
                            ((pieceMask << pieceLeft) & lineMasks[pieceBottomRowIndex - 1]) != 0) {
                            placements.append(piece)
                            stack.append(piece)
                        }
                        break
                    }
                }
            }
        }
    }


    /// Try to find a hinged, filled cell with 3 empty neighbors, as a fast
    /// pre-check for whether there may be a possible slide or twist move.
    /// A hinge looks like:   O _          _ O
    ///                       _ _    or    _ _
    func hasHinge(lineMasks: [Int]) -> Bool {
        let mask = 0b00000_00011_00000_00011
        let leftHinge = 0b00000_00001_00000_00000
        let rightHinge = 0b00000_00010_00000_00000
        for line in lineMasks {
            for i in 0 ..< 9 {
                let square = line & (mask << i)
                if square == (leftHinge << i) || square == (rightHinge << i) {
                    return true
                }
            }
        }
        return false
    }

    /// "Stack up" the lines so that each mask can be used to check
    /// the placement of a piece with a single operation.
    func makeMultiLineMasks() -> [Int] {
        guard storage.count > 0 else { return [] }
        var masks = storage.map(Int.init)

        for i in (1 ..< masks.count).reversed() {
            masks[i - 1] |= (masks[i] << 10)
        }
        return masks
    }
}


private extension Piece {
    /// Coding the piece based on its shape on the field, so two pieces have
    /// the same code iff. they occupy the same cells.  In other words, S and
    /// Z both have two pieces that have the same code.
    /// Assumes that the piece actually fits in the field and not, e.g., extend
    /// past the floor.
    var isomorphicCode: Int {
        let index = bitmaskIndex
        let boundOffsets = pieceBoundOffsets[index]
        let pieceLeft = x - boundOffsets.left
        let pieceBottom = y - boundOffsets.bottom
        let pieceMask = wholePieceBitmasks[index] << pieceLeft
        return pieceMask * 10 + pieceBottom
    }

    var isomorphicPiece: Piece? {
        var copy = self
        switch type {
        case .S, .Z, .I:
            switch orientation {
            case .up:
                copy.orientation = .down
                copy.y += 1
            case .down:
                copy.orientation = .up
                copy.y -= 1
            case .right:
                copy.orientation = .left
                copy.x += 1
            case .left:
                copy.orientation = .right
                copy.x -= 1
            }
            return copy
        case .J, .L, .T, .O: return nil
        }
    }
}


extension Field: CustomDebugStringConvertible {
    public var debugDescription: String {
        var lines = storage.map { (n: Int16) -> String in
            let binaryString = String(n, radix: 2)
            let padding =  String(repeating: "0", count: (10 - binaryString.count))
            return padding + binaryString + "  "
        }
        if (garbageCount > 0) && (garbageCount <= lines.count) {
            lines[garbageCount - 1] = "==< " + lines[garbageCount - 1]
        }
        return String(lines.joined(separator: "\n").reversed())
            .replacingOccurrences(of: "0", with: "  ")
            .replacingOccurrences(of: "1", with: "O ")
    }
}

extension Field: Equatable {}
