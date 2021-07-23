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
    public let garbageCount: Int

    public var height: Int { return storage.count }

    public init(storage: [Int16] = [], garbageCount: Int = 0) {
        assert(storage.count >= garbageCount)
        self.storage = storage
        self.garbageCount = garbageCount
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

extension Field: Hashable {}
