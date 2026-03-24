# Minimize bundled Racket distribution

## Summary

The app ships a 383MB Racket distribution under `Ruckus/racket/` that is
assembled by `bin/prepare-distribution` via raw `rsync` copies from the PB
Racket build tree, followed by manual deletions of doc packages, test
packages, `.trash`, aarch64 libs, and `.c` files. This approach is fragile
(breaks when new unwanted files appear) and ships more content than needed.

Now that users can install packages at runtime via the package manager,
the bundled distribution should only include packages that are transitive
dependencies of `main-distribution` and `ruckus-openssl`. Packages not in
that set can be installed by the user on demand.

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
packages. Would still be needed but with a cleaner whitelist approach.

## Impact

- **App size**: 383MB of Racket content ships in the bundle. Many
  packages outside `main-distribution` + `ruckus-openssl` deps are
  unnecessary.
- **CI fragility**: Manual deletions break when upstream changes (e.g.
  `.trash` directory appearing).
- **Maintenance**: Every new unwanted file type requires a new `rm` line
  in the script.

## Suggested Fix

### Whitelist packages by dependency analysis

Instead of copying everything and blacklisting what we don't want,
compute the transitive dependency closure of `main-distribution` and
`ruckus-openssl`, then only copy those packages.

**Step 1 — Compute the needed package set.**

Write a script (e.g. `bin/compute-deps.rkt`) that uses `pkg/lib` to
resolve the transitive dependencies of `main-distribution` and
`ruckus-openssl`:

```racket
#lang racket/base
(require pkg/lib)
;; Get transitive deps of main-distribution + ruckus-openssl
;; Output the list of package names
```

Or use `raco pkg show --all` and filter by dependency chains.

**Step 2 — Update `prepare-distribution` to use a whitelist.**

```bash
# Compute needed packages
NEEDED_PKGS=$(./bin/pbracket bin/compute-deps.rkt)

# Copy collects (always needed)
rsync -ravz --exclude '.gitignore' "$RACKET_DIR/collects" "$RUCKUS_DIR/racket/"

# Copy docs (displayed in-app)
rsync -ravz "$RACKET_DIR/doc" "$RUCKUS_DIR/racket/"

# Copy only needed packages
mkdir -p "$RUCKUS_DIR/racket/share/pkgs"
for pkg in $NEEDED_PKGS; do
  rsync -raz "$RACKET_DIR/share/pkgs/$pkg" "$RUCKUS_DIR/racket/share/pkgs/"
done

# Copy share metadata (links, etc)
cp "$RACKET_DIR/share/links.rktd" "$RUCKUS_DIR/racket/share/"
cp "$RACKET_DIR/share/info-cache.rktd" "$RUCKUS_DIR/racket/share/"

# Clean links to match copied packages
racket "$HERE/clean-links.rkt" "$RUCKUS_DIR/racket/share/links.rktd"
```

**Step 3 — Drop man pages.**

Don't copy `man/` — useless on iOS.

**Step 4 — Drop `.c` files and other build artifacts.**

Still strip `.c` files from share/pkgs as a post-step, or exclude them
during the per-package rsync.

### What to keep

- **Docs** — keep; displayed in-app via DocumentationView
- **Collects** — keep; needed for runtime module resolution
- **Packages** — only transitive deps of `main-distribution` +
  `ruckus-openssl`

### What to drop

- **Man pages** — useless on iOS
- **Test packages** (`*-test`) — not needed at runtime
- **Doc packages** (`*-doc`) — docs are in `doc/`, not in these packages
- **aarch64 native packages** — not needed for PB
- **`.c` files** — build artifacts
- **`.trash`** — package manager garbage
- **Packages outside the dependency closure** — can be installed via
  the package manager at runtime

### Expected size reduction

| Component | Current | After |
|-----------|---------|-------|
| collects  | 35MB    | ~35MB (keep all) |
| doc       | 173MB   | ~173MB (keep — used in-app) |
| man       | 20KB    | 0KB (drop) |
| share/pkgs | 176MB  | ~50-80MB (only transitive deps, no -test/-doc) |
| **Total** | **383MB** | **~260-290MB** |

Further reduction could come from stripping docs for packages not used
by the app (if DocumentationView only shows specific docs).

## Related

- `Ruckus/Backend/RacketEnvironment.swift` — layered config for writable
  packages (users can install missing packages at runtime)
- `Ruckus/Views/Settings/PackageManagerView.swift` — package manager UI
