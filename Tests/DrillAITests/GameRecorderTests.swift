import XCTest
@testable import DrillAI

final class GameRecorderTests: XCTestCase {

    func testGameRecorderInitializes() throws {
        let state = GameState(garbageCount: 8)
        XCTAssertNoThrow(GameRecorder(initialState: state))
    }

    func testSerializeAndSaveGameRecord() throws {
        let record = GameRecord.with { record in
            record.garbageSeed = 123
            record.pieceSeed = 321
            record.playedPieces = [7, 13, 22]
            record.steps = [
                GameRecord.RecordStep.with { step in
                    step.fieldCells = [true, true, false, true, false]
                    step.tetrominos = [2, 3, 5, 1, 0, 3]
                    step.actions = [95, 84, 73]
                    step.priors = [0.3, 0.4, 0.3]
                    step.value = 0.72
                },
                GameRecord.RecordStep.with { step in
                    step.fieldCells = [false, false, false]
                    step.tetrominos = [4, 2, 0]
                    step.actions = [8, 7, 6]
                    step.priors = [0.1, 0.8, 0.1]
                    step.value = 0.29
                }
            ]
        }

        print(record)
//        print(FileManager.default.currentDirectoryPath)
        XCTAssertNoThrow(try record.serializedData().write(to: .init(fileURLWithPath: "testRecord.pb")))
    }
}
