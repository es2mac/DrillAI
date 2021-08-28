//
//  DrillModelEvaluator.swift
//
//
//  Created by Paul on 8/26/21.
//

import Foundation
import CoreML
import Accelerate


public final class DrillModelEvaluator {

    let model: DrillModelCoreML

    public init(modelURL url: URL? = nil) throws {
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
        let inputs = info.map(\.state).map(encode(state:)).map(DrillModelCoreMLInput.init)
        let outputs = try! model.predictions(inputs: inputs)

        return zip(info, outputs).map { item, output in
            (id: item.id,
             value: calculateValue(modelValue: output.var_205[0].doubleValue,
                                   state: item.state),
             priors: calculatePriors(logits: output.var_186,
                                     playPieceType: item.state.playPieceType,
                                     actions: item.nextActions))
        }
    }
}


extension DrillModelEvaluator {
    func encode(state: GameState) -> MLShapedArray<Float> {
        var shapedArray = MLShapedArray<Float>(repeating: 0, shape: [1, 43, 20, 10])

        // Field
        let field = state.field
        let fieldCells: [Float] = field.storage.flatMap { row in
            (0 ..< 10).map { i in
                row & (1 << i) == 0 ? 0 : 1
            }
        }
        shapedArray[0][0][0..<field.height].fill(with: fieldCells)

        // Play pieces
        let playPieceType = state.playPieceType
        let tetrominos = [playPieceType] +
                          (state.hold.map { [$0] } ?? []) +
                          state.nextPieceTypes

        for (index, type) in tetrominos.enumerated().prefix(6) {
            shapedArray[0][1 + index * 7 + type.rawValue].fill(with: 1)
        }

        return shapedArray
    }

    /// Value is calculated as the efficiency from past + future.
    /// Future efficiency is an estimate converted from the ML model output,
    /// i.e. modelValue (as an efficiency of clears per piece, for either 14
    /// drops or till the end of that game).
    func calculateValue(modelValue: Double, state: GameState) -> Double {
        let pastCount = Double(state.dropCount - state.referenceStep)
        let pastClears = Double(state.garbageCleared - state.referenceGarbageCleared)
        let futureClears = min(14 * modelValue, Double(state.garbageRemaining))
        let futureCount = futureClears / modelValue
        let value = (pastClears + futureClears) / (pastCount + futureCount)

        // As of the first iteration, value is around 0.1 ~ 0.4
        // Try take 0 ~ 0.5 to -1 ~ 1
        let scaledValue = max(0, min(2, value * 4)) - 1

        return scaledValue
    }

    func calculatePriors(logits: MLMultiArray,
                         playPieceType: Tetromino,
                         actions: [Piece]) -> [Double] {
        // Logits are shaped (1, 8, 20, 10)
        // First select the logit values
        var values: [Float] = actions.map { piece in
            let playPieceOffset = piece.type == playPieceType ? 0 : 800
            let orientationOffset = 200 * piece.orientation.rawValue
            return logits[playPieceOffset + orientationOffset + 10 * piece.y + piece.x].floatValue
        }

        // Softmax.  Reference hollance/CoreMLHelpers/CoreMLHelpers/Math.swift
        let maximum = vDSP.maximum(values)
        vDSP.add(-maximum, values, result: &values)

        // Ad-hoc tweak:  Prior values are too extreme, smooth them out
        let minimum = min(-0.25, vDSP.minimum(values))
        vDSP.divide(values, -0.25 * minimum, result: &values)

        // The rest is the usual
        vForce.exp(values, result: &values)
        let valueSum = vDSP.sum(values)
        vDSP.divide(values, valueSum, result: &values)

        return values.map(Double.init)
    }
}
