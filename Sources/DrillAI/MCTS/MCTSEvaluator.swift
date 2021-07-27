//
//  MCTSEvaluator.swift
//
//
//  Created by Paul on 7/27/21.
//

import Foundation

protocol MCTSEvaluator {
    associatedtype State: MCTSState
    associatedtype Info // e.g. MCTSTree.StatesInfo & MCTSTree.ExtendedStatesInfo


    func evaluate(info: Info) async -> MCTSTree.EvaluationResults
}

