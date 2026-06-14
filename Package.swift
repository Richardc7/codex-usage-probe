// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CodexUsageProbe",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "codex-usage-probe", targets: ["CodexUsageProbe"]),
        .executable(name: "CodexUsageMenuBar", targets: ["CodexUsageMenuBar"])
    ],
    targets: [
        .target(
            name: "CodexUsageCore"
        ),
        .executableTarget(
            name: "CodexUsageProbe",
            dependencies: ["CodexUsageCore"]
        ),
        .executableTarget(
            name: "CodexUsageMenuBar",
            dependencies: ["CodexUsageCore"],
            linkerSettings: [
                .linkedFramework("AppKit")
            ]
        ),
        .testTarget(
            name: "CodexUsageCoreTests",
            dependencies: ["CodexUsageCore"]
        )
    ]
)
