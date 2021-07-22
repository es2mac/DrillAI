//
//  Piece.swift
//  
//
//  Created by Paul on 7/5/21.
//

import Foundation

/// A piece is a tetromino with placement information.  Calling it "Piece"
/// instead of "Placement" to be intentionally ambiguous, to use in different
/// contexts where we need to describe more than just the Tetromino type.
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
    // This "hash" is unique and reversible, more like an Int representation
    // TODO: Rename this as some kind of coding, and use this code (or not?) when adopting the new Hashable requirement
    var hashValue: Int {
        return ((x + y * 10) << 5) | (type.rawValue << 2) | orientation.rawValue
    }
    
    init?(hashValue: Int) {
        // Hash of 0 would be flat I at (0, 0) which in fact doesn't fit on board, so can ignore
        guard hashValue != 0 else { return nil }
        let x = (hashValue >> 5) % 10
        let y = (hashValue >> 5) / 10
        // Assume center should be in the 10x20 field, though there could be edge
        // cases in the real world where y goes >= 20
        guard 0..<10 ~= x, 0..<20 ~= y else { return nil }
        let type = Tetromino(rawValue: (hashValue >> 2) & 0b111)!
        let orientation = Orientation(rawValue: hashValue & 0b11)!
        self.init(type: type, x: x, y: y, orientation: orientation)
    }
}

// Piece conforms to CustomDebugStringConvertible, but it needs some constants defined later
// extension Piece: CustomDebugStringConvertible {}

extension Piece {
    /// This index is used as index to construct & access some constants
    var typeAndOrientationIndex: Int {
        get { return type.rawValue * 4 + orientation.rawValue }
    }
}
