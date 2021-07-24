//
//  MCTSState.swift
//
//
//  Created by Paul on 7/24/21.
//

import Foundation


public protocol MCTSState {
    associatedtype Action

    func getLegalActions() -> [Action]
    func getNextState(for: Action) -> Self
}
