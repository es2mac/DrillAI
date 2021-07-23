//
//  FieldUtilities.swift
//  
//
//  Created by Paul on 7/5/21.
//


import Foundation


/**
 Here is a collection of utility functions / constants for checking whether a piece fits on a field.
 To quickly check whether a piece (with tetromino type, orientation and center position) collides
 with what's already on the field, we use bitwise AND, line-by-line (in the case of `pieceBitmasks`)
 or one-shot multi-lines (in the case of `wholePieceBitmasks`).

 To describe what a tetromino looks like in a particular rotation, here I
 specify lines of bitmasks, and use "bound offsets" to describe the shape of
 the bounding box.  For example, (.J, .down) looks like

     111
     100

 and it's in a 2x3 box, with the center point being the top middle cell.
 So to specify the box, I specify how far the boundaries are in four
 directions from the center, i.e. 1 to the left/right/bottom, 0 to top.

 Ref: https://harddrop.com/wiki/SRS

 For performance, each of these sets of constants are packed in arrays with custom indexing scheme
 (piece.typeAndOrientationIndex) to make sure they can be retrieved as efficiently as possible.
 The more intuitive, switch-based constant definitions are kept private.
 */

/// Bitmasks of every piece in every orientation
let pieceBitmasks: [[Int16]] = .init(unsafeUninitializedCapacity: 7 * 4) { buffer, initializedCount in
    buffer.initialize(repeating: [])
    for type in Tetromino.allCases {
        for orientation in Piece.Orientation.allCases {
            let piece = Piece(type: type, x: 0, y: 0, orientation: orientation)
            buffer[piece.typeAndOrientationIndex] = makePieceBitmasks(type: type, orientation: orientation)
        }
    }
    initializedCount = 7 * 4
}


/// Bitmasks of every piece in every orientation, multi-lined in one Int
let wholePieceBitmasks: [Int] = pieceBitmasks.map { lines in
    lines.reversed().reduce(0, { (wholePieceMask, line) in
        (wholePieceMask << 10) | Int(line)
    })
}


/// For the box, how far are the 4 box edges are from the piece's center
let pieceBoundOffsets: [(top: Int, left: Int, right: Int, bottom: Int)] = { () -> [(top: Int, left: Int, right: Int, bottom: Int)] in
    var offsets = [(top: Int, left: Int, right: Int, bottom: Int)](repeating: (top: 0, left: 0, right: 0, bottom: 0), count: 7 * 4)
    for type in Tetromino.allCases {
        for orientation in Piece.Orientation.allCases {
            let piece = Piece(type: type, x: 0, y: 0, orientation: orientation)
            offsets[piece.typeAndOrientationIndex] = getBoundOffsets(type: type, orientation: orientation)
        }
    }
    return offsets
}()


private func makePieceBitmasks(type: Tetromino, orientation: Piece.Orientation) -> [Int16] {
    switch (type, orientation) {
    case (.I, .up),    (.I, .down): return [0b1111]
    case (.I, .right), (.I, .left): return [0b1, 0b1, 0b1, 0b1]
    case (.J, .up)   : return [0b111, 0b1]
    case (.J, .right): return [0b1, 0b1, 0b11]
    case (.J, .down) : return [0b100, 0b111]
    case (.J, .left) : return [0b11, 0b10, 0b10]
    case (.L, .up)   : return [0b111, 0b100]
    case (.L, .right): return [0b11, 0b1, 0b1]
    case (.L, .down) : return [0b1, 0b111]
    case (.L, .left) : return [0b10, 0b10, 0b11]
    case (.O, _)     : return [0b11, 0b11]
    case (.S, .up),    (.S, .down): return [0b11, 0b110]
    case (.S, .right), (.S, .left): return [0b10, 0b11, 0b1]
    case (.T, .up)   : return [0b111, 0b10]
    case (.T, .right): return [0b1, 0b11, 0b1]
    case (.T, .down) : return [0b10, 0b111]
    case (.T, .left) : return [0b10, 0b11, 0b10]
    case (.Z, .up),    (.Z, .down): return [0b110, 0b11]
    case (.Z, .right), (.Z, .left): return [0b1, 0b11, 0b10]
    }
}


private func getBoundOffsets(type: Tetromino, orientation: Piece.Orientation) -> (top: Int, left: Int, right: Int, bottom: Int) {
    switch (type, orientation) {
    case (.I, .up)   : return (top: 0, left: 1, right: 2, bottom: 0)
    case (.I, .right): return (top: 1, left: 0, right: 0, bottom: 2)
    case (.I, .down) : return (top: 0, left: 2, right: 1, bottom: 0)
    case (.I, .left) : return (top: 2, left: 0, right: 0, bottom: 1)
    case (.O, .up)   : return (top: 1, left: 0, right: 1, bottom: 0)
    case (.O, .right): return (top: 0, left: 0, right: 1, bottom: 1)
    case (.O, .down) : return (top: 0, left: 1, right: 0, bottom: 1)
    case (.O, .left) : return (top: 1, left: 1, right: 0, bottom: 0)
    case ( _, .up)   : return (top: 1, left: 1, right: 1, bottom: 0)
    case ( _, .right): return (top: 1, left: 0, right: 1, bottom: 1)
    case ( _, .down) : return (top: 0, left: 1, right: 1, bottom: 1)
    case ( _, .left) : return (top: 1, left: 1, right: 0, bottom: 1)
    }
}


