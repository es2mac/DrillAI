//
//  DrillModelEvaluator.swift
//
//
//  Created by Paul on 8/26/21.
//

import Foundation
import CoreML


public final class DrillModelEvaluator {

    let model: DrillModelCoreML

    init(modelURL url: URL?) throws {
        if let url = url {
            self.model = try DrillModelCoreML(contentsOf: url)
        } else {
            self.model = try DrillModelCoreML()
        }
    }
}


extension DrillModelEvaluator: MCTSEvaluator {
    public typealias State = GameState

    public func evaluate(info: MCTSTree<State>.StatesInfo) async -> MCTSTree.EvaluationResults {
        var results: MCTSTree.EvaluationResults = []

        for (id, state, nextActions) in info {
            results.append((id: id, value: Double(state.remainingGarbageCount), priors: [Double](repeating: 0, count: nextActions.count)))
        }

        return results
    }
}

extension DrillModelEvaluator {
    func evaluate(_ shapedArray: MLShapedArray<Float32>) -> DrillModelCoreMLOutput? {
        let x = try? model.prediction(input: shapedArray)
        return x
    }
}
