//
//  GameRecorder.swift
//
//
//  Created by Paul on 8/20/21.
//

import Foundation


public typealias GameRecord = Drillai_GameRecord

public enum ExportError: Error {
    case getPathFailed
}

public final class GameRecorder {
    public typealias ActionVisits = MCTSTree<GameState>.ActionVisits

    private let initiatedDate: Date = Date()

    // Each earch result & action should have a corresponding state, but not
    // vice versa.  Generally there would be one more state than the other two.
    private var states: [GameState] {
        // Don't read count directly, to prevent race condition
        didSet { lastStep = states.count - 1 }
    }
    private var lastStep: Int = 0
    private var searchResults: [[ActionVisits]]
    private var actions: [Piece]

    // Step is the index of the current state.
    public private(set) var step: Int = 0
    public var isAtLastStep: Bool { step == lastStep }

    public init(initialState: GameState) {
        self.states = [initialState]
        self.searchResults = []
        self.actions = []
    }
}


public extension GameRecorder {
    func log(searchResult: [ActionVisits], action: Piece, newState: GameState) {
        if states.count - 1 > step {
            states.replaceSubrange((step + 1)..., with: [])
            searchResults.replaceSubrange(step..., with: [])
            actions.replaceSubrange(step..., with: [])
        }
        searchResults.append(searchResult)
        actions.append(action)
        states.append(newState)
        step += 1
    }

    func stepForward() -> (state: GameState, searchResult: [ActionVisits]?)? {
        guard step < lastStep else {
            return nil
        }
        step += 1
        return stateAtCurrentStep()
    }

    func stepBackward() -> (state: GameState, searchResult: [ActionVisits]?)? {
        guard step > 0 else {
            return nil
        }
        step -= 1
        return stateAtCurrentStep()
    }

    func exportToDocumentFolder() throws {
        let data = encodeRecord()
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        if var path = paths.first {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
            let dateString = dateFormatter.string(from: initiatedDate)
            let fileName = dateString + " \(states[0].garbageTotal)L \(lastStep)p"
            path.appendPathComponent(fileName)
            path.appendPathExtension("pb")
            try data.write(to: path)
        } else {
            throw ExportError.getPathFailed
        }
    }

    func encodeRecord() -> Data {
        let environment = states[0].environment

        let record = GameRecord.with { record in
            record.garbageSeed = environment.garbageSeed
            record.pieceSeed = environment.pieceSeed
            record.playedPieces = actions.map(\.code).map(UInt32.init)
            record.steps = (0 ..< actions.count)
                .filter { states[$0].field.height <= 20 }
                .map(encodeStep)
        }
        return try! record.serializedData()
    }
}


private extension GameRecorder {
    func stateAtCurrentStep() -> (state: GameState, searchResult: [ActionVisits]?) {
        (state: states[step], searchResult: (step < searchResults.count) ? searchResults[step] : nil)
    }

    func encodeStep(_ i: Int) -> GameRecord.RecordStep {
        let state = states[i]

        // Field
        let fieldCells = state.field.storage.flatMap { row in
            (0 ..< 10).map { i in
                row & (1 << i) != 0
            }
        }

        // Play pieces starts with the current play piece, then maybe hold, then previews
        let playPieceType = state.playPieceType
        let tetrominos = ([playPieceType] +
                          (state.hold.map { [$0] } ?? []) +
                          state.nextPieceTypes).map { UInt32($0.rawValue) }

        // Specially encoded actions
        let searchResult = searchResults[i]
        let actions: [UInt32] = searchResult.map(\.action).map {
            let playPieceOrder = $0.type == playPieceType ? 0 : 1
            let position = $0.x + 10 * $0.y
            return UInt32(position + 200 * $0.orientation.rawValue + 800 * playPieceOrder)
        }

        // Normalize priors
        let totalN = Float(searchResult.map(\.visits).reduce(0, +))
        let priors = searchResult.map { Float($0.visits) / totalN }

        // Value as efficiency of next (up to) 14 piece drops
        let laterStateIndex = min(i + 14, states.count - 1)
        let clearCount = states[laterStateIndex].garbageCleared - state.garbageCleared
        let value = Float(clearCount) / Float(laterStateIndex - i)

        return GameRecord.RecordStep.with { step in
            step.fieldCells = fieldCells
            step.tetrominos = tetrominos
            step.actions = actions
            step.priors = priors
            step.value = value
        }
    }
}


