//
//  Piece.swift
//  
//
//  Created by Paul on 7/5/21.
//

import Foundation


/// A piece is a tetromino that has an orientation and a position on the field.
/// It could also represent an action performed (placing down a piece) in the game tree.
/// Sometimes, we may use it just for the Tetromino type and orientation,
/// ignoring position.
public struct Piece {
    public enum Orientation: Int, CaseIterable {
        case up, right, down, left
    }
    
    public let type: Tetromino
    public var x: Int
    public var y: Int
    public var orientation: Orientation = .up

    public init(type: Tetromino, x: Int, y: Int, orientation: Orientation) {
        self.type = type
        self.x = x
        self.y = y
        self.orientation = orientation
    }
}


extension Piece: Hashable {
    /// This encoding is unique and reversible (for reasonable height y),
    /// so we can store the whole piece compactly as just an Int.
    public var code: Int {
        return ((x + y * 10) << 5) | (type.rawValue << 2) | orientation.rawValue
    }
    
    public init(code: Int) {
        let x = (code >> 5) % 10
        let y = (code >> 5) / 10
        let type = Tetromino(rawValue: (code >> 2) & 0b111)!
        let orientation = Orientation(rawValue: code & 0b11)!
        self.init(type: type, x: x, y: y, orientation: orientation)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}


extension Piece {
    /// Index internally used mainly to construct & access bitmask constants.
    /// As bitmasks are defined for just the minimum rectangle enclosing the piece,
    /// it only concerns the type & orientatation, not its position.
    /// See: FieldUtilities
    var bitmaskIndex: Int {
        return type.rawValue * 4 + orientation.rawValue
    }
}


// ASCII "drawing" of Piece
extension Piece: CustomDebugStringConvertible {
    public var debugDescription: String {
        let masks = pieceBitmasks[bitmaskIndex]
        let lines = masks.map {
            String($0, radix: 2)
                .replacingOccurrences(of: "0", with: " ")
                .replacingOccurrences(of: "1", with: "X")
        }

        var joinedLines = String(lines.joined(separator: "\n").reversed())
        joinedLines += String(repeating: " ", count: 6 - lines.last!.count)
        joinedLines += "(\(x), \(y))\n"
        return "\n" + joinedLines
    }
}
