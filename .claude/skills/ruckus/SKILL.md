---
name: ruckus
description: |
  Use when building, testing, or linting the Ruckus iOS app, regenerating
  the Tuist project, running tests, or adding new Swift files. Covers
  xcodebuild, tuist, make, swiftlint, and test workflows.
user_invocable: false
---

# Ruckus Build, Test, Lint & Tuist

## Build

Build from the command line:

    xcodebuild -workspace Ruckus.xcworkspace -scheme Ruckus -destination 'generic/platform=iOS' build

A pre-build script in `Project.swift` runs `make` automatically before
compiling. This regenerates `Backend.swift` and `res/core.zo` from
Racket source. No need to run `make` manually before building.

## Tests

Run tests with xcodebuild using the **workspace** (not the project):

    xcodebuild test -workspace Ruckus.xcworkspace -scheme Ruckus \
      -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

To run a specific test class:

    xcodebuild test -workspace Ruckus.xcworkspace -scheme Ruckus \
      -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
      -only-testing RuckusTests/ClassName

The workspace is required because it includes external dependencies
(Noise, Runestone, TreeSitter). The project alone can't resolve them.

## Tuist

After modifying `Project.swift`, run:

    tuist generate --no-open

When adding or removing Swift files, regenerate the project so Xcode
picks them up.

## Linting

Always run after modifying Swift files:

    swiftlint lint

Fix any violations before finishing.

## Swift Configuration

- iOS 26.0+ deployment target
- Swift 6.0 (strict concurrency by default)

## Key Files

- `Ruckus/racket` — Vendored Racket libraries and environment config for runtime execution
- `Ruckus/Backend.swift` — Auto-generated Swift RPC client (do not edit)
- `Ruckus/Backend/Backend+shared.swift` — Shared Backend singleton
- `Project.swift` — Tuist project definition
- `Tuist/Package.swift` — Swift package dependencies (Noise from `../../Noise/`, OpenSSL)
