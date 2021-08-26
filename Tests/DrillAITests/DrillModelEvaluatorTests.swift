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

    func testEval() throws {
        let bundle = Bundle(for: DrillModelCoreML.self)
        let url = bundle.url(forResource: "DrillModelCoreML",
                             withExtension: "mlmodelc",
                             subdirectory: "DrillAI_DrillAI.bundle"
        )!

        let evaluator = try DrillModelEvaluator(modelURL: url)

        let shapedArray = MLShapedArray<Float>(repeating: 0, shape: [1, 43, 20, 10])
        print(shapedArray)
//        let result = evaluator.evaluate(shapedArray)!
//        print(result.var_186ShapedArray)
//        print(result.var_205ShapedArray)
    }
}

