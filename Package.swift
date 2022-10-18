// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "BackgroundService",
    products: [
        .library(
            name: "BackgroundService",
            targets: ["BackgroundService"]
        )
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "BackgroundService",
            dependencies: []
        )
    ]
)
