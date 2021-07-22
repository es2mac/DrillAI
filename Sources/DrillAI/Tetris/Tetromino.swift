//
//  Tetromino.swift
//  
//
//  Created by Paul on 7/5/21.
//

import Foundation

/// Seven type of tetromino.
enum Tetromino: Int, CaseIterable {
    case I, J, L, O, S, T, Z  // In alphabetical order
}

public func < <T: RawRepresentable>(a: T, b: T) -> Bool where T.RawValue: Comparable {
    return a.rawValue < b.rawValue
}

extension Tetromino: Comparable {}

extension Tetromino: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .I: return "I"
        case .J: return "J"
        case .L: return "L"
        case .O: return "O"
        case .S: return "S"
        case .T: return "T"
        case .Z: return "Z"
        }
    }
}
