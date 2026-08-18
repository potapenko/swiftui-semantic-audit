// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swiftui-semantic-audit",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "AuditCore", targets: ["AuditCore"]),
        .library(name: "SwiftSyntaxFrontend", targets: ["SwiftSyntaxFrontend"]),
        .library(name: "SwiftUISemantics", targets: ["SwiftUISemantics"]),
        .library(name: "SemanticNormalization", targets: ["SemanticNormalization"]),
        .library(name: "AuditRules", targets: ["AuditRules"]),
        .library(name: "SnapshotStore", targets: ["SnapshotStore"]),
        .library(name: "ContextSlicer", targets: ["ContextSlicer"]),
        .library(name: "SemanticDiff", targets: ["SemanticDiff"]),
        .library(name: "SymbolResolution", targets: ["SymbolResolution"]),
        .executable(name: "swiftui-audit", targets: ["SwiftUIAuditCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", exact: "603.0.2"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", exact: "1.8.2"),
        .package(
            url: "https://github.com/swiftlang/indexstore-db.git",
            revision: "003ac41513ba291f10ff1a0147ae68588914668d"
        ),
    ],
    targets: [
        .target(name: "AuditCore"),
        .target(
            name: "SwiftUISemantics",
            dependencies: ["AuditCore"]
        ),
        .target(
            name: "SwiftSyntaxFrontend",
            dependencies: [
                "AuditCore",
                "SwiftUISemantics",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ]
        ),
        .target(
            name: "SemanticNormalization",
            dependencies: ["AuditCore"]
        ),
        .target(
            name: "AuditRules",
            dependencies: ["AuditCore", "SemanticNormalization"]
        ),
        .target(
            name: "SnapshotStore",
            dependencies: ["AuditCore"]
        ),
        .target(
            name: "ContextSlicer",
            dependencies: ["AuditCore", "SnapshotStore"]
        ),
        .target(
            name: "SemanticDiff",
            dependencies: [
                "AuditCore",
                "AuditRules",
                "SnapshotStore",
                "SymbolResolution",
                "SwiftSyntaxFrontend",
            ]
        ),
        .target(
            name: "SymbolResolution",
            dependencies: [
                "AuditCore",
                .product(
                    name: "IndexStoreDB",
                    package: "indexstore-db",
                    condition: .when(platforms: [.macOS])
                ),
            ]
        ),
        .executableTarget(
            name: "SwiftUIAuditCLI",
            dependencies: [
                "AuditCore",
                "AuditRules",
                "ContextSlicer",
                "SemanticDiff",
                "SnapshotStore",
                "SymbolResolution",
                "SwiftSyntaxFrontend",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "ExtractionTests",
            dependencies: ["AuditCore", "SwiftSyntaxFrontend"]
        ),
        .testTarget(
            name: "RuleTests",
            dependencies: ["AuditCore", "AuditRules", "SwiftSyntaxFrontend"]
        ),
        .testTarget(
            name: "SnapshotTests",
            dependencies: ["AuditCore", "AuditRules", "SnapshotStore", "SwiftSyntaxFrontend"]
        ),
        .testTarget(
            name: "ContextSlicerTests",
            dependencies: ["AuditCore", "AuditRules", "ContextSlicer", "SnapshotStore", "SwiftSyntaxFrontend"]
        ),
        .testTarget(
            name: "DiffTests",
            dependencies: ["AuditCore", "AuditRules", "SemanticDiff", "SnapshotStore", "SwiftSyntaxFrontend"]
        ),
        .testTarget(
            name: "CheckTests",
            dependencies: ["AuditCore", "AuditRules", "SemanticDiff", "SwiftSyntaxFrontend"]
        ),
        .testTarget(
            name: "DoctorTests",
            dependencies: ["SemanticDiff", "SymbolResolution"]
        ),
        .testTarget(
            name: "SymbolResolutionTests",
            dependencies: [
                "AuditCore",
                "AuditRules",
                "ContextSlicer",
                "SemanticDiff",
                "SnapshotStore",
                "SymbolResolution",
                "SwiftSyntaxFrontend",
            ]
        ),
    ]
)
