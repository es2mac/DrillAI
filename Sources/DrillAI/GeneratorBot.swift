//
//  GeneratorBot.swift
//
//
//  Created by Paul on 7/31/21.
//

import Foundation


public final class GeneratorBot<Evaluator: MCTSEvaluator> where Evaluator.State == GameState {
    public typealias State = GameState
    public typealias Action = Piece
    public typealias ActionVisits = MCTSTree<State>.ActionVisits
    typealias EvaluationInfo = [(id: ObjectIdentifier, state: GameState, nextActions: [GameState.Action])]
    typealias EvaluationResults = MCTSTree<GameState>.EvaluationResults

    private let tree: MCTSTree<State>
    private let evaluator: Evaluator

    // Task management
    private var thinkingTask: Task<Void, Never>?
    private var treeTask: Task<EvaluationInfo, Never>?
    private var evaluatorTask: Task<Void, Never>?
    private var queuedInfo: EvaluationInfo? = nil

    public init(initialState: State, evaluator: Evaluator) {
        self.tree = MCTSTree(initialState: initialState)
        self.evaluator = evaluator
    }

    /// On the tree side: try to keep one EvaluationInfo queued for evaluation
    /// On the evaluator sitde: if have queued EvaluationInfo, take it
    public func startThinking() {
        guard thinkingTask == nil else { return }
        // spin off first tree task
        addTreeTask()
        // spin off thinking loop
        thinkingTask = Task {
            await coordinateThinking()
        }
    }

    public func stopThinking() {
        thinkingTask?.cancel()
        treeTask?.cancel()
        evaluatorTask?.cancel()
        thinkingTask = nil
        treeTask = nil
        evaluatorTask = nil
        queuedInfo = nil
    }

    public func getActions() async -> [ActionVisits] {
        return await tree.getOrderedRootActions()
    }

    public func advance(with action: Action) async -> State {
        stopThinking()
        let newState = await tree.promoteRoot(action: action)
        return newState
    }

    private func addTreeTask() {
        treeTask = Task {
//            print("Tree picking")
            let info = await tree.getNextUnevaluatedStates(targetCount: 32)
//            print("Tree done picking")
            return info
        }
    }

    private func addEvaluatorTask(info: EvaluationInfo) {
        evaluatorTask = Task {
//            print("Start evaluation")
            let results = await evaluator.evaluate(info: info)
//            print("End evaluation")
            if !Task.isCancelled {
                await tree.updateWithEvaluationResults(results)
            }
//            print("Tree updated")
        }
    }

    private func coordinateThinking() async {
        while !Task.isCancelled {
            switch (treeTask, queuedInfo, evaluatorTask) {
            case (nil, nil, _):
//                print("Case 1: Tree is idle, add tree task")
                // Tree is idle & nothing queued for eval
                addTreeTask()

            case (_, .some(let info), nil):
//                print("Case 2: Evaluator is idle, add evaluator task")
                // Evaluator is idle
                addEvaluatorTask(info: info)
                queuedInfo = nil

            case (_, .some(_), .some(let evaluatorTask)):
//                print("Case 3: Has tree result, wait on evaluator")
                // Has tree result, but waiting on evaluator
                await evaluatorTask.value
                self.evaluatorTask = nil

            case (.some(let treeTask), nil, nil):
//                print("Case 4: Evaluator nothing to do, wait on tree")
                // Tree busy, evaluator idle but nothing to do
                let info = await treeTask.value
                if !Task.isCancelled {
                    queuedInfo = info
                }
                self.treeTask = nil

            case (.some(let treeTask), nil, .some(_)):
//                print("Case 5: Both busy, choose to wait for tree")
                // Both busy.  Here I have a choice of which one to wait on
                // (because I don't know an easy way to wait for either).
                // But in fact, since tree is an actor, and evaluation task
                // includes updating the tree at the end, the eval task
                // actually also waits on the tree task.
                let info = await treeTask.value
                if !Task.isCancelled {
                    queuedInfo = info
                }
                self.treeTask = nil
            }
        }
    }
}

