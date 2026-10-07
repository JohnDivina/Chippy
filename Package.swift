// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Chippy",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "ChippyCore", targets: ["ChippyCore"]),
        .executable(name: "Chippy", targets: ["Chippy"])
    ],
    targets: [
        .target(
            name: "ChippyCore",
            path: "Sources/ChippyCore",
            resources: [
                .copy("Resources")
            ]
        ),
        .executableTarget(
            name: "Chippy",
            dependencies: ["ChippyCore"],
            path: "Sources/Chippy"
        ),
        .testTarget(
            name: "ChippyCoreTests",
            dependencies: ["ChippyCore"],
            path: "Tests/ChippyCoreTests",
            resources: [
                .copy("Fixtures")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
