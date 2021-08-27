import XCTest
import CoreML
@testable import DrillAI


final class DrillModelEvaluatorTests: XCTestCase {

    func testModelLoads() throws {
        // Issue with test target: Can't find resource without specifying
        // subdirectory.  Normally the model should just be loaded without
        // having to specify the resource url.
        let bundle = Bundle(for: DrillModelCoreML.self)
        let url = bundle.url(forResource: "DrillModelCoreML",
                             withExtension: "mlmodelc",
                             subdirectory: "DrillAI_DrillAI.bundle"
        )!
        XCTAssertNoThrow(_ = try DrillModelEvaluator(modelURL: url))
    }

//    func testTest() async throws {
//        let bundle = Bundle(for: DrillModelCoreML.self)
//        let url = bundle.url(forResource: "DrillModelCoreML",
//                             withExtension: "mlmodelc",
//                             subdirectory: "DrillAI_DrillAI.bundle"
//        )!
//
//        let evaluator = try DrillModelEvaluator(modelURL: url)
//
//        // Borrowed from GameStateTests
//        // Piece seed 1 => [Z, L, S, J, T, I, O, O, J, T, Z, I, S, L]
//        var state = GameState(garbageCount: 100, garbageSeed: 1, pieceSeed: 1)
//        var piece = Piece(type: .L, x: 8, y: 8, orientation: .down)
//        state = state.getNextState(for: piece)
//
//        piece = Piece(type: .S, x: 6, y: 8, orientation: .up)
//        state = state.getNextState(for: piece)
//
//        piece = Piece(type: .J, x: 1, y: 8, orientation: .up)
//        state = state.getNextState(for: piece)
//
////        print(state.field)
//
////        let shapedArray = evaluator.encode(state: state)
////        let output = evaluator.evaluate(shapedArray)!
////        print(output.var_186ShapedArray)
////        print(output.var_205ShapedArray)
//        let evaluations = await evaluator.evaluate(info: [(id: .init(self), state: state, nextActions: state.getLegalActions())])
//
//    }
}

