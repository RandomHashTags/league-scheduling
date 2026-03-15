// swift-tools-version:6.2

import PackageDescription

let package = Package(
    name: "league-scheduling",
    products: [
        .library(
            name: "LeagueScheduling",
            targets: ["LeagueScheduling"]
        ),
    ],
    traits: [
        .default(enabledTraits: [
            "ProtobufCodable",
            "UncheckedArraySubscript"
        ]),
        .trait(name: "ProtobufCodable"),
        .trait(name: "UncheckedArraySubscript")
    ],
    dependencies: [
        .package(url: "https://github.com/RandomHashTags/swift-staticdatetime", from: "0.3.5"),

        // Protocol buffers
        .package(url: "https://github.com/apple/swift-protobuf", from: "1.31.0"),
    ],
    targets: [
        .target(
            name: "LeagueScheduling",
            dependencies: [
                .product(name: "StaticDateTimes", package: "swift-staticdatetime"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ],
            path: "Sources/league-scheduling",
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")]
        ),
        .testTarget(
            name: "LeagueSchedulingTests",
            dependencies: ["LeagueScheduling"]
        )
    ]
)
