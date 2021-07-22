//
//  NotebookMethods.swift
//
//
//  Created by Paul on 7/23/21.
//

import Foundation


// Use matplotlib to draw the field

//func draw(_ field: Field) {
//  let filledBlocks = np.array(field.storage.map { number in
//    (0..<10).map { i in number & (1 << i) == 0 }
//  })
//
//  plt.figure(figsize: [5, 8])
//
//  let ax = plt.gca()
//  let im = ax.imshow(filledBlocks, cmap: "gray", vmin: -0.2, vmax: 1.2)
//
//  ax.set_xticks(np.arange(filledBlocks.shape[1]+1) - 0.5, minor: true)
//  ax.set_yticks(np.arange(filledBlocks.shape[0]+1) - 0.5, minor: true)
//  ax.grid(which: "minor", color: "w", linestyle: "-", linewidth: 3)
//  ax.invert_yaxis()
//
//  plt.show()
//}


/*
 Game data recording

 Saving raw data with numpy seems like a pretty clean way to go.

 For each generated move, save as training data:
 - game id (maybe use game start unix time)
 - move index
 - field
 - hold piece
 - play and (up to 5) preview pieces (to reconstruct model input)
 - garbage cleared count (to calculate value)
 - legal moves with visit counts (for policy labels), note each type has at most 34 simple placements.  Keeping 75 should be enough to account to the vast majority of situations, except in unnatural fields with a lot of twist/slide moves.
 */


//class GameRecorder {
//
//  static let fieldsCount = 1 + 1 + 20 + 1 + 6 + 1 + 75 * 2 // 180
//
//  var startTime = Date()
//  var moveId = 0
//
//  // Array of 1-D integer numpy arrays
//  var data = [PythonObject]()
//
//  init() {}
//
//  func setNewGame() {
//    startTime = Date()
//    moveId = 0
//  }
//}
//
//extension GameRecorder {
//  var numpyData: PythonObject {
//    return np.concatenate(data).reshape([-1, GameRecorder.fieldsCount])
//  }
//}
//
//
//extension GameRecorder{
//  func save(fileName: String) {
//    // Since data is mostly small integers, saving as text is
//    // smaller than Int64, plus it's human-readable
//    np.savetxt(fileName, numpyData, fmt: "%i")
//  }
//
//  func save() {
//    let formatter = DateFormatter()
//    formatter.dateFormat = "yyyy-MM-dd_HH-mm"
//    save(fileName: "GameRecords_" + formatter.string(from: Date()))
//  }
//}
//
//
//extension Array where Element: ExpressibleByIntegerLiteral {
//  func makeLength(_ length: Int) -> Array<Element> {
//    if count == length {
//      return self
//    } else if count > length {
//      return Array(self[0..<length])
//    } else {
//      return self + Array(repeating: 0, count: length - count)
//    }
//  }
//}
//
//extension GameRecorder {
//
//  func addPosition(field: Field,
//                   hold: Tetromino,
//                   play: [Tetromino],
//                   garbageCleared: Int,
//                   legalMoves: [Piece],
//                   childN: Tensor<Double>) {
//    var values = [Int]()
//    // Timestamp as ID
//    values.append(Int(startTime.timeIntervalSince1970))
//    // Move ID
//    values.append(moveId)
//    moveId += 1
//    // Field
//    values.append(contentsOf: field.storage.map(Int.init).makeLength(20))
//    // Hold
//    values.append(hold.rawValue)
//    // Play + up to 5 previews
//    values.append(contentsOf: play.map({ $0.rawValue }).makeLength(6))
//    // Garbage cleared count
//    values.append(garbageCleared)
//    // Up to 75 legal moves and their visit counts, sorted by count
//    let pairs = zip(legalMoves.map({ $0.hashValue }), childN.scalars.map(Int.init))
//    let sortedPairs = pairs.sorted { $0.1 > $1.1 }
//    let flattenSortedPairs = pairs.sorted(by: { $0.1 > $1.1 }).flatMap({ [$0.0, $0.1] })
//    values.append(contentsOf: flattenSortedPairs.makeLength(150))
//
//    let numpyArray = values.map(Int64.init).makeNumpyArray()
//    data.append(numpyArray)
//  }
//
//}
//
//extension GameRecorder {
//
//  func addPosition(tree: MCTSTree) {
//
//    addPosition(field: tree.root.field,
//                hold: tree.root.hold,
//                play: (0 ..< 6).map { tree.pieceSequence[$0] },
//                garbageCleared: tree.root.garbageCleared,
//                legalMoves: tree.root.legalMoves,
//                childN: tree.root.childN)
//  }
//
//}


