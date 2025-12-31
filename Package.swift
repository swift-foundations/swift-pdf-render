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
        .library(name: "PDF Rendering", targets: ["PDF Rendering"])
    ],
    dependencies: [
        .package(url: "https://github.com/coenttb/swift-renderable", from: "3.2.1"),
        .package(url: "https://github.com/coenttb/swift-copy-on-write", from: "0.3.1"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.18.7"),
        .package(url: "https://github.com/swift-standards/swift-pdf-standard", from: "0.3.2"),
        .package(url: "https://github.com/swift-standards/swift-standards", from: "0.21.0"),
    ],
    targets: [
        .target(
            name: "PDF Rendering",
            dependencies: [
                .product(name: "PDF Standard", package: "swift-pdf-standard"),
                .product(name: "Rendering", package: "swift-renderable"),
                .product(name: "Copy on Write", package: "swift-copy-on-write"),
                .product(name: "Layout", package: "swift-standards"),
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
