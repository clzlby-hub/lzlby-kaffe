// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KaffelogicStudioNative",
    defaultLocalization: "zh",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "KaffelogicStudioNative",
            targets: ["KaffelogicStudioNative"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "KaffelogicStudioNative",
            path: "Sources/KaffelogicStudio"
        )
    ]
)
