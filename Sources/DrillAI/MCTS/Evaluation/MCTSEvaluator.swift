//
//  MCTSEvaluator.swift
//
//
//  Created by Paul on 7/27/21.
//

import Foundation

public protocol MCTSEvaluator {
    associatedtype State: MCTSState

    func evaluate(info: MCTSTree<State>.StatesInfo) async -> MCTSTree.EvaluationResults
}

