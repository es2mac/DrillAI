//
//  FeaturePlane.swift
//  
//
//  Created by Paul on 7/5/21.
//

import Foundation

/// Value function wrapper

/*

/// Make model input with the field and play pieces.
/// Note that here the "play" pieces include the current play piece,
/// plus the previews.  It could be empty, and will use up to 3 previews.
/// The resulting tensor has 36 features, and indexed as (x, y, feature#)
/// for a shape of (10, 20, 36)
func constructFeaturePlanes(field: Field, hold: Tetromino, play: [Tetromino]) -> Tensor<Float> {

    // Work with (feature#, y, x) and transpose at the end
    var planes = Tensor<Float>.init(shape: [36, 20, 10], repeating: 0)

    // Plane 0: Actual field, up to 20 lines
    var flattenField = [Float](repeating: 0, count: 200)
    for (y, line) in zip(0..<20, field.storage) {
        for x in 0 ..< 10 {
            if line & (1 << x) != 0 {
                flattenField[x + y * 10] = 1
            }
        }
    }

    planes[0] = Tensor(flattenField).reshaped(to: [20, 10])

    // Each play piece fills one of 7 planes
    let filled = Tensor<Float>.init(ones: [20, 10])

    // Planes 1~7: Hold
    planes[1 + hold.rawValue] = filled

    // Planes 8-36: Play (current and up to 3 previews)
    for (nextIndex, type) in zip(0..<4, play) {
        planes[8 + 7 * nextIndex + type.rawValue] = filled
    }

    //       var start = Date()
    //       data2.append(Date().timeIntervalSince(start))
    //       start = Date()
    //       data3.append(Date().timeIntervalSince(start))

    return planes.transposed()
}

*/

/*

// Prototype: For sequential evaluations only
func modelEvaluate(model: TetrisModel,
                   field: Field,
                   legalMoves: [Piece],
                   hold: Tetromino,
                   play: [Tetromino]) -> (value: Double, priors: Tensor<Double>) {

    let input = constructFeaturePlanes(field: field, hold: hold, play: play)
    let output = model(input.rankLifted())
    let valueOutput = Double(output.value.scalarized())
    let policyOutput = output.policy[0] // shape = (10, 20, 8)

    let priorsArray = legalMoves.map { move -> Double in
        guard move.y < 20 else { return 0 }
        let typeIndex = (move.type == play.first) ? 4 : 0
        let pieceAndOrientation = typeIndex + move.orientation.rawValue
        let tensorValue = policyOutput[move.x, move.y, pieceAndOrientation]
        return Double(tensorValue.scalarized())
    }

    var priors = Tensor(priorsArray)
    priors = priors / priors.sum()  // Normalize again

    return (value: valueOutput, priors: priors)
}

 */
