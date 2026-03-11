# Add iCloud sync for scripts

## Summary

Scripts are stored only in the app's local sandbox. There is no
synchronization across devices. Users with multiple iOS devices must manually
transfer scripts.

## Affected Code

### `Ruckus/Models/EditorStore.swift`

All file operations go through the Racket backend's filesystem RPCs, which
operate on local sandbox paths.

### `RuckusShared/ScriptManifest.swift`

The script manifest uses local `UserDefaults` (app group) to track available
scripts.

### `Ruckus/Ruckus.entitlements`

No iCloud entitlements are currently configured.

## Impact

Users lose their work if they delete the app or switch devices. There is no
backup or sync mechanism.

## Suggested Fix

1. **iCloud Documents container** — enable the iCloud Documents capability
   and store scripts in the app's ubiquity container.
2. **NSMetadataQuery** — monitor for remote changes and update the file
   browser accordingly.
3. **Conflict resolution** — handle merge conflicts (last-write-wins is
   acceptable for scripts).
4. **Migration** — on first launch after enabling iCloud, offer to move
   existing local scripts to iCloud.
5. **Offline support** — ensure scripts remain accessible when offline (iCloud
   Documents handles this natively).
6. **Entitlements** — enable iCloud Documents in the Xcode capabilities tab,
   which configures the required entitlements automatically.
7. **Backend coordination** — the Racket backend manages files through its
   own I/O layer. iCloud may sync files underneath it (adding, removing, or
   replacing files with not-yet-downloaded placeholders). The backend needs
   to handle externally-changed files gracefully — either by re-reading on
   access or by being notified of changes via `NSMetadataQuery` events
   forwarded from the Swift side.
