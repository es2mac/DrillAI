//
//  DrillBot.swift
//
//
//  Created by Paul on 7/28/21.
//

import Foundation


public final class DrillBot<Evaluator: MCTSEvaluator> where Evaluator.State == GameState {
    public typealias State = GameState
    public typealias Action = Piece
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

//    struct Info: @unchecked Sendable {
//        let items: [(id: ObjectIdentifier, state: GameState, nextActions: [GameState.Action])]
//    }

    // This task group-based concurrent implementation causes memroy leak,
    // which seems to be a bug (https://bugs.swift.org/browse/SR-14973)
    // Need to study: how do you cancel a task (and maybe get partial results)?
    // I should not need to worry about partial results too much because of
    // the nature of MCTS
    public func thinkTillEnoughConcurrently() async -> [ActionVisits] {
        let target = 6_000
        var weightedCounts = 0
        var orderedActions: [ActionVisits] = []

//        var info: Info = Info(items: await self.tree.getNextUnevaluatedStates(targetCount: 32))
        typealias Info = [(id: ObjectIdentifier, state: GameState, nextActions: [GameState.Action])]
        var info: Info = []

        while weightedCounts < target {
//            let passedInfo = info!
//            info = nil
//            let newInfo: Info = await withTaskGroup(of: Info?.self) { [info] group in
            let newInfo: Info = await withTaskGroup(of: Info.self) { [info] group in
//                if !info.items.isEmpty {
                if !info.isEmpty {
                    group.addTask {
//                        print("Task evaluation")
//                        let results = await self.evaluator.evaluate(info: info.items)
                        let results = await self.evaluator.evaluate(info: info)
                        await self.tree.updateWithEvaluationResults(results)
//                        return nil
                        return []
                    }
                }
                group.addTask {
//                    print("Task tree search")
//                    return Info(items: await self.tree.getNextUnevaluatedStates(targetCount: 32))
                    await self.tree.getNextUnevaluatedStates(targetCount: 32)
                }
                for await info in group {
//                    if let info = info {
                    if !info.isEmpty {
                        return info
                    }
                }
//                return Info(items: [])
                return []
            }

            info = newInfo

            orderedActions = await tree.getOrderedRootActions()
            if orderedActions.count < 3 { break }

            let topVisits = orderedActions[0].visits
            let secondVisits = orderedActions[1].visits
            let thirdVisits = orderedActions[2].visits
            weightedCounts = topVisits + secondVisits / 2 + thirdVisits / 4
        }

        return orderedActions
    }

    public func thinkTillEnough() async -> [ActionVisits] {
        let target = 6_000
        var weightedCounts = 0
        var orderedActions: [ActionVisits] = []

        while weightedCounts < target {
            var evaluationCount = 0
            while evaluationCount < 1000 {
                let info = await tree.getNextUnevaluatedStates(targetCount: 32)
                let results = await evaluator.evaluate(info: info)
                await tree.updateWithEvaluationResults(results)
                evaluationCount += 32
            }
            orderedActions = await tree.getOrderedRootActions()
            if orderedActions.count < 3 { break }

            let topVisits = orderedActions[0].visits
            let secondVisits = orderedActions[1].visits
            let thirdVisits = orderedActions[2].visits
            weightedCounts = topVisits + secondVisits / 2 + thirdVisits / 4
        }

        return orderedActions
    }

    public func getSortedActions() async -> [ActionVisits] {
        return await tree.getOrderedRootActions()
    }

    public func advance(with action: Action) async -> State {
        let newState = await tree.promoteRoot(action: action)
        return newState
    }

    public func makeMoveWithCallback(action: @escaping ((Action?) -> Void)) {
        Task {
            let move = await makeAMove()
            action(move)
        }
    }
}



