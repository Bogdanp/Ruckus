import ProjectDescription

let project = Project(
  name: "Ruckus",
  settings: .settings(
    configurations: [
      .debug(name: "Debug", xcconfig: "./xcconfigs/Ruckus-Project.xcconfig"),
      .release(name: "Release", xcconfig: "./xcconfigs/Ruckus-Project.xcconfig"),
    ]
  ),
  targets: [
    .target(
      name: "Ruckus",
      destinations: .iOS,
      product: .app,
      bundleId: "io.defn.Ruckus",
      deploymentTargets: .iOS("26.0"),
      sources: ["Ruckus/**"],
      resources: [.folderReference(path: "Ruckus/res")],
      scripts: [
        .pre(
          script: "swiftlint lint --quiet",
          name: "SwiftLint",
          basedOnDependencyAnalysis: false
        ),
      ],
      dependencies: [
        .external(name: "NoiseBackend"),
        .external(name: "NoiseSerde"),
        .external(name: "Noise"),
        .external(name: "OpenSSL")
      ],
      settings: .settings(
        configurations: [
          .debug(name: "Debug", xcconfig: "./xcconfigs/Ruckus.xcconfig"),
          .debug(name: "Release", xcconfig: "./xcconfigs/Ruckus.xcconfig"),
        ]
      )
    ),
  ]
)
