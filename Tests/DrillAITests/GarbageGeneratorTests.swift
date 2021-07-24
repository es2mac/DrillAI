import XCTest
@testable import DrillAI

final class GarbageGeneratorTests: XCTestCase {

    func testGeneratorProducesOneLine() throws {
        let generator = GarbageGenerator()
        XCTAssertNoThrow(generator[0])
    }

    func testGeneratorProducesArbitraryLines() throws {
        let generator = GarbageGenerator()
        XCTAssertNoThrow(generator[9])
    }

    func testGeneratorProduces300Lines() throws {
        let generator = GarbageGenerator()
        let lines = (0..<300).map { generator[$0] }
        XCTAssertEqual(lines.count, 300)
    }

    func testGeneratedHolesCanBeAnyPosition() throws {
        let generator = GarbageGenerator()
        var lines = Set<Int16>()
        for i in 0 ..< 1000 {
            lines.insert(generator[i])
            if lines.count >= 10 {
                break
            }
        }
        let possibileLines: [Int16] = (0..<10).map { i in
            0b11111_11111 ^ (1 << i)
        }
        XCTAssertEqual(lines.sorted(by: >), possibileLines)
    }

    func testGeneratedHolesDontOverlap() throws {
        let generator = GarbageGenerator()
        let differences = (0 ..< 100).map { i in
            generator[i + 1] - generator[i]
        }
        XCTAssertNil(differences.firstIndex(of: 0))
    }

    func testGeneratorsWithSameSeedsGiveSameLines() throws {
        let seed: UInt64 = 42
        let generator = GarbageGenerator(seed: seed)
        let lines = (0..<300).map { generator[$0] }

        let generator2 = GarbageGenerator(seed: seed)
        let lines2 = (0..<300).map { generator2[$0] }

        XCTAssertEqual(lines, lines2)
    }

    func testGeneratorsWithDifferentSeedsGiveDifferentLines() throws {
        let generator = GarbageGenerator(seed: 42)
        let lines = (0..<20).map { generator[$0] }

        let generator2 = GarbageGenerator(seed: 9876)
        let lines2 = (0..<20).map { generator2[$0] }

        XCTAssertNotEqual(lines, lines2)
    }

    func testUsingOldSeedsToRecreateGeneratorProducesSameLines() throws {
        let generator = GarbageGenerator()
        let pieces = (0..<20).map { generator[$0] }

        let seed = generator.seed
        let generator2 = GarbageGenerator(seed: seed)
        let pieces2 = (0..<20).map { generator2[$0] }

        XCTAssertEqual(pieces, pieces2)
    }
}
