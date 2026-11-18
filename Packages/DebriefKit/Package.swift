// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "DebriefKit",
    platforms: [.iOS(.v27)],
    products: [
        .library(name: "DebriefDomain", targets: ["DebriefDomain"]),
        .library(name: "DebriefData", targets: ["DebriefData"]),
        .library(name: "DebriefIntelligence", targets: ["DebriefIntelligence"])
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "13.0.1")
    ],
    targets: [
        .target(name: "DebriefDomain"),
        .target(name: "DebriefData", dependencies: ["DebriefDomain"], resources: [.process("Resources")]),
        .target(name: "DebriefIntelligence", dependencies: ["DebriefDomain", .product(name: "FirebaseAILogic", package: "firebase-ios-sdk")]),
        .testTarget(name: "DebriefDomainTests", dependencies: ["DebriefDomain"]),
        .testTarget(name: "DebriefDataTests", dependencies: ["DebriefData"]),
        .testTarget(name: "DebriefIntelligenceTests", dependencies: ["DebriefIntelligence"])
    ]
)

