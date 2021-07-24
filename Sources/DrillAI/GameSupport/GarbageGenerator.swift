//
//  GarbageGenerator.swift
//
//
//  Created by Paul on 7/23/21.
//

import Foundation
import GameplayKit


@available(macOSApplicationExtension 10.11, *)
public final class GarbageGenerator {

    private let randomSource: GKMersenneTwisterRandomSource
    private var holePositions: [Int]

    public let seed: UInt64

    public init() {
        let randomSource = GKMersenneTwisterRandomSource()
        self.randomSource = randomSource
        self.holePositions = [randomSource.nextInt(upperBound: 10)]
        self.seed = randomSource.seed
    }

    public init(seed: UInt64) {
        let randomSource = GKMersenneTwisterRandomSource(seed: seed)
        self.randomSource = randomSource
        self.holePositions = [randomSource.nextInt(upperBound: 10)]
        self.seed = seed
    }

    subscript(index: Int) -> Int16 {
        while index >= holePositions.count {
            let lastHolePosition = holePositions.last!
            let increment = 1 + randomSource.nextInt(upperBound: 9)
            holePositions.append((lastHolePosition + increment) % 10)
        }
        return 0b11111_11111 ^ (1 << holePositions[index])
    }
}
