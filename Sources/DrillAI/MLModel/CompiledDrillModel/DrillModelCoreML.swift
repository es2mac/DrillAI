//
// DrillModelCoreML.swift
//
// This file was automatically generated and should not be edited.
//

import CoreML


/// Model Prediction Input Type
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
class DrillModelCoreMLInput : MLFeatureProvider {

    /// input as 1 × 43 × 20 × 10 4-dimensional array of floats
    var input: MLMultiArray

    var featureNames: Set<String> {
        get {
            return ["input"]
        }
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "input") {
            return MLFeatureValue(multiArray: input)
        }
        return nil
    }
    
    init(input: MLMultiArray) {
        self.input = input
    }

    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    convenience init(input: MLShapedArray<Float>) {
        self.init(input: MLMultiArray(input))
    }

}


/// Model Prediction Output Type
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
class DrillModelCoreMLOutput : MLFeatureProvider {

    /// Source provided by CoreML
    private let provider : MLFeatureProvider

    /// var_205 as multidimensional array of floats
    lazy var var_205: MLMultiArray = {
        [unowned self] in return self.provider.featureValue(for: "var_205")!.multiArrayValue
    }()!

    /// var_205 as multidimensional array of floats
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    lazy var var_205ShapedArray: MLShapedArray<Float> = {
        [unowned self] in return MLShapedArray<Float>(self.var_205)
    }()

    /// var_186 as multidimensional array of floats
    lazy var var_186: MLMultiArray = {
        [unowned self] in return self.provider.featureValue(for: "var_186")!.multiArrayValue
    }()!

    /// var_186 as multidimensional array of floats
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    lazy var var_186ShapedArray: MLShapedArray<Float> = {
        [unowned self] in return MLShapedArray<Float>(self.var_186)
    }()

    var featureNames: Set<String> {
        return self.provider.featureNames
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        return self.provider.featureValue(for: featureName)
    }

    init(var_205: MLMultiArray, var_186: MLMultiArray) {
        self.provider = try! MLDictionaryFeatureProvider(dictionary: ["var_205" : MLFeatureValue(multiArray: var_205), "var_186" : MLFeatureValue(multiArray: var_186)])
    }

    init(features: MLFeatureProvider) {
        self.provider = features
    }
}


/// Class for model loading and prediction
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
class DrillModelCoreML {
    let model: MLModel

    /// URL of model assuming it was installed in the same bundle as this class
    class var urlOfModelInThisBundle : URL {
        let bundle = Bundle(for: self)
        return bundle.url(forResource: "DrillModelCoreML", withExtension: "mlmodelc")!
    }

    /**
        Construct DrillModelCoreML instance with an existing MLModel object.

        Usually the application does not use this initializer unless it makes a subclass of DrillModelCoreML.
        Such application may want to use `MLModel(contentsOfURL:configuration:)` and `DrillModelCoreML.urlOfModelInThisBundle` to create a MLModel object to pass-in.

        - parameters:
          - model: MLModel object
    */
    init(model: MLModel) {
        self.model = model
    }

    /**
        Construct a model with configuration

        - parameters:
           - configuration: the desired model configuration

        - throws: an NSError object that describes the problem
    */
    convenience init(configuration: MLModelConfiguration = MLModelConfiguration()) throws {
        try self.init(contentsOf: type(of:self).urlOfModelInThisBundle, configuration: configuration)
    }

    /**
        Construct DrillModelCoreML instance with explicit path to mlmodelc file
        - parameters:
           - modelURL: the file url of the model

        - throws: an NSError object that describes the problem
    */
    convenience init(contentsOf modelURL: URL) throws {
        try self.init(model: MLModel(contentsOf: modelURL))
    }

    /**
        Construct a model with URL of the .mlmodelc directory and configuration

        - parameters:
           - modelURL: the file url of the model
           - configuration: the desired model configuration

        - throws: an NSError object that describes the problem
    */
    convenience init(contentsOf modelURL: URL, configuration: MLModelConfiguration) throws {
        try self.init(model: MLModel(contentsOf: modelURL, configuration: configuration))
    }

