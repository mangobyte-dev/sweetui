// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SweetUI",
    platforms: [
        .macOS(.v15),
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "SweetUIFoundations",
            targets: ["SweetUIFoundations"]
        ),
        .library(
            name: "SweetUIDesignSurface",
            targets: ["SweetUIDesignSurface"]
        ),
        .library(name: "SweetUIKit", targets: ["SweetUIKit"]),
        .executable(name: "sweetui", targets: ["SweetUICLI"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
        .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.3.0"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.4.3"),
        .package(url: "https://github.com/pointfreeco/swift-sharing", "2.9.1"..<"2.10.0", traits: []),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.18.9"),
    ],
    targets: [
        .target(
            name: "SweetUIKit",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
            ],
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
        .executableTarget(
            name: "SweetUICLI",
            dependencies: [
                "SweetUIKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Dependencies", package: "swift-dependencies"),
            ],
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
        .testTarget(
            name: "SweetUIKitTests",
            dependencies: [
                "SweetUIKit",
                "SweetUICLI",
                .product(name: "CustomDump", package: "swift-custom-dump"),
                .product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing"),
                .product(name: "DependenciesTestSupport", package: "swift-dependencies"),
            ],
            resources: [.copy("Fixtures")],
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
        .target(name: "SweetUIFoundations"),
        .target(
            name: "SweetUIDesignSurface",
            dependencies: [
                "SweetUIFoundations",
                .product(name: "Sharing", package: "swift-sharing")
            ]
        ),
        .testTarget(
            name: "SweetUIFoundationsTests",
            dependencies: ["SweetUIFoundations"]
        )
    ],
    swiftLanguageModes: [.v6]
)
