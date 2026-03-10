import ProjectDescription

let project = Project(
  name: "Ruckus",
  settings: .settings(
    base: [
      "SWIFT_VERSION": "6.0",
      "SWIFT_STRICT_CONCURRENCY": "complete",
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
      destinations: [.iPhone, .iPad],
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
        ]),
        "CFBundleURLTypes": .array([
          .dictionary([
            "CFBundleURLSchemes": .array([.string("ruckus")])
          ])
        ])
      ]),
      sources: ["Ruckus/**", "RuckusShared/**"],
      resources: [
        "Ruckus/Assets.xcassets",
        .folderReference(path: "Ruckus/racket"),
        .folderReference(path: "Ruckus/res"),
        .glob(pattern: "vendor/tree-sitter-racket/queries/highlights.scm"),
        .glob(pattern: "Ruckus/Generated/licenses.json")
      ],
      entitlements: .file(path: "Ruckus/Ruckus.entitlements"),
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
        .target(name: "TreeSitterRacket"),
        .target(name: "RuckusWidgets")
      ],
      settings: .settings(
        configurations: [
          .debug(name: "Debug", xcconfig: "./xcconfigs/Ruckus.xcconfig"),
          .release(name: "Release", xcconfig: "./xcconfigs/Ruckus.xcconfig")
        ]
      )
    ),
    .target(
      name: "RuckusWidgets",
      destinations: [.iPhone, .iPad],
      product: .appExtension,
      bundleId: "io.defn.Ruckus.Widgets",
      deploymentTargets: .iOS("26.0"),
      infoPlist: .extendingDefault(with: [
        "NSExtension": .dictionary([
          "NSExtensionPointIdentifier": .string("com.apple.widgetkit-extension")
        ])
      ]),
      sources: ["RuckusWidgets/**", "RuckusShared/**"],
      resources: [
        "RuckusWidgets/Assets.xcassets"
      ],
      entitlements: .file(path: "RuckusWidgets/RuckusWidgets.entitlements"),
      dependencies: [],
      settings: .settings(
        configurations: [
          .debug(name: "Debug", xcconfig: "./xcconfigs/RuckusWidgets.xcconfig"),
          .release(name: "Release", xcconfig: "./xcconfigs/RuckusWidgets.xcconfig")
        ]
      )
    ),
    .target(
      name: "RuckusTests",
      destinations: [.iPhone, .iPad],
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
      destinations: [.iPhone, .iPad],
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
