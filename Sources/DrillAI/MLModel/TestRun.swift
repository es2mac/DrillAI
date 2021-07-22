//
//  TestRun.swift
//
//
//  Created by Paul on 7/23/21.
//

import Foundation

/*
 Field test
 */

//let typical: [Int16] = [
//  0b01111_11111,
//  0b01111_11111,
//  0b01111_11111,
//  0b01101_11111,
//  0b00000_01111,
//  0b00000_00001,
//]
//
//var field = Field(storage: typical, garbageCount: 0)
//
//print(field)
//draw(field)


//let piece = Piece(type: .L, x: 9, y: 3, orientation: .left)
//print(field.canPlace(piece))
//let (newField, garbageCleared) = field.lockDown(piece)
//print(newField)
//print("cleared garbage lines:", garbageCleared)


/*
 Play a game
 */

//let thinkTime: TimeInterval = 3.0
//
//func playOneGame(model: TetrisModel, verbose: Bool = false, recorder: GameRecorder? = nil) {
//  // Initiate game
//  let tree = MCTSTree(model: model)
//
//  // Custom game...
////   let pieceSequence = PieceGenerator()
////   let garbages = GarbageGenerator()
////   let field = Field.init(storage: (0 ..< 6).map { garbages[$0] },
////                            garbageCount: 6)
////   let tree = MCTSTree(field: field, pieceSequence: pieceSequence, garbages: garbages, model: model)
//
//  recorder?.setNewGame()
//
//  // Make move repeatedly till game over
//  playGame: for move in 1... {
//
//    if verbose {
//      print("*** Move \(move): ***")
//      print("Play: \(tree.pieceSequence[0]), hold: \(tree.root.hold)")
//    }
//
//    let startTime = Date()
//
//    // Tree search: serial using BCTS, or parallel using model
//    tree.performSearch(times: 3000)
////     while Date().timeIntervalSince(startTime) < thinkTime {
////       tree.performParallelSearch(maxBatchSize: 32)
////     }
//
//    // Move selection: Best, or probabilistic?
////     let bestChild = tree.root.getMostVisitedChild() ?? tree.root
//    let bestChild = tree.root.getChildWithWeightedProbability() ?? tree.root
//
//    // Display results
//    print("Move \(move), search count: \(tree.root.childN.sum()), max depth: \(tree.getMostTraveledPath().count), garbage cleared: \(bestChild.garbageCleared)")
//    if verbose {
//      tree.printMove(childNode: bestChild)
//      print()
//    }
//
//    // Record results
//    recorder?.addPosition(tree: tree)
//
//    // Game finished?
//    if bestChild.field.garbageCount == 0 {
//      print("Garbage cleared!")
//      break playGame
//    }
//
//    if bestChild.field.height >= 20 {
//      print("Game over...")
//      break playGame
//    }
//
//    // Prepare for the next move
//    tree.promoteToRoot(node: bestChild)
//  }
//
//}



/*
 Play session: Main loop
 */

// Be careful with re-initializing recorder in notebook, will lose past data
// let recorder = GameRecorder()

// Go train a model below, and come back here
// Or use a completely random one...
// let model = TetrisModel()

//for _ in 0 ..< 1 {
//
//  // Run games
//  let sessionStartTime = Date()
//  let sessionTime: TimeInterval = 15 * 60
//
//  for game in 1...1 {
//
//    let elapsed = Date().timeIntervalSince(sessionStartTime)
//    print("Session elapsed: \(elapsed / 60) minutes")
//
//    if elapsed >= sessionTime {
//      print("Session done.  Bye!")
//      break
//    }
//
//    playOneGame(model: model, verbose: true)
////     playOneGame(model: model, verbose: false, recorder: recorder)
////     print("Recoder has \(recorder.data.count) entries.")
//
//    print()
//
//  }
//
////   recorder.save()
//}
//

