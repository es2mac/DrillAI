//
//  MCTSState.swift
//
//
//  Created by Paul on 7/24/21.
//

import Foundation


/// The state used in the MCTS tree needs to be able to report what are the legal
/// actions, as well as generating the next state after taking each of those actions.
/// So although we'd like the state to be a simple value type, that might be
/// challenging for many games and requires some hidden complexities.
public protocol MCTSState {
    associatedtype Action

    func getLegalActions() -> [Action]
    func getNextState(for: Action) -> Self
}
