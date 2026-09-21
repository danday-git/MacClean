// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SweepMyMac",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "SweepMyMac",
            targets: ["SweepMyMac"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "SweepMyMac",
            path: "SweepMyMac",
            exclude: ["Resources"]
        ),
        .testTarget(
            name: "SweepMyMacTests",
            dependencies: ["SweepMyMac"],
            path: "SweepMyMacTests"
        )
    ]
)
