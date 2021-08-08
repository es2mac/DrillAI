//
//  GeneratorBot.swift
//
//
//  Created by Paul on 7/31/21.
//

import Foundation


private let batchSize = 32


public final class GeneratorBot<Evaluator: MCTSEvaluator> where Evaluator.State == GameState {
    public typealias State = GameState
    public typealias Action = Piece
    public typealias ActionVisits = MCTSTree<State>.ActionVisits
    typealias EvaluationInfo = [(id: ObjectIdentifier, state: GameState, nextActions: [Action])]

    public var autoStopAction: (() -> Void)?

    private let tree: MCTSTree<State>
    private let evaluator: Evaluator

    // Task management
    private var thinkingTask: Task<Void, Never>?
    private var treeTask: Task<EvaluationInfo, Never>?
    private var evaluatorTask: Task<Void, Never>?

    public init(initialState: State, evaluator: Evaluator) {
        self.tree = MCTSTree(initialState: initialState)
        self.evaluator = evaluator
    }

    deinit { stopThinking() }
}


public extension GeneratorBot {
    var isThinking: Bool {
        if let task = thinkingTask, !task.isCancelled {
            return true
        } else {
            return false
        }
    }

    func startThinking() {
        guard thinkingTask == nil else { return }
        thinkingTask = Task {
            await coordinateThinking()
        }
    }

    func stopThinking() {
        thinkingTask?.cancel()
        treeTask?.cancel()
        evaluatorTask?.cancel()
        thinkingTask = nil
        treeTask = nil
        evaluatorTask = nil
    }

    func getActions() async -> [ActionVisits] {
        return await tree.getOrderedRootActions()
    }

    func advance(with action: Action) async -> State {
        stopThinking()
        let newState = await tree.promoteRoot(action: action)
        return newState
    }
}

private extension GeneratorBot {
    func coordinateThinking() async {
        while !Task.isCancelled {
            switch (treeTask, evaluatorTask) {
            case (nil, _):
                // Tree is idle & nothing waiting for eval
                addTreeTask()

            case (.some(let treeTask), nil):
                // Evaluator is idle, tree working or maybe done waiting with stuff to evaluate
                let info = await treeTask.value
                self.treeTask = nil
                guard info.count > 0 else {
                    stopThinking()
                    autoStopAction?()
                    return
                }
                guard !Task.isCancelled else {
                    return
                }
                addEvaluatorTask(info: info)

            case (.some(_), .some(let evaluatorTask)):
                // Both working away, need the evaluator checked off first to offload tree results
                await evaluatorTask.value
                self.evaluatorTask = nil
            }
        }
    }

    func addTreeTask() {
        treeTask = Task {
            await tree.getNextUnevaluatedStates(targetCount: batchSize)
        }
    }

    func addEvaluatorTask(info: EvaluationInfo) {
        evaluatorTask = Task {
            let results = await evaluator.evaluate(info: info)
            if !Task.isCancelled {
                await tree.updateWithEvaluationResults(results)
            }
        }
    }
}

