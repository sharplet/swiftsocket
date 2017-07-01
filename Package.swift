// swift-tools-version:4.0

import PackageDescription

let package = Package(
  name: "swiftsocket",
  dependencies: [
    .package(url: "https://github.com/ReactiveCocoa/ReactiveSwift.git", from: "1.0.0"),
    .package(url: "https://github.com/Quick/Quick.git", .branch("xcode-9-fix")),
    .package(url: "https://github.com/Quick/Nimble.git", from: "7.0.1"),
  ],
  targets: [
    .target(
      name: "swiftsocket",
      dependencies: [
        "Socket",
      ]
    ),
    .target(
      name: "Socket",
      dependencies: [
        "ReactiveSwift",
        "support",
      ]
    ),
    .target(
      name: "support",
      dependencies: []
    ),
    .target(
      name: "Pipes",
      dependencies: []
    ),
    .testTarget(
      name: "PipesTests",
      dependencies: ["Pipes", "Quick", "Nimble"]
    ),
  ]
)
