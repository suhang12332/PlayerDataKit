// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "PlayerDataKit",
    defaultLocalization: "zh-Hans",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "PlayerDataKit",
            targets: ["PlayerDataKit"]),
    ],
    targets: [
        .target(
            name: "PlayerDataKit",
            resources: [
                .process("Resources"),
            ],
            linkerSettings: [
                .linkedLibrary("z", .when(platforms: [.linux])),
            ]),
    ]
)
