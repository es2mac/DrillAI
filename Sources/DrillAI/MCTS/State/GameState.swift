//
//  GameState.swift
//
//
//  Created by Paul on 7/24/21.
//

import Foundation


public struct GameState {

    static let defaultGarbageCount = 8

    let environment: DigEnvironment
    let slidesAndTwists: Bool
    public let field: Field
    public let hold: Tetromino?
    public let dropCount: Int
    public let garbageCleared: Int
    public var garbageTotal: Int { environment.garbages.count }
    public var garbageRemaining: Int { environment.garbages.count - garbageCleared }

    public init(garbageCount: Int, garbageSeed: UInt64? = nil, pieceSeed: UInt64? = nil, slidesAndTwists: Bool = false) {
        self.environment = DigEnvironment(garbageCount: garbageCount, garbageSeed: garbageSeed, pieceSeed: pieceSeed)
        self.slidesAndTwists = slidesAndTwists

        let storage: [Int16] = environment.garbages.suffix(Self.defaultGarbageCount)
        self.field = Field(storage: storage, garbageCount: storage.count)

        self.hold = nil
        self.dropCount = 0
        self.garbageCleared = 0
    }

    private init(environment: DigEnvironment, field: Field, hold: Tetromino?, dropCount: Int, garbageCleared: Int, slidesAndTwists: Bool) {
        self.environment = environment
        self.slidesAndTwists = slidesAndTwists
        self.field = field
        self.hold = hold
        self.dropCount = dropCount
        self.garbageCleared = garbageCleared
    }
}


extension GameState: MCTSState {}
public extension GameState {
    typealias Action = Piece

    var playPieceType: Tetromino {
        hold == nil ? environment.pieces[dropCount] : environment.pieces[dropCount + 1]
    }

    var nextPieceTypes: [Tetromino] {
        let startIndex = hold == nil ? dropCount + 1 : dropCount + 2
        return (startIndex ..< startIndex + 5).map { environment.pieces[$0] }
    }

    func getLegalActions() -> [Piece] {
        if field.garbageCount == 0 {
            return []
        }
        return field.findAllPlacements(for: playablePieces, slidesAndTwists: slidesAndTwists)
    }

    func getNextState(for piece: Piece) -> GameState {
        assert(playablePieces.contains(piece.type))
        assert(field.canPlace(piece))

        var (newField, newGarbageCleared) = field.lockDown(piece)

        newGarbageCleared += garbageCleared
        newField = fieldReplenishedWithGarbage(newField)
        let newHold = (piece.type == playPieceType) ? hold : playPieceType

        return GameState(environment: environment, field: newField, hold: newHold, dropCount: dropCount + 1, garbageCleared: newGarbageCleared, slidesAndTwists: slidesAndTwists)
    }
}


extension GameState {
    var remainingGarbageCount: Int {
        environment.garbages.count - garbageCleared
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
