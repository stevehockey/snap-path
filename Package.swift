// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SnapPath",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "SnapPathCore",
            path: "Sources/SnapPathCore"
        ),
        .executableTarget(
            name: "SnapPath",
            dependencies: ["SnapPathCore"],
            path: "Sources/SnapPath"
        ),
        .testTarget(
            name: "SnapPathTests",
            dependencies: ["SnapPathCore"],
            path: "Tests/SnapPathTests"
        )
    ]
)
