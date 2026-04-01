// swift-tools-version: 6.3

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
        .product(name: "Rendering Primitives", package: "swift-rendering-primitives")
    }
    static var copyOnWrite: Self {
        .product(name: "Copy on Write", package: "swift-copy-on-write")
    }
    static var layoutPrimitives: Self {
        .product(name: "Layout Primitives", package: "swift-layout-primitives")
    }
    static var propertyPrimitives: Self {
        .product(name: "Property Primitives", package: "swift-property-primitives")
    }
}

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
        .library(name: .pdfRendering, targets: [.pdfRendering]),
        .library(name: "PDF Rendering Test Support", targets: ["PDF Rendering Test Support"]),
    ],
    dependencies: [
        .package(path: "../../swift-standards/swift-pdf-standard"),
        .package(path: "../../swift-primitives/swift-rendering-primitives"),
        .package(path: "../swift-copy-on-write"),
        .package(path: "../../swift-primitives/swift-layout-primitives"),
        .package(path: "../../swift-primitives/swift-property-primitives"),
        .package(path: "../../swift-primitives/swift-dimension-primitives"),
    ],
    targets: [
        .target(
            name: .pdfRendering,
            dependencies: [
                .pdfStandard,
                .renderingPrimitives,
                .copyOnWrite,
                .layoutPrimitives,
                .propertyPrimitives,
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
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
