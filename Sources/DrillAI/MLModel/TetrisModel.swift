//
//  TetrisModel.swift
//  
//
//  Created by Paul on 7/5/21.
//

import Foundation


/*
// This, ConvBN, ResidualBlock etc. modified from minigo
struct TetrisModel: Layer {

    var initialConv: ConvBN
    var residualBlocks: [ResidualBlock]

    var policyConv1: ConvBN
    var policyConv2: ConvBN

    var valueConv: ConvBN
    var valueDense1: Dense<Float>
    var valueDense2: Dense<Float>

    init(blockCount: Int = 4) {

        let inputFeatureCount = 36
        let convWidth = 32
        let valueDenseWidth = 32

        initialConv = ConvBN(filterShape: (3, 3, inputFeatureCount, convWidth))
        residualBlocks = (1...blockCount).map { _ in ResidualBlock(featureCount: convWidth) }

        policyConv1 = ConvBN(filterShape: (3, 3, convWidth, convWidth))
        policyConv2 = ConvBN(filterShape: (3, 3, convWidth, 8))

        valueConv = ConvBN(filterShape: (1, 1, convWidth, 1))
        valueDense1 = Dense<Float>(inputSize: 10 * 20, outputSize: valueDenseWidth, activation: relu)
        valueDense2 = Dense<Float>(inputSize: valueDenseWidth, outputSize: 1, activation: sigmoid)
    }

    @differentiable
    public func call(_ input: Tensor<Float>) -> TetrisModelOutput {

        let batchSize = input.shape[0]
        let initialOutput = relu(initialConv(input))
        let blocksOutput = residualBlocks.differentiableReduce(initialOutput) { last, layer in
            layer(last)
        }

        let logits = policyConv2(relu(policyConv1(blocksOutput)))
        let policyOutput = softmax(logits)

        let valueConvOutput = relu(valueConv(blocksOutput)).reshaped(to: [batchSize, 10 * 20])
        let valueOutput = valueDense2(valueDense1(valueConvOutput))

        return makeTetrisModelOutput(policy: policyOutput, value: valueOutput, logits: logits)
    }
}

*/
