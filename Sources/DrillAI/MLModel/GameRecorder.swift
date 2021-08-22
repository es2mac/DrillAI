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

    // Each earch result & action should have a corresponding state, but not
    // vice versa.  Generally there would be one more state than the other two.
    private(set) var states: [GameState]
    private(set) var searchResults: [[ActionVisits]]
    private(set) var actions: [Piece]

    // Step is the index of the current state.
    public private(set) var step: Int = 0
    public var lastStep: Int {
        states.count - 1
    }

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

    // Export results
}


private extension GameRecorder {
    func stateAtCurrentStep() -> (state: GameState, searchResult: [ActionVisits]?) {
        (state: states[step], searchResult: (step < searchResults.count) ? searchResults[step] : nil)
    }

    /// The environment contains the seeds & garbages
    var environment: DigEnvironment {
        states[0].environment
    }
}



