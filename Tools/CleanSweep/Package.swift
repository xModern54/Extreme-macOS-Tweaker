// swift-tools-version: 5.10

import PackageDescription

let package = Package(
  name: "CleanSweep",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(name: "CleanSweepCore", targets: ["CleanSweepCore"]),
    .executable(name: "cleansweep", targets: ["cleansweep"]),
  ],
  targets: [
    .target(
      name: "CleanSweepCore"
    ),
    .executableTarget(
      name: "cleansweep",
      dependencies: ["CleanSweepCore"]
    ),
    .testTarget(
      name: "CleanSweepTests",
      dependencies: ["CleanSweepCore"]
    ),
  ]
)
