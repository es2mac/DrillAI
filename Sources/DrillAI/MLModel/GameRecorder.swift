//
//  GameRecorder.swift
//
//
//  Created by Paul on 8/20/21.
//

import Foundation


public final class GameRecorder {
    public typealias ActionVisits = MCTSTree<GameState>.ActionVisits

    private let initiatedDate: Date = Date()

    // There should always be 1 more states than actions or search results
    public private(set) var states: [GameState]
    public private(set) var actions: [Piece]
    public private(set) var searchResults: [[ActionVisits]]

    public init(initialState: GameState) {
        self.states = [initialState]
        self.actions = []
        self.searchResults = []
    }
}


public extension GameRecorder {
    func log(searchResult: [ActionVisits], action: Piece, newState: GameState) {
        searchResults.append(searchResult)
        actions.append(action)
        states.append(newState)
    }

    // Export results
}


private extension GameRecorder {
    /// The environment contains the seeds & garbages
    var environment: DigEnvironment {
        states[0].environment
    }
}



