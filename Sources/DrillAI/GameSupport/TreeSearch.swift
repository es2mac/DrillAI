//
//  TreeSearch.swift
//
//
//  Created by Paul on 7/23/21.
//

import Foundation

//
//// Sequential search
//
//extension MCTSTree {
//
//  func performSearch(times: Int = 1000) {
//    for iteration in 1 ... times {
//
////       if iteration % 1000 == 0 {
////         print("Iteration \(iteration)")
////       }
//
//      // Selection & expansion
//      let node = selectBestUnevaluatedNode()
//      let depth = node.step - root.step
//
//      // Evaluation & backpropagation
//      node.setupChildren(playPieceType: pieceSequence[depth])
//
//      let (value, priors) = bctsEvaluate(node, depth: depth)
////       let (value, priors) = modelEvaluate(model: model,
////                                     field: node.field,
////                                     legalMoves: node.legalMoves,
////                                     hold: .I,
////                                     play: (0...5).map { pieceSequence[$0] })
//
//      node.priors = priors
//      backPropagate(from: node, value: value)
//    }
//  }
//}
//
//
//// Parallel search
//
//extension MCTSTree {
//
//  func makeInputTensor(nodes: [MCTSNode]) -> Tensor<Float> {
//    let tensors = nodes.map { node -> Tensor<Float> in
//      let depth = node.step - root.step
//      return constructFeaturePlanes(field: node.field,
//                                    hold: node.hold,
//                                    play: (0...5).map { pieceSequence[$0 + depth]})
//    }
//    let result = tensors.reduce(Tensor<Float>(zeros: [0, 10, 20, 36])) {
//      $0.concatenated(with: $1.rankLifted())
//    }
//    return result
//  }
//
//  func parseModelPolicy(policyOutput: Tensor<Float>,
//                        legalMoves: [Piece],
//                        play: Tetromino) -> Tensor<Double> {
//
//    let priorsArray = legalMoves.map { move -> Double in
//      guard move.y < 20 else { return 0 }
//      let typeIndex = (move.type == play) ? 4 : 0
//      let pieceAndOrientation = typeIndex + move.orientation.rawValue
//      let tensorValue = policyOutput[move.x, move.y, pieceAndOrientation]
//      return Double(tensorValue.scalarized())
//    }
//
//    return Tensor(priorsArray)
//  }
//
//  func performParallelSearch(maxBatchSize: Int = 1) {
//
//    var nodeVisits = [MCTSNode : Int]()
//
//    // Gather a batch of nodes by selecting maxBatchSize times
//    for _ in 0 ..< maxBatchSize {
//      let node = selectBestUnevaluatedNode()
//      let depth = node.step - root.step
//
//      // Add virtual loss
//      backPropagate(from: node, value: -1)
//
//      // Book keeping
//      nodeVisits[node, default: 0] += 1
//    }
//
//    // Evaluate batch
//    let nodes = Array(nodeVisits.keys) // Use this for ordering to match input/output
//    let input: Tensor<Float> = makeInputTensor(nodes: nodes)
//    let output: TetrisModelOutput = model(input)
//    let values = output.value.scalars.map(Double.init)
//
//    // Update tree
//    for (index, node) in nodes.enumerated() {
//
//      // Setup children
//      let depth = node.step - root.step
//      let playPieceType = pieceSequence[depth]
//      node.setupChildren(playPieceType: playPieceType)
//
//      // Save priors, re-normalize here
//      let priors = parseModelPolicy(policyOutput: output.policy[index],
//                                    legalMoves: node.legalMoves,
//                                    play: playPieceType)
//      node.priors = priors / priors.sum()
//
//      // Integrate future efficiency estimate (model's value) with past efficiency
//      // (observed in the search so far), assuming the future efficiency is
//      // average over (14) steps
//      let integratedStepsCount = depth + 14
//      let integratedClears = values[index] * 14 + Double(node.garbageCleared - root.garbageCleared)
//      let integratedValue = integratedClears / Double(integratedStepsCount)
//
////       data1.append(Double(integratedStepsCount))
////       data2.append(integratedClears)
////       data3.append(integratedValue)
//
//      // Propagate value, and reverse virtual loss (= visits count)
//      let visits = Double(nodeVisits[node]!)
//      backPropagate(from: node, value: integratedValue + visits, visits: 1 - visits)
//    }
//
//  }
//
//}
//
//
//extension MCTSTree {
//
//  func promoteToRoot(node: MCTSNode) {
//    assert(node.parent == root)
//    root = node
//    pieceSequence.offset += 1
//    garbages.offset += 1
//  }
//
//  func promoteBestChildToRoot() {
//    guard let bestChild = root.getMostVisitedChild() else {
//      assertionFailure("Root node has no children.")
//      return
//    }
//    promoteToRoot(node: bestChild)
//  }
//
//}
//
