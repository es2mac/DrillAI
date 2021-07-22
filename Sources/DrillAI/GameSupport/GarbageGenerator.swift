//
//  GarbageGenerator.swift
//
//
//  Created by Paul on 7/23/21.
//

import Foundation


class GarbageGenerator {
  private var holePositions: [Int] = [Int.random(in: 0..<10)]

  var offset = 0

  init() {}

  subscript(index: Int) -> Int16 {
    get {
      let internalIndex = index + offset
      while internalIndex >= holePositions.count {
        let lastHolePosition = holePositions.last!
        holePositions.append((lastHolePosition + Int.random(in: 1..<10)) % 10)
      }
      return 0b11111_11111 ^ (1 << holePositions[internalIndex])
    }
  }
}
