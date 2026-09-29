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
        .package(name: "SweetUI", path: "../../..")
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
            dependencies: ["SweetUIShowcaseFeature"]
        )
    ]
)
