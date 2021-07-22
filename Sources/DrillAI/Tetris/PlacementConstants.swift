//
//  PlacementConstants.swift
//  
//
//  Created by Paul on 7/5/21.
//

import Foundation

/// Tetromino's starting placements are x-coordinates + orientations reached by
/// 2-step finesse, without obstruction and disregarding y-coordinates.
/// Hard-dropping from here becomes a "simple placement," below.

typealias StartingPlacement = (x: Int, orientation: Piece.Orientation)


/// Constants for simple dropping positions
func getStartingPlacements(type: Tetromino) -> [StartingPlacement] {
    switch type {
    case .J, .L, .T: return placementsJLT
    case .S, .Z: return placementsSZ
    case .O: return placementsO
    case .I: return placementsI
    }
}

let placementsO: [StartingPlacement] = [
    (x: 0, orientation: .up),
    (x: 1, orientation: .up),
    (x: 2, orientation: .up),
    (x: 3, orientation: .up),
    (x: 4, orientation: .up),
    (x: 5, orientation: .up),
    (x: 6, orientation: .up),
    (x: 7, orientation: .up),
    (x: 8, orientation: .up)
]

let placementsI: [StartingPlacement] = [
    (x: 1, orientation: .up),
    (x: 2, orientation: .up),
    (x: 3, orientation: .up),
    (x: 4, orientation: .up),
    (x: 5, orientation: .up),
    (x: 6, orientation: .up),
    (x: 7, orientation: .up),

    (x: 0, orientation: .left),
    (x: 1, orientation: .left),
    (x: 2, orientation: .right),
    (x: 3, orientation: .left),
    (x: 4, orientation: .left),
    (x: 5, orientation: .right),
    (x: 6, orientation: .right),
    (x: 7, orientation: .left),
    (x: 8, orientation: .right),
    (x: 9, orientation: .right)
]

let placementsSZ: [StartingPlacement] = [
    (x: 1, orientation: .up),
    (x: 2, orientation: .up),
    (x: 3, orientation: .up),
    (x: 4, orientation: .up),
    (x: 5, orientation: .up),
    (x: 6, orientation: .up),
    (x: 7, orientation: .up),
    (x: 8, orientation: .up),

    (x: 1, orientation: .left),
    (x: 1, orientation: .right),
    (x: 3, orientation: .left),
    (x: 4, orientation: .left),
    (x: 4, orientation: .right),
    (x: 5, orientation: .right),
    (x: 6, orientation: .right),
    (x: 8, orientation: .left),
    (x: 8, orientation: .right)
]

let placementsJLT: [StartingPlacement] = [
    (x: 1, orientation: .up),
    (x: 2, orientation: .up),
    (x: 3, orientation: .up),
    (x: 4, orientation: .up),
    (x: 5, orientation: .up),
    (x: 6, orientation: .up),
    (x: 7, orientation: .up),
    (x: 8, orientation: .up),

    (x: 0, orientation: .right),
    (x: 1, orientation: .right),
    (x: 2, orientation: .right),
    (x: 3, orientation: .right),
    (x: 4, orientation: .right),
    (x: 5, orientation: .right),
    (x: 6, orientation: .right),
    (x: 7, orientation: .right),
    (x: 8, orientation: .right),

    (x: 1, orientation: .down),
    (x: 2, orientation: .down),
    (x: 3, orientation: .down),
    (x: 4, orientation: .down),
    (x: 5, orientation: .down),
    (x: 6, orientation: .down),
    (x: 7, orientation: .down),
    (x: 8, orientation: .down),

    (x: 1, orientation: .left),
    (x: 2, orientation: .left),
    (x: 3, orientation: .left),
    (x: 4, orientation: .left),
    (x: 5, orientation: .left),
    (x: 6, orientation: .left),
    (x: 7, orientation: .left),
    (x: 8, orientation: .left),
    (x: 9, orientation: .left)
]
