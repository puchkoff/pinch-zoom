// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PinchZoom",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "PinchZoom",
            path: "Sources/PinchZoom"
        )
    ]
)
