// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Selenophile",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "Selenophile", targets: ["Selenophile"]),
        .library(name: "SelenophileKit", targets: ["SelenophileKit"]),
    ],
    targets: [
        .target(
            name: "SelenophileKit",
            path: "Sources/SelenophileKit",
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "Selenophile",
            dependencies: ["SelenophileKit"],
            path: "Sources/Selenophile",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "SelenophileTests",
            dependencies: ["Selenophile"],
            path: "Tests/SelenophileTests"
        ),
        .testTarget(
            name: "SelenophileKitTests",
            dependencies: ["SelenophileKit"],
            path: "Tests/SelenophileKitTests"
        ),
    ]
)