    /**
        Construct DrillModelCoreML instance asynchronously with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - configuration: the desired model configuration
          - handler: the completion handler to be called when the model loading completes successfully or unsuccessfully
    */
    class func load(configuration: MLModelConfiguration = MLModelConfiguration(), completionHandler handler: @escaping (Swift.Result<DrillModelCoreML, Error>) -> Void) {
        return self.load(contentsOf: self.urlOfModelInThisBundle, configuration: configuration, completionHandler: handler)
    }

    /**
        Construct DrillModelCoreML instance asynchronously with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - configuration: the desired model configuration
    */
    class func load(configuration: MLModelConfiguration = MLModelConfiguration()) async throws -> DrillModelCoreML {
        return try await self.load(contentsOf: self.urlOfModelInThisBundle, configuration: configuration)
    }

    /**
        Construct DrillModelCoreML instance asynchronously with URL of the .mlmodelc directory with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - modelURL: the URL to the model
          - configuration: the desired model configuration
          - handler: the completion handler to be called when the model loading completes successfully or unsuccessfully
    */
    class func load(contentsOf modelURL: URL, configuration: MLModelConfiguration = MLModelConfiguration(), completionHandler handler: @escaping (Swift.Result<DrillModelCoreML, Error>) -> Void) {
        MLModel.load(contentsOf: modelURL, configuration: configuration) { result in
            switch result {
            case .failure(let error):
                handler(.failure(error))
            case .success(let model):
                handler(.success(DrillModelCoreML(model: model)))
            }
        }
    }

    /**
        Construct DrillModelCoreML instance asynchronously with URL of the .mlmodelc directory with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - modelURL: the URL to the model
          - configuration: the desired model configuration
    */
    class func load(contentsOf modelURL: URL, configuration: MLModelConfiguration = MLModelConfiguration()) async throws -> DrillModelCoreML {
        let model = try await MLModel.load(contentsOf: modelURL, configuration: configuration)
        return DrillModelCoreML(model: model)
    }

    /**
        Make a prediction using the structured interface

        - parameters:
           - input: the input to the prediction as DrillModelCoreMLInput

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as DrillModelCoreMLOutput
    */
    func prediction(input: DrillModelCoreMLInput) throws -> DrillModelCoreMLOutput {
        return try self.prediction(input: input, options: MLPredictionOptions())
    }

    /**
        Make a prediction using the structured interface

        - parameters:
           - input: the input to the prediction as DrillModelCoreMLInput
           - options: prediction options 

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as DrillModelCoreMLOutput
    */
    func prediction(input: DrillModelCoreMLInput, options: MLPredictionOptions) throws -> DrillModelCoreMLOutput {
        let outFeatures = try model.prediction(from: input, options:options)
        return DrillModelCoreMLOutput(features: outFeatures)
    }

    /**
        Make a prediction using the convenience interface

        - parameters:
            - input as 1 × 43 × 20 × 10 4-dimensional array of floats

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as DrillModelCoreMLOutput
    */
    func prediction(input: MLMultiArray) throws -> DrillModelCoreMLOutput {
        let input_ = DrillModelCoreMLInput(input: input)
        return try self.prediction(input: input_)
    }

    /**
        Make a prediction using the convenience interface

        - parameters:
            - input as 1 × 43 × 20 × 10 4-dimensional array of floats

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as DrillModelCoreMLOutput
    */

    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    func prediction(input: MLShapedArray<Float>) throws -> DrillModelCoreMLOutput {
        let input_ = DrillModelCoreMLInput(input: input)
        return try self.prediction(input: input_)
    }

    /**
        Make a batch prediction using the structured interface

        - parameters:
           - inputs: the inputs to the prediction as [DrillModelCoreMLInput]
           - options: prediction options 

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as [DrillModelCoreMLOutput]
    */
    func predictions(inputs: [DrillModelCoreMLInput], options: MLPredictionOptions = MLPredictionOptions()) throws -> [DrillModelCoreMLOutput] {
        let batchIn = MLArrayBatchProvider(array: inputs)
        let batchOut = try model.predictions(from: batchIn, options: options)
        var results : [DrillModelCoreMLOutput] = []
        results.reserveCapacity(inputs.count)
        for i in 0..<batchOut.count {
            let outProvider = batchOut.features(at: i)
            let result =  DrillModelCoreMLOutput(features: outProvider)
            results.append(result)
        }
        return results
    }
}
