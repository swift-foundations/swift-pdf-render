// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-pdf-rendering",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    products: [
        .library(name: "PDF Rendering", targets: ["PDF Rendering"]),
    ],
    dependencies: [
        .package(url: "https://github.com/coenttb/swift-renderable", from: "3.1.0"),
        .package(url: "https://github.com/swift-standards/swift-pdf-standard", from: "0.3.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.18.0"),
        .package(url: "https://github.com/swift-standards/swift-standards", from: "0.16.1"),
    ],
    targets: [
        .target(
            name: "PDF Rendering",
            dependencies: [
                .product(name: "Rendering", package: "swift-renderable"),
                .product(name: "PDF Standard", package: "swift-pdf-standard"),
            ]
        ),
        .testTarget(
            name: "PDF Rendering Tests",
            dependencies: [
                "PDF Rendering",
                .product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing"),
                .product(name: "StandardsTestSupport", package: "swift-standards"),
            ]
        ),
    ]
)
