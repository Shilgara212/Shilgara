// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Shilgara",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "Shilgara", targets: ["Shilgara"])],
    targets: [.executableTarget(name: "Shilgara", path: "Sources/MacStudy")]
)
