// swift-tools-version: 6.3.1

import PackageDescription

extension String {
    static let pdfRendering: Self = "PDF Rendering"
    var tests: Self { self + " Tests" }
}

extension Target.Dependency {
    static var pdfRendering: Self { .target(name: .pdfRendering) }
}

extension Target.Dependency {
    static var pdfStandard: Self {
        .product(name: "PDF Standard", package: "swift-pdf-standard")
    }
    static var renderingPrimitives: Self {
        .product(name: "Render Primitives", package: "swift-render-primitives")
    }
    static var copyOnWrite: Self {
        .product(name: "Copy on Write", package: "swift-copy-on-write")
    }
    static var ascii: Self {
        .product(name: "ASCII", package: "swift-ascii")
    }
    static var layoutPrimitives: Self {
        .product(name: "Layout Primitives", package: "swift-layout-primitives")
    }
    static var propertyPrimitives: Self {
        .product(name: "Property Primitives", package: "swift-property-primitives")
    }
    static var pairPrimitives: Self {
        .product(name: "Pair Primitives", package: "swift-pair-primitives")
    }
}

let package = Package(
    name: "swift-pdf-render",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    products: [
        .library(name: .pdfRendering, targets: [.pdfRendering]),
        .library(name: "PDF Rendering Test Support", targets: ["PDF Rendering Test Support"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-standards/swift-pdf-standard.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-render-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-copy-on-write.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-ascii.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-layout-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-property-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-dimension-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-pair-primitives.git", branch: "main"),
    ],
    targets: [
        .target(
            name: .pdfRendering,
            dependencies: [
                .pdfStandard,
                .renderingPrimitives,
                .copyOnWrite,
                .ascii,
                .layoutPrimitives,
                .propertyPrimitives,
                .pairPrimitives,
            ]
        ),
        .target(
            name: "PDF Rendering Test Support",
            dependencies: [
                .pdfRendering,
                .product(name: "Dimension Primitives Test Support", package: "swift-dimension-primitives"),
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: .pdfRendering.tests,
            dependencies: [
                .pdfRendering,
                "PDF Rendering Test Support",
            ],
            path: "Tests/PDF Rendering Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
