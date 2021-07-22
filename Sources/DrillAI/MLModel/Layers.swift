//
//  Layers.swift
//  
//
//  Created by Paul on 7/5/21.
//

import Foundation

/*
struct ConvBN: Layer {
    var conv: Conv2D<Float>
    var norm: BatchNorm<Float>

    init(filterShape: (Int, Int, Int, Int), strides: (Int, Int) = (1, 1), padding: Padding = .same) {
        self.conv = Conv2D(filterShape: filterShape, strides: strides, padding: padding)
        self.norm = BatchNorm(featureCount: filterShape.3)
    }

    @differentiable
    func call(_ input: Tensor<Float>) -> Tensor<Float> {
        return input.sequenced(through: conv, norm)
    }
}

struct ResidualBlock: Layer {
    var layer1: ConvBN
    var layer2: ConvBN

    init(featureCount: Int, kernelSize: Int = 3) {
        self.layer1 = ConvBN(filterShape: (kernelSize, kernelSize, featureCount, featureCount))
        self.layer2 = ConvBN(filterShape: (kernelSize, kernelSize, featureCount, featureCount))
    }

    @differentiable
    func call(_ input: Tensor<Float>) -> Tensor<Float> {
        let layersOutput = layer2(relu(layer1(input)))
        return relu(layersOutput + input)
    }
}

/// Policy is softmax'd logits, shaped (10, 20, 8), i.e. (x, y, piece+orientation)
/// Last dimension (8) consists of the 4 orientations of the hold piece,
/// and then 4 for the play piece
struct TetrisModelOutput: Differentiable {
    let policy: Tensor<Float>
    let value: Tensor<Float>
    let logits: Tensor<Float>
}

// Modified from Transformer model, wrapping struct init in a differentiable function
// These look boilerplate-ish, and I do not understand them.
@differentiable(wrt: (policy, value, logits), vjp: _vjpMakeTetrisModelOutput)
func makeTetrisModelOutput(policy: Tensor<Float>, value: Tensor<Float>, logits: Tensor<Float>) -> TetrisModelOutput {
    return TetrisModelOutput(policy: policy, value: value, logits: logits)
}

func _vjpMakeTetrisModelOutput(policy: Tensor<Float>, value: Tensor<Float>, logits: Tensor<Float>)
-> (TetrisModelOutput, (TetrisModelOutput.CotangentVector) -> (Tensor<Float>, Tensor<Float>, Tensor<Float>)) {
    let result = TetrisModelOutput(policy: policy, value: value, logits: logits)
    return (result, { seed in (seed.policy, seed.value, seed.logits) })
}


// Copied from CIFAR helper, because control flow (e.g. looping) is not yet differentiable
extension Array where Element: Differentiable {
    @differentiable(wrt: (self, initialResult), vjp: reduceDerivative)
    func differentiableReduce<Result: Differentiable>(
        _ initialResult: Result,
        _ nextPartialResult: @differentiable (Result, Element) -> Result
    ) -> Result {
        return reduce(initialResult, nextPartialResult)
    }

    func reduceDerivative<Result: Differentiable>(
        _ initialResult: Result,
        _ nextPartialResult: @differentiable (Result, Element) -> Result
    ) -> (Result, (Result.CotangentVector) -> (Array.CotangentVector, Result.CotangentVector)) {
        var pullbacks: [(Result.CotangentVector)
                        -> (Result.CotangentVector, Element.CotangentVector)] = []
        let count = self.count
        pullbacks.reserveCapacity(count)
        var result = initialResult
        for element in self {
            let (y, pb) = Swift.valueWithPullback(at: result, element, in: nextPartialResult)
            result = y
            pullbacks.append(pb)
        }
        return (value: result, pullback: { cotangent in
            var resultCotangent = cotangent
            var elementCotangents = CotangentVector([])
            elementCotangents.base.reserveCapacity(count)
            for pullback in pullbacks.reversed() {
                let (newResultCotangent, elementCotangent) = pullback(resultCotangent)
                resultCotangent = newResultCotangent
                elementCotangents.base.append(elementCotangent)
            }
            return (CotangentVector(elementCotangents.base.reversed()), resultCotangent)
        })
    }
}

 */

