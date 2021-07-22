//
//  Field.swift
//  
//
//  Created by Paul on 7/5/21.
//

import Foundation

/// The game field is really just an array of rows.
/// It can be any number of rows tall.
struct Field {
    /// Each row is stored as bits in an Int16.
    /// By convention, empty top rows should be removed, no empty row.
    var storage: [Int16]
    var height: Int { return storage.count }
    var garbageCount: Int
}

extension Field {
    init() {
        self.storage = []
        self.garbageCount = 0
    }
}

extension Field: CustomDebugStringConvertible {
    public var debugDescription: String {
        var lines = storage.map { (n: Int16) -> String in
            let binaryString = String(n, radix: 2)
            let padding =  String(repeating: "0", count: (10 - binaryString.count))
            return padding + binaryString + "  "
        }
        if (garbageCount > 0) && (garbageCount <= lines.count) {
            lines[garbageCount - 1] = "==< " + lines[garbageCount - 1]
        }
        return String(lines.joined(separator: "\n").reversed())
            .replacingOccurrences(of: "0", with: "  ")
            .replacingOccurrences(of: "1", with: "O ")
    }
}

extension Field: Hashable {}
