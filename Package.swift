// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "spells",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "spells", targets: ["spells"]),
        .library(name: "SpellbookKit", targets: ["SpellbookKit"])
    ],
    targets: [
        .executableTarget(
            name: "spells",
            dependencies: ["SpellbookKit"],
            path: "Sources/spells",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "SpellbookKit",
            path: "Sources/SpellbookKit",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "SpellbookTests",
            dependencies: ["SpellbookKit"],
            path: "Tests/SpellbookTests",
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
