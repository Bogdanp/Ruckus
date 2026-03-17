# Support Racket package installation at runtime

## Summary

The app bundles a full Racket distribution under `Ruckus/racket/` (collects,
share, pkgs, etc). On iOS, the app bundle is read-only due to sandboxing, so
`raco pkg install` (or programmatic equivalents like `pkg-install-command`)
fails because it tries to write to `share/pkgs/` and `share/links.rktd` inside
the bundle. We need to redirect writable package-installation paths to a
location outside the bundle (e.g. Application Support) while keeping the
bundled read-only distribution discoverable via search paths.

## Affected Code

### `Ruckus/racket/etc/config.rktd`

```racket
#hash((catalogs . (#f))
      (default-scope . "installation")
      (installation-name . "Ruckus"))
```

The current config sets `default-scope` to `"installation"`, which means
`raco pkg install` targets the installation-scope `pkgs-dir`. That defaults to
`share/pkgs` relative to the config dir's parent — i.e. inside the read-only
bundle. There are no `pkgs-search-dirs`, `links-search-files`, or
`share-search-dirs` entries to layer a writable directory on top.

### `Ruckus/Backend/Backend+shared.swift:10-12`

```swift
andBootArguments: .init(
  collectsDir: "../racket/collects",
  configDir: "../racket/etc"
)
```

The `configDir` boot argument points Racket at the bundled (read-only)
config directory. To support writable packages, this needs to point at a
runtime-generated config in a writable location instead.

### `Noise/Sources/Noise/Racket.swift:69-70`

```swift
if let collectsDir = ba.collectsDir { args.collects_dir = collectsDir.utf8CString.cstring() }
if let configDir = ba.configDir { args.config_dir = configDir.utf8CString.cstring() }
```

The Noise framework passes `configDir` through to Racket's `config_dir` boot
parameter — equivalent to `PLTCONFIGDIR`. No changes needed here, but it's
important context: whoever builds the config must produce an absolute path to
a writable `etc/` directory at startup.

## Impact

Users cannot install Racket packages at runtime. Any call to
`(require pkg/lib) (pkg-install ...)` or similar will fail with a filesystem
permission error when attempting to write to the bundled `share/` directory.

## Suggested Fix

### Approach: runtime-generated layered config (recommended)

Inspired by [raco-pkg-env](https://github.com/samdphillips/raco-pkg-env),
generate a `config.rktd` at app startup in a writable directory and pass that
as the `configDir` boot argument. The generated config chains back to the
bundled read-only distribution via `*-search-dirs` lists.

**Step 1 — Swift side: generate config at startup**

At launch, before creating `Backend.shared`, build a writable Racket root
directory (e.g. `<AppSupport>/racket/`) and write an `etc/config.rktd` into it.

```swift
// Paths
let bundle    = Bundle.main.resourceURL!.appendingPathComponent("racket")
let writable  = FileManager.default
    .urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    .appendingPathComponent("racket")
let writableEtc = writable.appendingPathComponent("etc")

// Ensure directories exist
try FileManager.default.createDirectory(at: writableEtc, withIntermediateDirectories: true)
for sub in ["pkgs", "share", "doc", "lib"] {
    let dir = writable.appendingPathComponent(sub)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
}
```

**Step 2 — generate config.rktd**

The key insight from Racket's [config.rktd docs](https://docs.racket-lang.org/raco/config-file.html):
in every `*-search-dirs` list, `#f` expands to the corresponding `*-dir`
value (the writable directory). Appending the bundled path after `#f` makes
the read-only distribution a fallback.

```racket
#hash(
  ;; Writable targets for installation scope:
  (pkgs-dir    . "<writable>/pkgs")
  (links-file  . "<writable>/links.rktd")
  (share-dir   . "<writable>/share")
  (doc-dir     . "<writable>/doc")
  (lib-dir     . "<writable>/lib")

  ;; Search paths: writable (#f) first, then bundled read-only:
  (pkgs-search-dirs    . (#f "<bundle>/racket/share/pkgs"))
  (links-search-files  . (#f "<bundle>/racket/share/links.rktd"))
  (share-search-dirs   . (#f "<bundle>/racket/share"))
  (collects-search-dirs . (#f "<bundle>/racket/collects"))
  (doc-search-dirs     . (#f "<bundle>/racket/doc"))
  (lib-search-dirs     . (#f "<bundle>/racket/lib"))

  ;; Package management:
  (default-scope       . "installation")
  (installation-name   . "Ruckus")
  (catalogs            . (#f))
)
```

All `<writable>` and `<bundle>` placeholders must be replaced with absolute
paths at runtime since the config directory is no longer co-located with the
bundled distribution.

**Step 3 — pass writable config to Backend**

```swift
// Backend+shared.swift
static let shared = Backend(
  withZo: Bundle.main.url(forResource: "res/core", withExtension: "zo")!,
  andMod: "main",
  andProc: "main",
  andBootArguments: .init(
    collectsDir: Bundle.main.resourceURL!
        .appendingPathComponent("racket/collects").path,
    configDir: writableEtcPath  // absolute path to writable etc/
  )
)
```

Note: `collectsDir` must also become an absolute path since it's currently
relative to the .zo file, and the config dir has moved.

**Step 4 — seed writable links.rktd**

On first launch (when `<writable>/links.rktd` doesn't exist), copy or create
an empty links file: `()`. The bundled `links.rktd` will be found via
`links-search-files` fallback, so pre-installed packages remain discoverable
without duplicating the file.

### Key config.rktd semantics (reference)

| Key | Purpose |
|-----|---------|
| `pkgs-dir` | Where installation-scope packages are installed |
| `links-file` | Collection links file for installation scope |
| `pkgs-search-dirs` | `(#f ...)` — `#f` = `pkgs-dir`, rest = fallback dirs |
| `links-search-files` | `(#f ...)` — `#f` = `links-file`, rest = fallback files |
| `collects-search-dirs` | `(#f ...)` — `#f` = main collects, rest = fallback |
| `share-dir` | Writable share directory for new package metadata |
| `share-search-dirs` | `(#f ...)` — `#f` = `share-dir`, rest = fallback |
| `default-scope` | `"installation"` routes `raco pkg install` to `pkgs-dir` |
| `catalogs` | `(#f)` = use default Racket package catalogs |

### Alternative: user scope (simpler but less control)

Instead of overriding the installation scope, switch `default-scope` to
`"user"`. User-scope packages go to
`~/Library/Racket/<installation-name>/pkgs/` which is writable inside the
iOS sandbox. The default search paths already include user-scope directories,
so no `*-search-dirs` overrides are needed. However:
- Less explicit control over where files land
- The `~/Library/Racket/` path may not exist and needs to be created
- May interact poorly with the custom `make-collects-resolver` in
  `ruckus-core/resolver.rkt` which converts `(lib ...)` paths to file paths
  via `collection-file-path` — needs testing to confirm user-scope collections
  are discoverable through the embedded resolver

## Related

- `ruckus-core/resolver.rkt` — custom module resolver that converts lib paths
  to file paths via `collection-file-path`; must be able to find packages in
  the writable directory
- `bin/prepare-distribution` — bundles the read-only distribution
- `bin/clean-links.rkt` — filters `links.rktd` to only reference existing pkgs
- [raco-pkg-env](https://github.com/samdphillips/raco-pkg-env) — reference
  implementation of the layered-config approach
- [Racket: Layered Installations](https://docs.racket-lang.org/raco/layered-install.html)
- [Racket: config.rktd reference](https://docs.racket-lang.org/raco/config-file.html)
