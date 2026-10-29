// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TrackpadInk",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "TrackpadInkLab", targets: ["TrackpadInkLab"])],
    targets: [.executableTarget(name: "TrackpadInkLab")]
)