/*
 Converting recorded data to training data

 The parse functions are very slow right now...
 */

///// Parse the one-dimensional numpy array representing one move
//func parseOneMoveData(_ numpyArray: PythonObject) -> (features: Tensor<Float>,
//                                                      logits: Tensor<Float>) {
//  guard let array = Array<Int64>(numpy: numpyArray)?.map(Int.init),
//    array.count == GameRecorder.fieldsCount else { fatalError() }
//
////   let gameId = array[0]
////   let moveId = array[1]
//  let storage = array[2...21].map(Int16.init).filter { $0 != 0 }
//  let field = Field.init(storage: storage, garbageCount: 0)
//  let hold = Tetromino(rawValue: array[22])!
//  let play = array[23...28].map { Tetromino(rawValue: $0)! }
//  // let garbageCleared = array[29]
//
//  var logits = Tensor<Float>(zeros: [10, 20, 8])
//  for moveIndex in stride(from: 30, to: GameRecorder.fieldsCount, by: 2) {
//    let pieceHash = array[moveIndex]
//    let visits = array[moveIndex + 1]
//    guard let move = Piece(hashValue: pieceHash) else { break } // e.g. hash = 0
//
//    let typeIndex = (move.type == play.first) ? 4 : 0
//    let pieceAndOrientation = typeIndex + move.orientation.rawValue
//
//    logits[move.x, move.y, pieceAndOrientation] = Tensor(Float(visits))
//  }
//
//  // Normalize
//  logits /= logits.sum()
//
//  let features = constructFeaturePlanes(field: field, hold: hold, play: play)
//
//  return (features: features, logits: logits)
//}
//
//
//func parseGameDataForTraining(_ numpyArray: PythonObject) -> (features: Tensor<Float>,
//                                                              logits: Tensor<Float>,
//                                                              values: Tensor<Float>) {
//
//  // The value of a position is defined as the average rate of garbage lines
//  // cleared per move afterwards.  The rate is calculated as clears/moves for
//  // the next # moves (# defined below), or to the end of the game.
//  // Value range: between 0 and 1
//  let maxAveragingMoves = 14
//
//  // np.unique returns [unique, unique_indices, unique_counts]
//  let uniqueGameIds = np.unique(numpyArray[0..., 0], return_index: true, return_counts: true)
//  let garbageCleardCounts = Array<Float>(numpyArray[0..., 29])!
//
//  // Pre-construct the big tensors.  Last move of each game is left out because
//  // value cannot be given when there's no future move.
//  let finalCount = Int(numpyArray.shape[0] - uniqueGameIds[0].shape[0])!
//  var allFeatures = Tensor<Float>(zeros: [finalCount, 10, 20, 36])
//  var allLogits = Tensor<Float>(zeros: [finalCount, 10, 20, 8])
//  var values = Array<Float>()
//
//  // Process each game
//  var gamesProcessed = 0
//  var movesProcessed = 0
//
//  for (startIndex, count) in zip(uniqueGameIds[1], uniqueGameIds[2]) {
//    let lastIndex = Int(startIndex + count - 1)!
//
//    // Process each move, notice below that index stops before lastIndex
//    for index in (Int(startIndex)! ..< lastIndex) {
//      // Features and logits
//      let (features, logits) = parseOneMoveData(numpyArray[index])
//      allFeatures[index - gamesProcessed] = features
//      allLogits[index - gamesProcessed] = logits
//
//      // Values
//      let checkGarbageIndex = min(index + maxAveragingMoves, lastIndex)
//      let moveCount = checkGarbageIndex - index
//      let garbageCleared = garbageCleardCounts[checkGarbageIndex] - garbageCleardCounts[index]
//      values.append(garbageCleared / Float(moveCount))
//
//      // Display
//      movesProcessed += 1
//      if movesProcessed % 1000 == 0 {
//        print("Parsed count: \(movesProcessed)")
//      }
//    }
//
//    gamesProcessed += 1
//  }
//
//  return (features: allFeatures, logits: allLogits, values: Tensor(values))
//}
