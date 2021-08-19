//
//  PieceRotation.swift
//
//
//  Created by Paul on 8/18/21.
//

import Foundation

extension Piece.Orientation {
    func rotatedRight() -> Piece.Orientation {
        switch self {
        case .up: return .right
        case .right: return .down
        case .down: return .left
        case .left: return .up
        }
    }

    func rotatedLeft() -> Piece.Orientation {
        switch self {
        case .up: return .left
        case .left: return .down
        case .down: return .right
        case .right: return .up
        }
    }
}


/// Cached offsets for every type and rotation.  A bit different from what's
/// commonly done in that each offset is the "additional offset" on top of
/// the one before it.
let leftKickOffsets: [[(x: Int, y: Int)]] = .init(unsafeUninitializedCapacity: 7 * 4) { buffer, initializedCount in
    buffer.initialize(repeating: [])
    for type in Tetromino.allCases {
        for orientation in Piece.Orientation.allCases {
            let piece = Piece(type: type, x: 0, y: 0, orientation: orientation)
            buffer[piece.bitmaskIndex] = type.kickOffsets(from: orientation, to: orientation.rotatedLeft())
        }
    }
    initializedCount = 7 * 4
}

let rightKickOffsets: [[(x: Int, y: Int)]] = .init(unsafeUninitializedCapacity: 7 * 4) { buffer, initializedCount in
    buffer.initialize(repeating: [])
    for type in Tetromino.allCases {
        for orientation in Piece.Orientation.allCases {
            let piece = Piece(type: type, x: 0, y: 0, orientation: orientation)
            buffer[piece.bitmaskIndex] = type.kickOffsets(from: orientation, to: orientation.rotatedRight())
        }
    }
    initializedCount = 7 * 4
}


/* Borrowed logic from BombStepper */

private typealias Offset = (x: Int, y: Int)

private extension Tetromino {
    /// Strange implementation detail of the SRS rotation.  The four possible
    /// kick positions of rotating from orientation A to B is actually
    /// calculated as a difference between offsets of A and offsets of B.
    func internalOffsets(for orientation: Piece.Orientation) -> [Offset] {
        switch self {
        case .I:
            switch orientation {
            case .up:    return [( 0,  0), (-1,  0), ( 2,  0), (-1,  0), ( 2,  0)]
            case .right: return [(-1,  0), ( 0,  0), ( 0,  0), ( 0,  1), ( 0, -2)]
            case .down:  return [(-1,  1), ( 1,  1), (-2,  1), ( 1,  0), (-2,  0)]
            case .left:  return [( 0,  1), ( 0,  1), ( 0,  1), ( 0, -1), ( 0,  2)]
            }

        case .J, .L, .S, .T, .Z:
            switch orientation {
            case .up:    return [( 0,  0), ( 0,  0), ( 0,  0), ( 0,  0), ( 0,  0)]
            case .right: return [( 0,  0), ( 1,  0), ( 1, -1), ( 0,  2), ( 1,  2)]
            case .down:  return [( 0,  0), ( 0,  0), ( 0,  0), ( 0,  0), ( 0,  0)]
            case .left:  return [( 0,  0), (-1,  0), (-1, -1), ( 0,  2), (-1,  2)]
            }
        case .O:
            switch orientation {
            case .up:    return [( 0,  0)]
            case .right: return [( 0, -1)]
            case .down:  return [(-1, -1)]
            case .left:  return [(-1,  0)]
            }
        }
    }

    func kickOffsets(from fromOrientation: Piece.Orientation, to toOrientation: Piece.Orientation) -> [Offset] {
        let fromOffsets = internalOffsets(for: fromOrientation)
        let toOffsets = internalOffsets(for: toOrientation)
        var offsets = zip(fromOffsets, toOffsets).map(-)

        for i in (1 ..< offsets.count).reversed() {
            offsets[i] = offsets[i] - offsets[i-1]
        }

        return offsets
    }
}

private func -(lhs: Offset, rhs: Offset) -> Offset {
        return (x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

