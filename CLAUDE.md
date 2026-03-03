# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build

See README.md for requirements, setup, and build commands.

To build from the command line:

    xcodebuild -workspace Ruckus.xcworkspace -scheme Ruckus -destination 'generic/platform=iOS' build

A pre-build script in `Project.swift` runs `make` automatically before compiling the app. This ensures `Backend.swift` and `res/core.zo` are always regenerated from the Racket source. There is no need to run `make` manually before building in Xcode.

## Architecture

Racket handles business logic; Swift/SwiftUI provides the iOS UI layer. They communicate via the Noise RPC framework.

RPC methods are defined in `ruckus-core/main.rkt` using `define-rpc`. The Makefile runs `noise-serde-codegen` to auto-generate `Ruckus/Backend.swift` with corresponding async Swift methods. **Do not edit Backend.swift manually** — it is regenerated from Racket source.

Flow: `ruckus-core/*.rkt` → `make` → `Backend.swift` (auto-generated) + `res/core.zo` (bytecode)

### Adding an RPC Method

1. Add `(define-rpc (name : ReturnType) body)` in `ruckus-core/main.rkt`
2. Run `make` to regenerate `Backend.swift` and recompile bytecode
3. Call `Backend.shared.name()` from Swift

### Key Files

- `ruckus-core/main.rkt` — Racket backend: RPC definitions and server entry point
- `Ruckus/Backend.swift` — Auto-generated Swift RPC client (do not edit)
- `Ruckus/Backend/Backend+shared.swift` — Shared Backend singleton
- `Project.swift` — Tuist project definition
- `Tuist/Package.swift` — Swift package dependencies (Noise from `../../Noise/`, OpenSSL)

## Tuist

After modifying `Project.swift`, always run `tuist generate --no-open` to verify.

## Linting

Always run `swiftlint lint` after modifying Swift files and fix any violations before finishing.

## Swift Configuration

- iOS 26.0+ deployment target
- Swift 6.0 (strict concurrency by default)
- Default `@MainActor` isolation on all Swift code
