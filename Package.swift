// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "PolioPager",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "PolioPager",
            targets: ["PolioPager"])
    ],
    targets: [
        .target(
            name: "PolioPager",
            path: "PolioPager"),
        .testTarget(
            name: "PolioPagerTests",
            path: "PolioPagerTests"),
    ]
)
