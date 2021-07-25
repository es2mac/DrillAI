//
//  PieceGenerator.swift
//
//
//  Created by Paul on 7/23/21.
//

import Foundation
import GameplayKit


/// The Tetris piece random generator can generate arbitrarily many pieces.
/// To access the pieces, subscript the generator directly.
/// The seed can be saved to recreate the same sequence next time.
public final class PieceGenerator {

    private let randomSource: GKMersenneTwisterRandomSource
    private var storage: [Tetromino] = []

    public let seed: UInt64

    public init() {
        self.randomSource = GKMersenneTwisterRandomSource()
        self.seed = randomSource.seed
    }

    public init(seed: UInt64) {
        self.randomSource = GKMersenneTwisterRandomSource(seed: seed)
        self.seed = seed
    }

    public subscript(index: Int) -> Tetromino {
        guard index >= 0 else {
            fatalError("Invalid index.")
        }
        while index >= storage.count {
            let bag = randomSource.arrayByShufflingObjects(in: Tetromino.allCases) as! [Tetromino]
            storage.append(contentsOf: bag)
        }
        return storage[index]
    }
}

