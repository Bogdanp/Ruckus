# Settings Page

## Summary

Ruckus has no settings or about page. Add a settings page presented as a
NavigationStack, accessible via a gear icon in the toolbar. The page should
display a list of sub-pages (starting with an About page), a "Rate Ruckus"
button, and the app version number at the bottom.

The About page should show app information and open-source licenses for all
bundled dependencies. A new `bin/collect-licenses` script should automate
gathering license texts into a format the app can bundle at build time.

## Affected Code

### `Ruckus/Views/ContentView.swift:146-155`

```swift
@ToolbarContentBuilder
private func leadingToolbar() -> some ToolbarContent {
  ToolbarItem(placement: .topBarLeading) {
    Button {
      showFileBrowser = true
    } label: {
      Image(systemName: "folder")
    }
  }
}
```

The leading toolbar currently only has the folder button. A gear icon for
settings should be added here (or as a separate toolbar item).

## Scope

### 1. Settings page (`SettingsView.swift`)

- Presented via a `NavigationStack` inside a sheet (triggered by a gear icon
  in the toolbar).
- Contains a `List` with:
  - A "Rate Ruckus" button that opens the App Store review prompt
    (`SKStoreReviewController.requestReview` or the App Store URL).
  - An "About" navigation link leading to `AboutView`.
- Displays the app version (`CFBundleShortVersionString`) and build number at
  the bottom of the list as a footer.

### 2. About page (`AboutView.swift`)

- Shows app name, icon, and version.
- Lists open-source licenses in a scrollable view. License data is read from
  a bundled JSON file generated at build time (stored in `Generated/`, not
  `Resources/`, to avoid code-signing issues).

### 3. License collection script (`bin/collect-licenses`)

- A shell script that scans dependency directories (e.g. `vendor/`,
  `Tuist/Dependencies/`, Swift package checkouts) for LICENSE files.
- Outputs a JSON file (e.g. `Ruckus/Generated/licenses.json`) with an array
  of `{ "name": "...", "text": "..." }` entries. Avoid `Resources/` to
  prevent code-signing issues -- use a generated-code directory instead.
- Should be run as part of the build or release process (document in
  Makefile or as a Tuist build phase).

### 4. Toolbar wiring (`ContentView.swift`)

- Add `@State private var showSettings = false` to `ContentView`.
- Add a gear icon `ToolbarItem` to the leading toolbar.
- Present `SettingsView` in a `.sheet(isPresented: $showSettings)`.

## Impact

Users currently have no way to see app version info, view licenses, or rate
the app from within Ruckus.

## Suggested Fix

**ContentView.swift** -- add settings state and toolbar item:

```swift
@State private var showSettings = false

// In leadingToolbar():
ToolbarItem(placement: .topBarLeading) {
  Button { showSettings = true } label: {
    Image(systemName: "gearshape")
  }
}

// Add sheet:
.sheet(isPresented: $showSettings) {
  SettingsView()
}
```

**SettingsView.swift**:

```swift
struct SettingsView: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      List {
        Section {
          Button("Rate Ruckus") { /* requestReview or open App Store URL */ }
          NavigationLink("About") { AboutView() }
        }
      }
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { dismiss() }
        }
      }
      .safeAreaInset(edge: .bottom) {
        Text("Version \(appVersion)")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
  }

  private var appVersion: String {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
    return "\(version) (\(build))"
  }
}
```

**bin/collect-licenses** (sketch):

```bash
#!/bin/bash
set -euo pipefail
OUT="Ruckus/Generated/licenses.json"
echo "[" > "$OUT"
first=true
for f in $(find vendor Tuist/Dependencies -name 'LICENSE*' 2>/dev/null); do
  name=$(basename "$(dirname "$f")")
  text=$(cat "$f" | jq -Rs .)
  if [ "$first" = true ]; then first=false; else echo "," >> "$OUT"; fi
  echo "  {\"name\": \"$name\", \"text\": $text}" >> "$OUT"
done
echo "]" >> "$OUT"
```

## Related

- None
