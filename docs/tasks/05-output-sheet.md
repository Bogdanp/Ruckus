# Display output in a sheet instead of the output panel

## Summary

Script output currently appears in a fixed 150pt panel at the bottom of the
editor. This eats into editor space and cannot be resized or dismissed. Replace
it with a sheet that appears after execution finishes, can be dismissed, and
can be re-opened on demand.

## Affected Code

### `ContentView.swift:45-47`

```swift
if doc.output.length > 0 {
  OutputPanelView(text: doc.output)
}
```

The output panel is unconditionally embedded in the editor VStack whenever
there is output. It needs to be replaced with a `.sheet` presentation driven
by a `@State` boolean.

### `ContentView.swift:185-203`

The trailing toolbar currently has a Run/Stop button. A "Show Output" button
should be added here (or nearby) so the user can re-open the output sheet
after dismissing it.

### `OutputPanelView.swift:1-33`

The entire view is a bottom panel with a fixed `maxHeight: 150`. It will need
to be redesigned as a sheet-friendly view — taller, with a dismiss button or
drag-to-dismiss, and possibly a toolbar title like "Output".

## Impact

The 150pt output panel permanently reduces editor height once output exists.
Users cannot dismiss it or scroll through large output comfortably.

## Suggested Fix

1. **Add state to ContentView.** Add `@State private var showOutput = false`.

2. **Show the sheet after execution.** In `EditorStore.execute()` (or via an
   `onChange` on `doc.isEvaluating`), set `showOutput = true` when evaluation
   finishes and there is output.

3. **Present output as a sheet.** Replace the inline `OutputPanelView` embed
   with:
   ```swift
   .sheet(isPresented: $showOutput) {
     OutputSheetView(text: doc.output)
   }
   ```

4. **Build `OutputSheetView`.** Wrap the existing `OutputTextView` in a
   `NavigationStack` with a toolbar dismiss button and a title:
   ```swift
   struct OutputSheetView: View {
     let text: NSAttributedString
     @Environment(\.dismiss) private var dismiss

     var body: some View {
       NavigationStack {
         OutputTextView(text: text)
           .navigationTitle("Output")
           .navigationBarTitleDisplayMode(.inline)
           .toolbar {
             ToolbarItem(placement: .confirmationAction) {
               Button("Done") { dismiss() }
             }
           }
       }
     }
   }
   ```

5. **Add a "Show Output" toolbar button.** In the trailing toolbar, add a
   button (e.g. `terminal` SF Symbol) that sets `showOutput = true`, disabled
   when `doc.output.length == 0`.

6. **Remove the inline panel.** Delete the `if doc.output.length > 0` block
   from the VStack.

## Related

- None
