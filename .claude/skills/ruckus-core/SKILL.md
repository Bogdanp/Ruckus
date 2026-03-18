---
name: ruckus-core
description: |
  Use when working with the Racket backend, adding or modifying RPC methods,
  or understanding the Racket-Swift communication layer. Covers define-rpc,
  Backend.swift codegen, and the Noise RPC framework.
user-invocable: false
---

# Ruckus Core (Racket Backend)

Racket handles business logic; Swift/SwiftUI provides the iOS UI layer.
They communicate via the Noise RPC framework.

RPC methods are defined in `ruckus-core/main.rkt` using `define-rpc`.
The Makefile runs `noise-serde-codegen` to auto-generate
`Ruckus/Backend.swift` with corresponding async Swift methods. **Do not
edit Backend.swift manually** — it is regenerated from Racket source.

Flow: `ruckus-core/*.rkt` → `make` → `Backend.swift`
(auto-generated) + `res/core.zo` (bytecode)

## Adding an RPC Method

1. Add `(define-rpc (name : ReturnType) body)` in `ruckus-core/main.rkt`
2. Run `make` to regenerate `Backend.swift` and recompile bytecode
3. Call `Backend.shared.name()` from Swift

## Naming Conventions

- Racket module names should be **singular** (e.g. `example.rkt`, not `examples.rkt`).

## Key Files

- `ruckus-core/main.rkt` — Racket backend: RPC definitions and server entry point
