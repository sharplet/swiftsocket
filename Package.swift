// swift-tools-version:4.0

import PackageDescription

let package = Package(
  name: "swiftsocket",
  dependencies: [
  ],
  targets: [
    .target(
      name: "swiftsocket",
      dependencies: [
        "support",
      ]
    ),
    .target(
      name: "support",
      dependencies: []
    ),
  ]
)
