// swift-tools-version:5.10
// 纯 Swift 规则层：不依赖 UIKit/SpriteKit，可在 Linux 上运行测试（docs/production/decisions/engine.md）。
import PackageDescription

let package = Package(
    name: "GoblinForgeCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "GoblinForgeCore", targets: ["GoblinForgeCore"]),
    ],
    targets: [
        .target(name: "GoblinForgeCore"),
        .testTarget(name: "GoblinForgeCoreTests", dependencies: ["GoblinForgeCore"]),
    ]
)
