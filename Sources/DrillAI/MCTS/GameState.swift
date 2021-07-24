//
//  GameState.swift
//
//
//  Created by Paul on 7/24/21.
//

import Foundation


/*
 Hold should be optional, play piece might not be stored directly but rather as an
 index for fetching from a referenced game object with piece sequence

 From the outside, a caller doesn't really need to know what's held, as long as the
 state can properly figure out what are the possible next actions.  E.g. when hold
 is nil, we can actually play the next two pieces.

 Suppose the piece and garbage generators are outside, and the state's field may
 only be a partial portion near the top, I might need a reference pointer back to
 something that manages the game
 */
struct GameState {
    let field: Field
    let hold: Tetromino
    let step: Int
    let garbageCleared: Int
    var playPieceType: Tetromino? = nil // Not given until setting up children
}


extension GameState: MCTSState {
    typealias Action = Piece

    func getLegalActions() -> [Piece] {
        // Dummy, TBD
//        let availableTypes = (playPieceType == hold) ? [hold] : [hold, playPieceType]
//        let nextActions = field.findAllSimplePlacements(for: availableTypes)
//        return nextActions

        return []
    }

    func getNextState(for piece: Piece) -> GameState {
        assert(field.canPlace(piece))

        let (newField, newGarbageCleared) = field.lockDown(piece)

        // missing hold and play piece logic
//        let newHold = (placedPiece.type == state.playPieceType) ? state.hold : state.playPieceType!

        let state = GameState(field: newField,
                              hold: hold,
                              step: step + 1,
                              garbageCleared: garbageCleared + newGarbageCleared,
                              playPieceType: playPieceType)
        return state
    }
}


extension GameState: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "hold: \(hold), cleared: \(garbageCleared), step: \(step)"
    }
}
