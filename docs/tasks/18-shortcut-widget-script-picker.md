# Replace path input with script picker in Shortcut and Widget

## Summary

The Apple Shortcut (`ExecuteScriptIntent`) and the home screen widget
(`SelectScriptIntent`) both require the user to type a raw file path to
select a script. This is error-prone and unfriendly -- users have to know
the exact sandbox path. Instead, both intents should present a dynamic list
of the user's saved scripts and let them pick from it.

## Affected Code

### `Ruckus/Intents/ExecuteScriptIntent.swift:8-9`

```swift
@Parameter(title: "Script Path")
var scriptPath: String
```

The shortcut intent takes a free-text `String` parameter. It should use an
`AppEntity`-backed parameter so Shortcuts shows a picker populated with
the user's scripts.

### `RuckusWidgets/SelectScriptIntent.swift:7-8`

```swift
@Parameter(title: "Script Path")
var scriptPath: String?
```

Same problem for the widget configuration intent -- the user has to type a
path instead of picking from a list.

### `Ruckus/Intents/AppShortcuts.swift:6`

```swift
intent: ExecuteScriptIntent(),
```

The shortcut phrase summary uses `\(\.$scriptPath)` which renders as a raw
path. After the migration it should display the script's display name.

## Impact

Users must manually type or paste the full sandbox path to configure the
widget or run a script via Shortcuts. Most users won't know this path,
making the feature effectively unusable without first finding the path in
the app.

## Suggested Fix

1. **Create a `ScriptEntity` conforming to `AppEntity`.** It should expose
   an `id` (the relative path) and a `displayName` (the filename without
   extension). Implement `defaultQuery` with an `EntityQuery` that calls
   `Backend.shared.getRootPath()` then `Backend.shared.listFiles(atPath:)`
   to enumerate `.rkt` files.

2. **Update `ExecuteScriptIntent`** to replace the `String` parameter with:
   ```swift
   @Parameter(title: "Script")
   var script: ScriptEntity
   ```
   Update `perform()` to resolve `script.id` back to a full path via the
   root path.

3. **Update `SelectScriptIntent`** similarly:
   ```swift
   @Parameter(title: "Script")
   var script: ScriptEntity?
   ```

4. **Update `RuckusWidgets.swift`** to use `script?.id` instead of
   `scriptPath` when loading cached output and displaying the filename.

5. **Update `AppShortcuts.swift`** parameter summary to reference the new
   `$script` parameter.

6. **Shared target:** `ScriptEntity` and its query will need access to
   `Backend` (or a lightweight file-listing helper in `RuckusShared`) so
   the widget extension can also resolve the entity query.

### Alternative

If calling `Backend` from the widget extension is too heavy, store a
manifest of script paths in the shared `UserDefaults` (the same app group
used by `ScriptOutputCache`). The main app would update this list whenever
scripts are created, deleted, or renamed. The entity query would read from
this manifest instead of hitting the backend.

## Related

- `docs/tasks/17-settings-shortcuts-link.md` -- related Shortcuts integration work
