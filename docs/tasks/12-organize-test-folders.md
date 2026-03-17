# Organize test files into folders mirroring app structure

## Summary

All 21 test files sit flat in `RuckusTests/`. The app source is organized
into `Models/`, `Views/`, `Views/Editor/`, `Views/TabBar/`, `Themes/`,
`Languages/`, `Backend/`, `Extensions/`, and `ViewModifiers/`. The test
directory should mirror this structure so tests are easy to locate next to
the code they cover.

## Affected Code

### `RuckusTests/` (all files)

Current flat listing:

```
AsyncButtonTests.swift          → Views/
BracketHighlighterTests.swift   → Languages/
BrowserEntryTests.swift         → Views/
CodeEditingViewTests.swift      → Views/Editor/
ColorPaletteTests.swift         → Themes/
ColorThemeNameTests.swift       → Themes/
CompletionControllerTests.swift → Views/Editor/
CompletionPopoverTests.swift    → Views/Editor/
EditorAccessoryBarTests.swift   → Views/Editor/
EditorDocumentTests.swift       → Models/
EditorSettingsTests.swift       → Models/
EditorStoreTests.swift          → Models/
EditorThemeTests.swift          → Themes/
ExecutionRegistryTests.swift    → Models/
ExecutionStepTests.swift        → Backend/
FilesystemEntryTests.swift      → Backend/
HighlightControllerTests.swift  → Views/Editor/
OutputBufferTests.swift         → Models/
RacketIndenterTests.swift       → Languages/
SaveErrorTests.swift            → Models/
UIColorHexTests.swift           → Extensions/
```

## Impact

With 21 test files in a flat directory, finding the test for a given
source file requires scanning by name rather than navigating to the
matching folder. This will only get worse as more tests are added.

## Suggested Fix

Create subdirectories under `RuckusTests/` that match the app structure
and move each test file into its corresponding folder. The `Project.swift`
glob `RuckusTests/**` already recurses into subdirectories, so no project
configuration change is needed.

```
RuckusTests/
  Backend/
    ExecutionStepTests.swift
    FilesystemEntryTests.swift
  Extensions/
    UIColorHexTests.swift
  Languages/
    BracketHighlighterTests.swift
    RacketIndenterTests.swift
  Models/
    EditorDocumentTests.swift
    EditorSettingsTests.swift
    EditorStoreTests.swift
    ExecutionRegistryTests.swift
    OutputBufferTests.swift
    SaveErrorTests.swift
  Themes/
    ColorPaletteTests.swift
    ColorThemeNameTests.swift
    EditorThemeTests.swift
  Views/
    AsyncButtonTests.swift
    BrowserEntryTests.swift
    Editor/
      CodeEditingViewTests.swift
      CompletionControllerTests.swift
      CompletionPopoverTests.swift
      EditorAccessoryBarTests.swift
      HighlightControllerTests.swift
```

After moving, run `tuist generate --no-open` and verify tests still build.

## Related

- None
