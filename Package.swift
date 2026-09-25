// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Porticide",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Porticide", targets: ["Porticide"])
    ],
    targets: [
        // Port discovery, process inspection and classification. No UI dependencies.
        .target(name: "PorticideKit"),
        // The menu bar app (AppKit + SwiftUI).
        .executableTarget(
            name: "Porticide",
            dependencies: ["PorticideKit"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "PorticideKitTests",
            dependencies: ["PorticideKit"]
        )
    ]
)
