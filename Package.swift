// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DrillAI",
    platforms: [.macOS(.v10_15)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "DrillAI",
            targets: ["DrillAI"]),
    ],
    dependencies: [
        .package(name: "SwiftProtobuf", url: "https://github.com/apple/swift-protobuf.git", from: "1.17.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "DrillAI",
            dependencies: ["SwiftProtobuf"],
            exclude: ["MLModel/GameRecord/README.md",
                      "MLModel/GameRecord/DrillGameRecord.proto",
                      "MLModel/GameRecord/DrillGameRecord_pb2.py"],
            resources: [.process("MLModel/CompiledDrillModel/DrillModelCoreML.mlmodelc")],
            swiftSettings: [
                .unsafeFlags(["-Xfrontend", "-disable-availability-checking"])
            ]),
        .testTarget(
            name: "DrillAITests",
            dependencies: ["DrillAI"],
            swiftSettings: [
                .unsafeFlags(["-Xfrontend", "-disable-availability-checking", "-Xfrontend", "-enable-experimental-concurrency"])
            ]),
    ]
)
