// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ClaudeUsageBar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ClaudeUsageBar", targets: ["ClaudeUsageBar"])
    ],
    targets: [
        .executableTarget(
            name: "ClaudeUsageBar",
            path: "Sources/ClaudeUsageBar"
        )
    ],
    swiftLanguageVersions: [.v5]
)
