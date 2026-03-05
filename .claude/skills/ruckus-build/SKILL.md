---
name: ruckus-build
description: |
  Use when building the Ruckus iOS app, running swiftlint, regenerating
  the Tuist project, or adding new Swift files. Covers xcodebuild, make,
  tuist generate, and swiftlint workflows.
user_invocable: false
---

# Ruckus Build, Lint & Tuist

## Build

Build from the command line:

    xcodebuild -workspace Ruckus.xcworkspace -scheme Ruckus -destination 'generic/platform=iOS' build

A pre-build script in `Project.swift` runs `make` automatically before
compiling. This regenerates `Backend.swift` and `res/core.zo` from
Racket source. No need to run `make` manually before building.

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

- `Ruckus/Backend.swift` — Auto-generated Swift RPC client (do not edit)
- `Ruckus/Backend/Backend+shared.swift` — Shared Backend singleton
- `Project.swift` — Tuist project definition
- `Tuist/Package.swift` — Swift package dependencies (Noise from `../../Noise/`, OpenSSL)
