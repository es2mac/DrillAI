//
//  DrillBot.swift
//
//
//  Created by Paul on 7/28/21.
//

import Foundation


public final class DrillBot<Evaluator: MCTSEvaluator> {
    public typealias State = Evaluator.State
    public typealias Action = State.Action
    public typealias ActionVisits = MCTSTree<State>.ActionVisits

    private let tree: MCTSTree<State>
    private let evaluator: Evaluator

    public init(initialState: State, evaluator: Evaluator) {
        self.tree = MCTSTree(initialState: initialState)
        self.evaluator = evaluator
    }

    public func makeAMove() async -> Action? {
        var evaluationCount = 0

        while evaluationCount < 1000 {
            let info = await tree.getNextUnevaluatedStates(targetCount: 32)
            let results = await evaluator.evaluate(info: info)
            await tree.updateWithEvaluationResults(results)
            evaluationCount += 32
        }

        let orderedActions = await tree.getOrderedRootActions()
        return orderedActions.first?.action
    }

    public func think(minTimes: Int = 1000) async {
        var evaluationCount = 0
        let batchSize = 32

        while evaluationCount < minTimes {
            let info = await tree.getNextUnevaluatedStates(targetCount: batchSize)
            let results = await evaluator.evaluate(info: info)
            await tree.updateWithEvaluationResults(results)
            evaluationCount += batchSize
        }
    }

    public func getSortedActions() async -> [ActionVisits] {
        return await tree.getOrderedRootActions()
    }

    public func makeMoveWithCallback(action: @escaping ((Action?) -> Void)) {
        Task {
            let move = await makeAMove()
            action(move)
        }
    }
}


