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
struct Piece {
    enum Orientation: Int, CaseIterable {
        case up, right, down, left
    }
    
    let type: Tetromino
    var x: Int
    var y: Int
    var orientation: Orientation = .up
}


extension Piece: Hashable {
    // This encoding is unique and reversible, so we can store the whole piece compactly as jsut an Int.
    var code: Int {
        return ((x + y * 10) << 5) | (type.rawValue << 2) | orientation.rawValue
    }
    
    init?(code: Int) {
        // Hash of 0 would be flat I at (0, 0) which in fact doesn't fit on board, so can ignore
        guard code != 0 else { return nil }
        let x = (code >> 5) % 10
        let y = (code >> 5) / 10
        // Assume center should be in the 10x20 field, though there could be edge
        // cases in the real world where y goes >= 20
        guard 0..<10 ~= x, 0..<20 ~= y else { return nil }
        let type = Tetromino(rawValue: (code >> 2) & 0b111)!
        let orientation = Orientation(rawValue: code & 0b11)!
        self.init(type: type, x: x, y: y, orientation: orientation)
    }
}


/// Piece conforms to CustomDebugStringConvertible, but it needs some constants defined later
// extension Piece: CustomDebugStringConvertible {}
extension Piece {
    /// Index used to construct & access bitmask constants
    var typeAndOrientationIndex: Int {
        get { return type.rawValue * 4 + orientation.rawValue }
    }
}
