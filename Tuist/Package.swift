// swift-tools-version: 5.9
import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
  productTypes: [:]
)
#endif

let package = Package(
  name: "Ruckus",
  dependencies: [
    .package(path: "../../Noise"),
    .package(url: "https://github.com/krzyzanowskim/OpenSSL", from: "3.6.0001")
  ]
)
