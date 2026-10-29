// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TrackpadInk",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "TrackpadInkLab", targets: ["TrackpadInkLab"]),
        .executable(name: "TrackpadInkBridge", targets: ["TrackpadInkBridge"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Kyome22/OpenMultitouchSupport.git", exact: "3.0.3"),
    ],
    targets: [
        .executableTarget(name: "TrackpadInkLab"),
        .executableTarget(
            name: "TrackpadInkBridge",
            dependencies: [.product(name: "OpenMultitouchSupport", package: "OpenMultitouchSupport")]
        ),
    ]
)
