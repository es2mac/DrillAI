import XCTest
@testable import DrillAI

final class FieldTests: XCTestCase {
    func testLockdownClearsLine() throws {
        // O
        // O O O O         X X
        // O O O O O O   O O X
        // O O O O O O O O O X
        // O O O O O O O O O
        // O O O O O O O O O
        let typical: [Int16] = [
            0b01111_11111,
            0b01111_11111,
            0b01111_11111,
            0b01101_11111,
            0b00000_01111,
            0b00000_00001,
        ]
        let afterLock: [Int16] = [
            0b01111_11111,
            0b01111_11111,
            0b11101_11111,
            0b11000_01111,
            0b00000_00001,
        ]

        let field1 = Field(storage: typical, garbageCount: 0)
        let field2 = Field(storage: afterLock, garbageCount: 0)

        let piece = Piece(type: .L, x: 9, y: 3, orientation: .left)
        let pieceTooLow = Piece(type: .L, x: 9, y: 2, orientation: .left)
        XCTAssertFalse(field1.canPlace(pieceTooLow))
        XCTAssertTrue(field1.canPlace(piece))

        let (newField, garbageCleared) = field1.lockDown(piece)
        XCTAssertEqual(newField, field2)
        XCTAssertEqual(garbageCleared, 0)
    }
}
