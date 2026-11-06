// swift-tools-version: 5.9
import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
  baseSettings: .settings(
    base: [
      "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
      "STRING_CATALOG_GENERATE_SYMBOLS": "YES"
    ]
  ),
  targetSettings: [
    "Noise": ["ENABLE_MODULE_VERIFIER": "YES"],
    "NoiseBackend": ["ENABLE_MODULE_VERIFIER": "YES"],
    "NoiseBoot_iOS": ["ENABLE_MODULE_VERIFIER": "YES"],
    "NoiseSerde": ["ENABLE_MODULE_VERIFIER": "YES"],
    // These packages declare iOS deployment targets below 15.0, which
    // Xcode 27 rejects (the supported range starts at 15.0).
    "Runestone": ["IPHONEOS_DEPLOYMENT_TARGET": "15.0"],
    "Semaphore": ["IPHONEOS_DEPLOYMENT_TARGET": "15.0"],
    "TreeSitter": ["IPHONEOS_DEPLOYMENT_TARGET": "15.0"]
  ]
)
#endif

let package = Package(
  name: "Ruckus",
  dependencies: [
    .package(path: "../../Noise"),
    .package(url: "https://github.com/krzyzanowskim/OpenSSL", from: "3.6.0001"),
    .package(url: "https://github.com/simonbs/runestone.git", from: "0.5.0"),
    .package(url: "https://github.com/groue/Semaphore.git", from: "0.1.0")
  ]
)
