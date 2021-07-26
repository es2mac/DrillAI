import XCTest
@testable import DrillAI

final class GameStateTests: XCTestCase {

    func testInitiatingStateWithLessThan8Garbages() throws {
        let state = GameState(garbageCount: 5)
        XCTAssertEqual(state.field.height, 5)
        XCTAssertEqual(state.field.garbageCount, 5)
    }

    func testInitiatingStateWithMoreThan8GarbagesHasFieldWith8Garbages() throws {
        let state = GameState(garbageCount: 12)
        XCTAssertEqual(state.field.height, 8)
        XCTAssertEqual(state.field.garbageCount, 8)
    }

    func testInitialStateFindsActionsForFirstTwoPieces() throws {
        // Piece seed 1 => [Z, L, S, J, T, I, O, O, J, T, Z, I, S, L]
        let state = GameState(garbageCount: 100, pieceSeed: 1)
        let actions = state.getLegalActions()
        let types = Set(actions.map(\.type))
        XCTAssertEqual(types, [.Z, .L])
    }

    func testDropPieceCorrectlyDeterminesHoldChanges() throws {
        // Piece seed 1 => [Z, L, S, J, T, I, O, O, J, T, Z, I, S, L]
        var state = GameState(garbageCount: 100, pieceSeed: 1)

        // 1: drop Z without hold
        var piece = state.getLegalActions().filter { $0.type == .Z }.randomElement()!
        state = state.getNextState(for: piece)
        XCTAssertNil(state.hold)
        XCTAssertEqual(state.playPiece, .L)

        // 2: hold L, drop S, next play piece is J
        piece = state.getLegalActions().filter { $0.type == .S }.randomElement()!
        state = state.getNextState(for: piece)
        XCTAssertEqual(state.hold, .L)
        XCTAssertEqual(state.playPiece, .J)

        // 3: Keep holding L, drop J, next play T
        piece = state.getLegalActions().filter { $0.type == .J }.randomElement()!
        state = state.getNextState(for: piece)
        XCTAssertEqual(state.hold, .L)
        XCTAssertEqual(state.playPiece, .T)

        // 4: Swap to hold T, play L, next play I
        piece = state.getLegalActions().filter { $0.type == .L }.randomElement()!
        state = state.getNextState(for: piece)
        XCTAssertEqual(state.hold, .T)
        XCTAssertEqual(state.playPiece, .I)
    }

    func testIncrementGarbageCleared() throws {
        // Piece seed 1 => [Z, L, S, J, T, I, O, O, J, T, Z, I, S, L]
        var state = GameState(garbageCount: 100, garbageSeed: 1, pieceSeed: 1)
        XCTAssertEqual(state.dropCount, 0)
        XCTAssertEqual(state.garbageCleared, 0)
        XCTAssertEqual(state.field.garbageCount, 8)

        var piece = Piece(type: .L, x: 8, y: 8, orientation: .down)
        state = state.getNextState(for: piece)
        XCTAssertEqual(state.dropCount, 1)
        XCTAssertEqual(state.garbageCleared, 1)
        XCTAssertEqual(state.field.garbageCount, 8)

        piece = Piece(type: .S, x: 6, y: 8, orientation: .up)
        state = state.getNextState(for: piece)
        XCTAssertEqual(state.dropCount, 2)
        XCTAssertEqual(state.garbageCleared, 1)
        XCTAssertEqual(state.field.garbageCount, 8)

        piece = Piece(type: .J, x: 1, y: 8, orientation: .up)
        state = state.getNextState(for: piece)
        XCTAssertEqual(state.dropCount, 3)
        XCTAssertEqual(state.garbageCleared, 1)
        XCTAssertEqual(state.field.garbageCount, 8)

        piece = Piece(type: .Z, x: 3, y: 8, orientation: .up)
        state = state.getNextState(for: piece)
        XCTAssertEqual(state.dropCount, 4)
        XCTAssertEqual(state.garbageCleared, 1)
        XCTAssertEqual(state.field.garbageCount, 8)

        piece = Piece(type: .T, x: 9, y: 8, orientation: .left)
        state = state.getNextState(for: piece)
        XCTAssertEqual(state.dropCount, 5)
        XCTAssertEqual(state.garbageCleared, 2)
        XCTAssertEqual(state.field.garbageCount, 8)

        piece = Piece(type: .I, x: 5, y: 9, orientation: .right)
        state = state.getNextState(for: piece)
        XCTAssertEqual(state.dropCount, 6)
        XCTAssertEqual(state.garbageCleared, 3)
        XCTAssertEqual(state.field.garbageCount, 8)
//        print(state.field)
//        print(state.playPiece, state.hold as Any)
    }
}
