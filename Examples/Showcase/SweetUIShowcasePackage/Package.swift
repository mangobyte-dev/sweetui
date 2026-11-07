// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SweetUIShowcaseFeature",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "SweetUIShowcaseFeature",
            targets: ["SweetUIShowcaseFeature"]
        )
    ],
    dependencies: [
        .package(name: "SweetUI", path: "../../.."),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "SweetUIShowcaseFeature",
            dependencies: [
                .product(
                    name: "SweetUIFoundations",
                    package: "SweetUI"
                ),
                .product(
                    name: "SweetUIDesignSurface",
                    package: "SweetUI"
                )
            ]
        ),
        .testTarget(
            name: "SweetUIShowcaseFeatureTests",
            dependencies: [
                "SweetUIShowcaseFeature",
                .product(name: "DependenciesTestSupport", package: "swift-dependencies")
            ]
        )
    ]
)
