# Minimize bundled Racket distribution

## Summary

The app ships a 383MB Racket distribution under `Ruckus/racket/` that is
assembled by `bin/prepare-distribution` via raw `rsync` copies from the PB
Racket build tree, followed by manual deletions of doc packages, test
packages, `.trash`, aarch64 libs, and `.c` files. This approach is fragile
(breaks when new unwanted files appear) and ships more content than needed.

Now that users can install packages at runtime via the package manager,
the bundled distribution should be the minimal set that `ruckus-core`
depends on. The proper way to produce a custom Racket distribution is
via [`distro-build`](https://github.com/racket/distro-build), which
handles package selection, dependency resolution, collects, docs, and
linking automatically.

## Affected Code

### `bin/prepare-distribution`

```bash
rsync -ravz --exclude '.gitignore' "$RACKET_DIR/collects" "$RUCKUS_DIR/racket/"
rsync -ravz "$RACKET_DIR/doc" "$RUCKUS_DIR/racket/"
rsync -ravz "$RACKET_DIR/man" "$RUCKUS_DIR/racket/"
rsync -ravz "$RACKET_DIR/share" "$RUCKUS_DIR/racket/"
rm -rf "$RUCKUS_DIR/racket/share/pkgs/.trash"
rm -r "$RUCKUS_DIR/racket/share/pkgs/"{*-doc,*-test}
rm -fr "$RUCKUS_DIR/racket/share/pkgs/"*-aarch64-*
racket "$HERE/clean-links.rkt" "$RUCKUS_DIR/racket/share/links.rktd"
find "$RUCKUS_DIR/racket/share" -name '*.c' -exec rm \{\} \;
```

Copies the entire PB Racket tree then manually deletes unwanted parts.
Fragile — new unwanted content (like `.trash`) causes CI failures.

### `bin/clean-links.rkt`

Filters `links.rktd` and `pkgs.rktd` to remove references to deleted
packages. This would be unnecessary if the distribution were built
correctly from the start via `distro-build`.

## Impact

- **App size**: 383MB of Racket content ships in the bundle. Much of
  this (test packages, man pages, unused packages) is unnecessary.
- **CI fragility**: Manual deletions break when upstream changes (e.g.
  `.trash` directory appearing).
- **Maintenance**: Every new unwanted file type requires a new `rm` line
  in the script.

## Suggested Fix

### Use `distro-build` to produce a proper custom distribution

Replace the ad-hoc `prepare-distribution` script with Racket's official
[`distro-build`](https://github.com/racket/distro-build) tooling.

**Step 1 — Create a site configuration.**

Write a `distro-build` config (e.g. `build/site.rkt`) that specifies
only the packages `ruckus-core` needs:

```racket
#lang distro-build/config
(machine
  #:pkgs '("ruckus-core" "ruckus-openssl")
  #:dist-name "Ruckus"
  #:dist-base "ruckus")
```

`distro-build` will resolve the transitive dependency closure
automatically, including collects, docs, and links — no manual filtering
needed.

**Step 2 — Build the distribution.**

```bash
make server PKGS="ruckus-core ruckus-openssl"
make client SERVER=localhost PKGS="ruckus-core ruckus-openssl"
```

Or for a single-machine build:

```bash
make installers CONFIG=build/site.rkt
```

This produces a self-consistent distribution in `build/installers/`
with only the packages specified and their transitive dependencies.

**Step 3 — Update CI and Makefile.**

Replace the `prepare-distribution` step in CI with the `distro-build`
workflow. The resulting distribution directory replaces the current
`Ruckus/racket/` tree.

**Step 4 — Remove `bin/prepare-distribution` and `bin/clean-links.rkt`.**

These become unnecessary since `distro-build` produces a clean
distribution without orphaned links or packages.

### What to keep

- **Docs** — keep them; they're displayed in-app via DocumentationView.
- **Collects** — keep; needed for runtime module resolution.
- **Man pages** — can be excluded (useless on iOS). Check if
  `distro-build` has an option to skip man pages, or remove them
  post-build.

### Expected size reduction

The exact reduction depends on the transitive dependency closure of
`ruckus-core`, but removing test packages, unused packages, man pages,
`.c` files, and `.trash` directories should significantly reduce the
383MB total. The key win is that `distro-build` only includes what's
needed rather than including everything and manually deleting.

## Related

- `Ruckus/Backend/RacketEnvironment.swift` — layered config for writable
  packages (users can install missing packages at runtime)
- `Ruckus/Views/Settings/PackageManagerView.swift` — package manager UI
- [distro-build documentation](https://docs.racket-lang.org/distro-build/index.html)
- [Distributing Racket Variants](https://docs.racket-lang.org/racket-build-guide/distribute.html)
