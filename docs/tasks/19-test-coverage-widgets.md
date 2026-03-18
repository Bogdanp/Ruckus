# Add tests for RuckusShared and RuckusWidgets

## Summary

The `RuckusShared` module (`ScriptManifest`, `ScriptOutputCache`) and the entire
`RuckusWidgets` extension have zero test coverage. These modules handle shared
data between the app and home screen widgets.

## Affected Code

### `RuckusShared/ScriptManifest.swift`

Script manifest serialization/deserialization — used to share script metadata
between app and widget.

### `RuckusShared/ScriptOutputCache.swift`

Output cache read/write — used to display script output on the home screen
widget.

### `RuckusWidgets/`

- `ScriptWidgetProvider.swift` — timeline generation
- `ScriptEntityQuery.swift` — entity lookup
- `ScriptOutputWidgetView.swift` — widget rendering

## Impact

Widget data sharing is a critical integration point. Bugs in manifest or cache
handling could cause widgets to show stale or incorrect data with no test to
catch it.

## Suggested Fix

Create `RuckusTests/Shared/ScriptManifestTests.swift` and
`ScriptOutputCacheTests.swift`. Test round-trip serialization, missing file
handling, and concurrent read/write scenarios. Widget view tests can be
snapshot-based or verify the timeline entry generation logic.
