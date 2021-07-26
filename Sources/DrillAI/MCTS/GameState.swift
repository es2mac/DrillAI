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
 something that manages the game.

 Evaluation will also need the garbage cleared count and the step, because in addition
 to how easy it is to clear many lines from this point on, I also want to consider how
 well it's been doing prior (as this is not like Go, where only the end result matters).
 */
struct GameState {

    static let defaultGarbageCount = 8

    let environment: DigEnvironment
    let field: Field
    let hold: Tetromino?
    let dropCount: Int
    let garbageCleared: Int

    init(garbageCount: Int, garbageSeed: UInt64? = nil, pieceSeed: UInt64? = nil) {
        self.environment = DigEnvironment(garbageCount: garbageCount, garbageSeed: garbageSeed, pieceSeed: pieceSeed)

        let storage: [Int16] = environment.garbages.suffix(Self.defaultGarbageCount)
        self.field = Field(storage: storage, garbageCount: storage.count)

        self.hold = nil
        self.dropCount = 0
        self.garbageCleared = 0
    }
}


extension GameState: MCTSState {
    typealias Action = Piece

    func getLegalActions() -> [Piece] {
        // Dummy, TBD
        // Note: Eventually when the garbages are done, there should be no more action
//        let availableTypes = (playPieceType == hold) ? [hold] : [hold, playPieceType]
//        let nextActions = field.findAllSimplePlacements(for: availableTypes)
//        return nextActions

        return []
    }

    func getNextState(for piece: Piece) -> GameState {
//        assert(field.canPlace(piece))

//        let (newField, newGarbageCleared) = field.lockDown(piece)

        // missing hold and play piece logic
//        let newHold = (placedPiece.type == state.playPieceType) ? state.hold : state.playPieceType!

//        let state = GameState(field: newField,
//                              hold: hold,
//                              step: step + 1,
//                              garbageCleared: garbageCleared + newGarbageCleared,
//                              playPieceType: playPieceType)
//        return state
        return self
    }
}


extension GameState: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "hold: \(hold), cleared: \(garbageCleared), dropCount: \(dropCount)"
    }
}
