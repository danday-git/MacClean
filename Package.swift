// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacClean",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "MacClean",
            targets: ["MacClean"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "MacClean",
            path: "MacClean",
            exclude: ["Resources"]
        ),
        .testTarget(
            name: "MacCleanTests",
            dependencies: ["MacClean"],
            path: "MacCleanTests"
        )
    ]
)
