import XCTest
@testable import DrillAI

final class FieldTests: XCTestCase {

    func testCreateFieldWithBothGarbageAndNonGarbage() throws {
        let garbages: [Int16] = (0..<10)
            .map { 0b11111_11111 ^ 1 << $0 }
            .shuffled()
        let nonGarbages: [Int16] = [0b00011_11111]
        let field = Field(storage: garbages + nonGarbages,
                          garbageCount: garbages.count)
        XCTAssertEqual(field.garbageCount, 10)
        XCTAssertEqual(field.height, 11)
    }

    func testCanPlacePieceIsTrue() throws {
        // O
        // O O O O
        // O O O O O O   O O
        // O O O O O O O O O
        // O O O O O O O O O
        let storage: [Int16] = [
            0b01111_11111,
            0b01111_11111,
            0b01101_11111,
            0b00000_01111,
            0b00000_00001,
        ]
        let field = Field(storage: storage)
        let piece1 = Piece(type: .T, x: 6, y: 3, orientation: .down)
        let piece2 = Piece(type: .L, x: 9, y: 2, orientation: .left)
        XCTAssertTrue(field.canPlace(piece1))
        XCTAssertTrue(field.canPlace(piece2))
    }

    func testCanNotPlacePiece() throws {
        // O
        // O O O O
        // O O O O O O   O O
        // O O O O O O O O O
        // O O O O O O O O O
        let storage: [Int16] = [
            0b01111_11111,
            0b01111_11111,
            0b01101_11111,
            0b00000_01111,
            0b00000_00001,
        ]
        let field = Field(storage: storage)
        let piece1 = Piece(type: .T, x: 6, y: 2, orientation: .down)
        let piece2 = Piece(type: .L, x: 9, y: 1, orientation: .left)
        XCTAssertFalse(field.canPlace(piece1))
        XCTAssertFalse(field.canPlace(piece2))
    }

    func testLockdownClearsLine() throws {
        // O
        // O O O O         X X
        // O O O O O O   O O X
        // O O O O O O O O O X
        // O O O O O O O O O
        // O O O O O O O O O
        let storage: [Int16] = [
            0b01111_11111,
            0b01111_11111,
            0b01111_11111,
            0b01101_11111,
            0b00000_01111,
            0b00000_00001,
        ]
        let afterStorage: [Int16] = [
            0b01111_11111,
            0b01111_11111,
            0b11101_11111,
            0b11000_01111,
            0b00000_00001,
        ]

        let field = Field(storage: storage, garbageCount: 0)
        let fieldAfter = Field(storage: afterStorage, garbageCount: 0)

        let piece = Piece(type: .L, x: 9, y: 3, orientation: .left)
        XCTAssertTrue(field.canPlace(piece))

        let (newField, garbageCleared) = field.lockDown(piece)
        XCTAssertEqual(newField, fieldAfter)
        XCTAssertEqual(garbageCleared, 0)
        XCTAssertEqual(newField.height, field.height - 1)
    }

    func testFindingSimplePlacementsForEveryType() throws {
        let storage: [Int16] = [
            0b01111_11111,
            0b01111_11111,
            0b01101_11111,
            0b00000_01111,
            0b00000_00001,
        ]
        let field = Field(storage: storage)
        for type in Tetromino.allCases {
            let count = Set(field.findAllPlacements(for: [type])).count
            switch type {
            case .I:
                XCTAssertEqual(count, 17)
            case .J:
                XCTAssertEqual(count, 34)
            case .L:
                XCTAssertEqual(count, 34)
            case .O:
                XCTAssertEqual(count, 9)
            case .S:
                XCTAssertEqual(count, 17)
            case .T:
                XCTAssertEqual(count, 34)
            case .Z:
                XCTAssertEqual(count, 17)
            }
        }
    }

    func testFindingSimplePlacementsForTwoTypesAreCombined() throws {
        let storage: [Int16] = [
            0b01111_11111,
            0b01111_11111,
            0b01101_11111,
            0b00000_01111,
            0b00000_00001,
        ]
        let field = Field(storage: storage)
        let types = Array(Tetromino.allCases.shuffled().prefix(2))
        let set1 = Set(field.findAllPlacements(for: [types[0]]))
        let set2 = Set(field.findAllPlacements(for: [types[1]]))
        let setBoth = Set(field.findAllPlacements(for: types))
        XCTAssertEqual(setBoth, set1.union(set2))
    }

