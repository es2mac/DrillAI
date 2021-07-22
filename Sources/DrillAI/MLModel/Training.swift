//
//  Training.swift
//
//
//  Created by Paul on 7/23/21.
//

import Foundation


//let filenames = ["BCTS_2019-05-30_09-39.dms",
//                 "BCTS_2019-05-30_14-46.dms",
//                 "BCTS_2019-05-31_09-39.dms",
//                 "BCTS_2019-05-31_14-34.dms"]
//
//let rawData = np.concatenate(filenames.map { np.loadtxt($0, dtype: "int64") })
//
//print(rawData.shape)

//let (features, logits, values) = parseGameDataForTraining(rawData)


//let batchSize = 128
//
//// Note that the batch selection should probably be randomized
//// using the S4TF Dataset API instead
//func minibatch<Scalar>(in x: Tensor<Scalar>, at index: Int) -> Tensor<Scalar> {
//    let start = index * batchSize
//    return x[start..<start+batchSize]
//}


// var model = TetrisModel()
// let optimizer = SGD(for: model)

//// Test training
//
//let epochCount = 5
//// var policyLosses = [Float]() // Record per batch
//// var valueLosses = [Float]()
//// var accuracies = [Float]()
//
//// Epochs
//for epoch in 1 ... epochCount {
//
//  var totalLoss: Float = 0
//
//  // Batches
//  let batchCount = features.shape[0] / batchSize
//  for batchIndex in 0 ..< batchCount {
//    let (loss, gradients) = valueWithGradient(at: model) { model -> Tensor<Float> in
//      let input = minibatch(in: features, at: batchIndex)
//
//      var policyLabels = minibatch(in: logits, at: batchIndex)
//      policyLabels = policyLabels.reshaped(to: [batchSize, -1])
//
//      let valueLabels = minibatch(in: values, at: batchIndex)
//
//      let output = model(input)
//      let outputLogits = output.logits.reshaped(to: [batchSize, -1])
//
//      let policyLoss = softmaxCrossEntropy(logits: outputLogits,
//                                           probabilities: policyLabels)
//      let valueLoss = meanSquaredError(predicted: output.value, expected: valueLabels)
//
//      policyLosses.append(policyLoss.scalarized())
//      valueLosses.append(valueLoss.scalarized())
//
//      let predictions = outputLogits.argmax(squeezingAxis: 1)
//      let truths = policyLabels.argmax(squeezingAxis: 1)
//      let accuracy = Tensor<Float>(predictions .== truths).mean().scalarized()
//      accuracies.append(accuracy)
//
//      // May need: weight policy & value loss differently in their sum
//      // May need: regularization cost (combination of L2 of all trainable vars)
//      // This might not be so simple because this cost closure needs to be differentiable
//
////       let testFilters = model.initialConv.conv.filter
////       let regularizationLoss = (testFilters * testFilters).sum() * 1e-4
////       print(policyLoss, valueLoss, regularizationLoss)
//
////       return policyLoss + valueLoss + regularizationLoss
//      return policyLoss + valueLoss
//    }
//
//    optimizer.update(&model.allDifferentiableVariables, along: gradients)
//
//    totalLoss += loss.scalarized()
//  }
//
//  print("Average loss:", totalLoss / Float(batchCount))
//
//}


//plt.figure(figsize: [12, 12])
//
//let policyLossAxes = plt.subplot(3, 1, 1)
//policyLossAxes.set_ylabel("Policy Loss")
//policyLossAxes.set_xlabel("Epoch")
//policyLossAxes.plot(policyLosses)
//
//let valueLossAxes = plt.subplot(3, 1, 2)
//valueLossAxes.set_ylabel("Value Loss")
//valueLossAxes.set_xlabel("Epoch")
//valueLossAxes.plot(valueLosses)
//
//let accuracyAxes = plt.subplot(3, 1, 3)
//accuracyAxes.set_ylabel("Accuracies")
//accuracyAxes.set_xlabel("Epoch")
//accuracyAxes.plot(accuracies)
//
//plt.show()



//// Use holdout data for validation
//
//let testData = np.loadtxt("BCTS_2019-05-30_20-49.dms", dtype: "int64")
//let (testFeatures, testLogits, _) = parseGameDataForTraining(testData)
//let testOutput = model(testFeatures)
//
//let testTruths = testLogits.reshaped(to: [testOutput.logits.shape[0], -1]).argmax(squeezingAxis: 1)
//let testPredictions = testOutput.logits.reshaped(to: [testOutput.logits.shape[0], -1]).argmax(squeezingAxis: 1)
//let testAccuracy = Tensor<Float>(testPredictions .== testTruths).mean().scalarized()
//print("Testing policy output accuracy: \(testAccuracy)")


