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
public struct GameState {

    static let defaultGarbageCount = 8

    let environment: DigEnvironment
    public let field: Field
    let hold: Tetromino?
    let dropCount: Int
    let garbageCleared: Int

    public init(garbageCount: Int, garbageSeed: UInt64? = nil, pieceSeed: UInt64? = nil) {
        self.environment = DigEnvironment(garbageCount: garbageCount, garbageSeed: garbageSeed, pieceSeed: pieceSeed)

        let storage: [Int16] = environment.garbages.suffix(Self.defaultGarbageCount)
        self.field = Field(storage: storage, garbageCount: storage.count)

        self.hold = nil
        self.dropCount = 0
        self.garbageCleared = 0
    }

    private init(environment: DigEnvironment, field: Field, hold: Tetromino?, dropCount: Int, garbageCleared: Int) {
        self.environment = environment
        self.field = field
        self.hold = hold
        self.dropCount = dropCount
        self.garbageCleared = garbageCleared
    }
}


extension GameState: MCTSState {}
public extension GameState {
    typealias Action = Piece

    func getLegalActions() -> [Piece] {
        field.findAllSimplePlacements(for: playablePieces)
    }

    func getNextState(for piece: Piece) -> GameState {
        assert(playablePieces.contains(piece.type))
        assert(field.canPlace(piece))

        var (newField, newGarbageCleared) = field.lockDown(piece)

        newGarbageCleared += garbageCleared
        newField = fieldReplenishedWithGarbage(newField)
        let newHold = (piece.type == playPiece) ? hold : playPiece

        return GameState(environment: environment, field: newField, hold: newHold, dropCount: dropCount + 1, garbageCleared: newGarbageCleared)
    }
}


extension GameState {
    var playPiece: Tetromino {
        hold == nil ? environment.pieces[dropCount] : environment.pieces[dropCount + 1]
    }

    private var playablePieces: [Tetromino] {
        let piece1 = hold ?? environment.pieces[dropCount]
        let piece2 = environment.pieces[dropCount + 1]
        return (piece1 == piece2) ? [piece1] : [piece1, piece2]
    }

    private func fieldReplenishedWithGarbage(_ newField: Field) -> Field {
        let wantedAddCount = Self.defaultGarbageCount - newField.garbageCount
        let hiddenLineCount = environment.garbages.count - garbageCleared - field.garbageCount
        guard wantedAddCount > 0, hiddenLineCount > 0 else {
            return newField
        }

        let addCount = min(wantedAddCount, hiddenLineCount)
        let upperIndex = hiddenLineCount
        let lowerIndex = hiddenLineCount - addCount
        let storage: [Int16] = environment.garbages[lowerIndex ..< upperIndex] + newField.storage

        return Field(storage: storage, garbageCount: newField.garbageCount + addCount)
    }
}


extension GameState: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "hold: \(hold?.debugDescription ?? "-"), cleared: \(garbageCleared), dropCount: \(dropCount)"
    }
}