    func testFieldThatDoesnNotHaveHinge() throws {
        let storage: [Int16] = [
            0b01111_11111,
            0b01111_11111,
            0b01101_11111,
            0b00000_01111,
            0b00000_00001,
        ]
        let field = Field(storage: storage)

        XCTAssertTrue(!field.hasHinge(lineMasks: field.makeMultiLineMasks()))
    }

    func testFieldThatHasHinge() throws {
        let storage: [Int16] = [
            0b01111_11111,
            0b01001_11111,
            0b01101_11111,  // left hinge
            0b00000_01111,
            0b00000_00001,
        ]
        let storage2: [Int16] = [
            0b00111_11111,  // right hinge
            0b01111_11111,
            0b01101_11111,
            0b00000_01111,
            0b00000_00001,
        ]
        let field = Field(storage: storage)
        let field2 = Field(storage: storage2)

        XCTAssertTrue(field.hasHinge(lineMasks: field.makeMultiLineMasks()))
        XCTAssertTrue(field2.hasHinge(lineMasks: field.makeMultiLineMasks()))
    }

    func testFieldFindsLeftSlidePlacements() throws {
        let storage: [Int16] = [
            0b11011_11111,
            0b01111_11111,
            0b11111_11011,
            0b00000_00111,
            0b00000_11111,
        ]
        let field = Field(storage: storage)

        let noSlides = field.findAllPlacements(for: [.L])
        let withSlides = field.findAllPlacements(for: [.L], slidesAndTwists: true)
        XCTAssertEqual(withSlides.count, noSlides.count + 2)

        let difference = withSlides.filter { !noSlides.contains($0) }
        XCTAssertEqual(difference.count, 2)

        let piece1 = Piece(type: .L, x: 5, y: 3, orientation: .up)
        let piece2 = Piece(type: .L, x: 4, y: 3, orientation: .up)
        XCTAssertTrue(difference.contains(piece1))
        XCTAssertTrue(difference.contains(piece2))
    }

    func testFieldOnlyFindsLeftSlidePlacementsThatAreLanded() {
        let storage: [Int16] = [
            0b11011_11111,
            0b01111_11111,
            0b10000_01111,
            0b00000_00111,
            0b00000_11111,
        ]
        let field = Field(storage: storage)

        let noSlides = field.findAllPlacements(for: [.L])
        let withSlides = field.findAllPlacements(for: [.L], slidesAndTwists: true)
        XCTAssertEqual(withSlides.count, noSlides.count + 3)

        let difference = withSlides.filter { !noSlides.contains($0) }
        XCTAssertEqual(difference.count, 3)

        let piece1 = Piece(type: .L, x: 5, y: 2, orientation: .up)
        let piece2 = Piece(type: .L, x: 4, y: 3, orientation: .up)
        let piece3 = Piece(type: .L, x: 5, y: 3, orientation: .down)
        XCTAssertTrue(difference.contains(piece1))
        XCTAssertTrue(difference.contains(piece2))
        XCTAssertTrue(difference.contains(piece3))
    }

    func testFieldFindsSlidePlacementsAtBottomWithoutCrashing() throws {
        let storage: [Int16] = [
            0b00000_00111,
            0b00000_11111,
        ]
        let field = Field(storage: storage)

        let noSlides = field.findAllPlacements(for: [.S])
        let withSlides = field.findAllPlacements(for: [.S], slidesAndTwists: true)

        let difference = withSlides.filter { !noSlides.contains($0) }

        let piece = Piece(type: .S, x: 5, y: 0, orientation: .up)
        XCTAssertTrue(difference.contains(piece))
    }

    func testFieldFindsRightSlidePlacements() throws {
        let storage: [Int16] = [
            0b11011_11111,
            0b01111_11111,
            0b11111_11011,
            0b00110_00000,
            0b00011_00000,
        ]
        let field = Field(storage: storage)

        let noSlides = field.findAllPlacements(for: [.I])
        let withSlides = field.findAllPlacements(for: [.I], slidesAndTwists: true)
        XCTAssertEqual(withSlides.count, noSlides.count + 1)

        let difference = withSlides.filter { !noSlides.contains($0) }
        XCTAssertEqual(difference.count, 1)

        let piece = Piece(type: .I, x: 3, y: 3, orientation: .up)
        XCTAssertTrue(difference.contains(piece))
    }

//    func testFoundPlacementsHaveNoIsomorphicDuplicates() {}
}
