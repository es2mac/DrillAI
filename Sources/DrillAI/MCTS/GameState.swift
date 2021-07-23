//
//  GameState.swift
//
//
//  Created by Paul on 7/24/21.
//

import Foundation


struct GameState {
    let field: Field
    let hold: Tetromino
    let step: Int
    let garbageCleared: Int
    var playPieceType: Tetromino? = nil // Not given until setting up children
}


extension GameState: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "hold: \(hold), cleared: \(garbageCleared), step: \(step)"
    }
}
