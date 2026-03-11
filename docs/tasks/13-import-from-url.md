# Add import from URL and GitHub Gist

## Summary

Users can only open files from the local sandbox or import via the system
share sheet. There is no way to directly import a script from a URL or GitHub
Gist.

## Affected Code

### `Ruckus/Models/EditorStore.swift:147-168`

```swift
func importFile(from url: URL) async {
  // Reads from a local file URL only
  guard let content = try? String(contentsOf: url, encoding: .utf8) else { ... }
}
```

This reads local file URLs. It does not handle `https://` URLs.

### `Ruckus/Views/ContentView.swift:96-139`

The title menu has Open and New but no "Import from URL" option.

## Impact

Users must manually copy-paste code from the web. Sharing scripts via URL
(common in the Racket community) requires extra steps.

## Suggested Fix

1. **"Import from URL" action** — add a menu item that presents a text field
   for entering a URL. Fetch the content and create a new document.
2. **GitHub Gist support** — detect Gist page URLs and resolve the raw file
   URL from GitHub's Gist API or page metadata before fetching content. Do
   not assume appending `/raw` to an arbitrary Gist URL will return the
   desired file, especially for multi-file or revision-specific Gists.
3. **URL scheme** — extend the `ruckus://` URL scheme to support
   `ruckus://open?url=https://...` for deep linking from Safari or other
   apps. Validate URLs against an allowlist of trusted hosts (e.g.
   `gist.githubusercontent.com`, `pkgs.racket-lang.org`) or prompt the user
   for confirmation before fetching to prevent abuse from malicious
   webpages.
