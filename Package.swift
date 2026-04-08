// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SpankApp",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "SpankApp",
            path: "Sources/SpankApp",
            resources: [.copy("Resources")]
        )
    ]
)
