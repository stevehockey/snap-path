// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SnapPath",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "SnapPathCore",
            dependencies: [
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
            ],
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
