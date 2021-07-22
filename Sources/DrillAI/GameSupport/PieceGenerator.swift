//
//  PieceGenerator.swift
//
//
//  Created by Paul on 7/23/21.
//

import Foundation

/*
 Ideally this is should not be placed under MCTS, but right now gameplay is tied up with the MCTSTree (the tree needs full information of the game, that is, the field and play piece sequence), and trial game runs are done with manual control flows.
 */
class PieceGenerator {
  private var storage: [Tetromino] = []

  var offset = 0

  init() {}

  subscript(index: Int) -> Tetromino {
    get {
      let internalIndex = index + offset
      while internalIndex >= storage.count {
        storage.append(contentsOf: Tetromino.allCases.shuffled())
      }
      return storage[internalIndex]
    }
  }
}

