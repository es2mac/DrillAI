import XCTest
@testable import DrillAI

final class PieceGeneratorTests: XCTestCase {

    func testGeneratorProducesOnePiece() throws {
        let generator = PieceGenerator()
        XCTAssertNoThrow(generator[0])
    }

    func testGeneratorProducesArbitraryPiece() throws {
        let generator = PieceGenerator()
        XCTAssertNoThrow(generator[9])
    }

    func testGeneratorProduces300Pieces() throws {
        let generator = PieceGenerator()
        let pieces = (0..<300).map { generator[$0] }
        XCTAssertEqual(pieces.count, 300)
    }

    func testGeneratedSequenceAreInSevenBags() throws {
        let generator = PieceGenerator()
        var pieces = Set<Tetromino>()
        for i in 0 ..< 7 {
            pieces.insert(generator[i])
        }
        XCTAssertEqual(pieces.count, 7)
        for i in 7 ..< 14 {
            pieces.remove(generator[i])
        }
        XCTAssertEqual(pieces.count, 0)
    }

    func testGeneratorsWithSameSeedsGiveSamePieces() throws {
        let seed: UInt64 = 42
        let generator = PieceGenerator(seed: seed)
        let pieces = (0..<300).map { generator[$0] }

        let generator2 = PieceGenerator(seed: seed)
        let pieces2 = (0..<300).map { generator2[$0] }

        XCTAssertEqual(pieces, pieces2)
    }

    func testGeneratorsWithDifferentSeedsGiveDifferentPieces() throws {
        let generator = PieceGenerator(seed: 42)
        let pieces = (0..<20).map { generator[$0] }

        let generator2 = PieceGenerator(seed: 9876)
        let pieces2 = (0..<20).map { generator2[$0] }

        XCTAssertNotEqual(pieces, pieces2)
    }

    func testUsingOldSeedsToRecreateGeneratorProducesSameSequence() throws {
        let generator = PieceGenerator()
        let pieces = (0..<20).map { generator[$0] }

        let seed = generator.seed
        let generator2 = PieceGenerator(seed: seed)
        let pieces2 = (0..<20).map { generator2[$0] }

        XCTAssertEqual(pieces, pieces2)
    }
}
