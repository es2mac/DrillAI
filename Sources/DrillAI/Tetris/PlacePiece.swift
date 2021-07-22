//
//  PlacePiece.swift
//  
//
//  Created by Paul on 7/5/21.
//

import Foundation

/// Place (lock down) a piece
extension Field {
    /// Returns a copy of the field with a piece placed in, and lines cleared.
    /// "Paste" the piece right onto the field, does not check if it's legal.
    /// However, it is assumed that e.g. if the piece spans rows 7~9, then
    /// the field must already have at least 6 rows.  This would be true if
    /// the piece locked legally.
    func lockDown(_ piece: Piece) -> (newField: Field, garbageCleared: Int) {

        let index = piece.typeAndOrientationIndex
        let boundOffsets = pieceBoundOffsets[index]
        let pieceLeft = piece.x - boundOffsets.left
        let pieceMasks = pieceBitmasks[index]
        let bottomRow = piece.y - boundOffsets.bottom

        var newStorage = storage

        // Append or OR in the mask
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

        return (newField: Field(storage: newStorage, garbageCount: newGarbageCount),
                garbageCleared: garbageCleared)
    }
}

