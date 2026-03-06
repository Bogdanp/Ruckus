import ProjectDescription

let project = Project(
  name: "Ruckus",
  settings: .settings(
    base: [
      "SWIFT_VERSION": "6.0",
      "STRING_CATALOG_GENERATE_SYMBOLS": "YES"
    ],
    configurations: [
      .debug(name: "Debug", xcconfig: "./xcconfigs/Ruckus-Project.xcconfig"),
      .release(name: "Release", xcconfig: "./xcconfigs/Ruckus-Project.xcconfig")
    ]
  ),
  targets: [
    .target(
      name: "Ruckus",
      destinations: .iOS,
      product: .app,
      bundleId: "io.defn.Ruckus",
      deploymentTargets: .iOS("26.0"),
      infoPlist: .extendingDefault(with: [
        "CFBundleDocumentTypes": .array([
          .dictionary([
            "CFBundleTypeName": .string("Racket Source"),
            "CFBundleTypeRole": .string("Editor"),
            "LSHandlerRank": .string("Default"),
            "LSItemContentTypes": .array([
              .string("org.racket-lang.racket-source")
            ])
          ])
        ]),
        "UTImportedTypeDeclarations": .array([
          .dictionary([
            "UTTypeIdentifier": .string("org.racket-lang.racket-source"),
            "UTTypeDescription": .string("Racket Source File"),
            "UTTypeConformsTo": .array([
              .string("public.source-code")
            ]),
            "UTTypeTagSpecification": .dictionary([
              "public.filename-extension": .array([
                .string("rkt")
              ])
            ])
          ])
        ])
      ]),
      sources: ["Ruckus/**"],
      resources: [
        .folderReference(path: "Ruckus/racket"),
        .folderReference(path: "Ruckus/res"),
        .glob(pattern: "vendor/tree-sitter-racket/queries/highlights.scm")
      ],
      scripts: [
        .pre(
          script: "make -C \"${SRCROOT}\"",
          name: "Build Racket Core",
          basedOnDependencyAnalysis: false
        ),
        .pre(
          script: "swiftlint lint --quiet",
          name: "SwiftLint",
          basedOnDependencyAnalysis: false
        )
      ],
      dependencies: [
        .external(name: "NoiseBackend"),
        .external(name: "NoiseSerde"),
        .external(name: "Noise"),
        .external(name: "OpenSSL"),
        .external(name: "Runestone"),
        .target(name: "TreeSitterRacket")
      ],
      settings: .settings(
        configurations: [
          .debug(name: "Debug", xcconfig: "./xcconfigs/Ruckus.xcconfig"),
          .release(name: "Release", xcconfig: "./xcconfigs/Ruckus.xcconfig")
        ]
      )
    ),
    .target(
      name: "RuckusTests",
      destinations: .iOS,
      product: .unitTests,
      bundleId: "io.defn.RuckusTests",
      sources: ["RuckusTests/**"],
      dependencies: [
        .target(name: "Ruckus"),
        .external(name: "Semaphore")
      ]
    ),
    .target(
      name: "TreeSitterRacket",
      destinations: .iOS,
      product: .staticLibrary,
      bundleId: "io.defn.TreeSitterRacket",
      sources: ["vendor/tree-sitter-racket/src/**"],
      headers: .headers(public: ["vendor/tree-sitter-racket/bindings/swift/**"]),
      settings: .settings(base: [
        "HEADER_SEARCH_PATHS": "$(SRCROOT)/vendor/tree-sitter-racket/src",
        "MODULEMAP_FILE": "$(SRCROOT)/vendor/tree-sitter-racket.modulemap"
      ])
    )
  ],
  schemes: [
    .scheme(
      name: "Ruckus",
      buildAction: .buildAction(targets: ["Ruckus"]),
      testAction: .targets(["RuckusTests"]),
      runAction: .runAction(executable: "Ruckus")
    )
  ]
)
