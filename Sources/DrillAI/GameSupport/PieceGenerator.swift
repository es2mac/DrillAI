//
//  PieceGenerator.swift
//
//
//  Created by Paul on 7/23/21.
//

import Foundation
import GameplayKit


/*
 Ideally this is should not be placed under MCTS, but right now gameplay is tied up with the MCTSTree (the tree needs full information of the game, that is, the field and play piece sequence), and trial game runs are done with manual control flows.
 */
@available(macOSApplicationExtension 10.11, *)
class PieceGenerator {

    private let randomSource: GKRandomSource
    private var storage: [Tetromino] = []

    let seed: UInt64
    var offset = 0

    init() {
        let randomSource = GKMersenneTwisterRandomSource()
        self.randomSource = randomSource
        self.seed = randomSource.seed
    }

    init(seed: UInt64) {
        self.randomSource = GKMersenneTwisterRandomSource(seed: seed)
        self.seed = seed
    }

    subscript(index: Int) -> Tetromino {
        get {
            let internalIndex = index + offset
            while internalIndex >= storage.count {
                let bag = randomSource.arrayByShufflingObjects(in: Tetromino.allCases) as! [Tetromino]
                storage.append(contentsOf: bag)
            }
            return storage[internalIndex]
        }
    }
}

