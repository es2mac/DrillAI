//
//  DigEnvironment.swift
//
//
//  Created by Paul on 7/26/21.
//

import Foundation

final class DigEnvironment {

    let garbages: [Int16]
    let pieces: PieceGenerator

    let garbageSeed: UInt64
    let pieceSeed: UInt64

    init(garbageCount: Int, garbageSeed: UInt64? = nil, pieceSeed: UInt64? = nil) {
        // Garbages
        let garbageGenerator: GarbageGenerator
        if let seed = garbageSeed {
            garbageGenerator = GarbageGenerator(seed: seed)
        } else {
            garbageGenerator = GarbageGenerator()
        }
        self.garbages = (0 ..< garbageCount).map { garbageGenerator[$0] }
        self.garbageSeed = garbageGenerator.seed

        // Pieces
        if let seed = pieceSeed {
            self.pieces = PieceGenerator(seed: seed)
        } else {
            self.pieces = PieceGenerator()
        }
        self.pieceSeed = pieces.seed
    }
}
