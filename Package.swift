// swift-tools-version:6.2
import PackageDescription

let package = Package(
  name: "sf",
  platforms: [
    .macOS(.v13)
  ],
  products: [
    .executable(name: "sf", targets: ["sf"])
  ],
  dependencies: [],
  targets: [
    .executableTarget(name: "sf"),
  ])
