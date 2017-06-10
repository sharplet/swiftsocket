// swift-tools-version:4.0

import PackageDescription

let package = Package(
  name: "swiftsocket",
  dependencies: [
    .package(url: "https://github.com/ReactiveCocoa/ReactiveSwift.git", from: "1.0.0"),
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
  ]
)
