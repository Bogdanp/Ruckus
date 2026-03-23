# Package management UI

## Summary

Now that writable package installation is supported via `RacketEnvironment`
(layered `config.rktd` with writable pkgs dir), users need a UI to browse,
install, and remove Racket packages. Currently the only way to manage
packages is programmatically via `(require pkg/lib)` in a script.

## Affected Code

### New files needed

- `Ruckus/Views/Settings/PackageManagerView.swift` — main package
  management screen, accessible from Settings
- `Ruckus/Models/PackageManager.swift` — model layer wrapping `pkg/lib`
  operations via Backend RPC calls

### Existing files to modify

- `Ruckus/Views/Settings/SettingsView.swift` — add navigation link to
  package manager
- `ruckus-core/main.rkt` — add RPC methods for package operations
  (list installed, search catalog, install, remove)

## Features

### Installed packages list

Show all installed packages with name and source. Use `pkg-directory`
and `installed-pkg-table` from `pkg/lib` to enumerate. Allow swiping
to remove a package (`pkg-remove`).

### Package search / install

Search the Racket package catalog (`pkg-catalog-suggestions-for-module`
or query `https://pkgs.racket-lang.org`). Show results with name and
description. Tap to install (`pkg-install` with `pkg-desc`).

### Progress and status

Package installation can take time (network download, compilation).
Show a progress indicator during install/remove operations. Display
errors inline if an operation fails.

## Suggested Approach

### Backend RPC methods

Add to `ruckus-core/main.rkt`:

- `list-installed-packages` — returns list of `(name source)` pairs
  using `installed-pkg-table`
- `install-package` — takes a package name or URL, calls `pkg-install`
  with `with-pkg-lock`, returns success/error
- `remove-package` — takes a package name, calls `pkg-remove` with
  `with-pkg-lock`, returns success/error
- `search-packages` — queries the package catalog, returns list of
  `(name description)` pairs

### Swift UI

A `PackageManagerView` with two sections:

1. **Installed** — list of installed packages with swipe-to-delete
2. **Search** — search bar + results list with install buttons

Use `AsyncButton` for install/remove actions (shows progress spinner).
Model state via an `@Observable PackageManager` class.

## Impact

Without this, users must write Racket code to manage packages, which
is not discoverable and error-prone (requires knowing `pkg/lib` API,
`with-pkg-lock`, `pkg-desc` constructor, etc.).

## Related

- `Ruckus/Backend/RacketEnvironment.swift` — writable package config
- `docs/tasks/02-writable-package-installation.md` — prerequisite (done)
- `Ruckus/Views/Settings/SettingsView.swift` — entry point for the UI
