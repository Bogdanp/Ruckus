# switchDocument selection/layout ordering

`CodeEditingView.Coordinator.switchDocument` must force layout before restoring the
saved selection.

## Why the order matters

Runestone's `TextView.selectedRange` setter forwards to
`TextInputView.selectedTextRange`. That setter does not immediately call the text
view delegate. Instead, it sets `notifyDelegateAboutSelectionChangeInLayoutSubviews`
and defers `textInputViewDidChangeSelection` until the next
`TextInputView.layoutSubviews`.

`switchDocument` used to restore the saved range and then immediately call
`textView.layoutIfNeeded()`. That forced layout flushed the deferred selection
callback for the restored caret position during the document switch itself.

When the restored caret was far outside the current viewport, the deferred
selection callback took this path inside Runestone:

1. `TextInputView.layoutSubviews` fires `delegate?.textInputViewDidChangeSelection`.
2. `TextView.textInputViewDidChangeSelection` calls `scrollLocationToVisible` for a
   caret selection.
3. `scrollLocationToVisible` asks `TextInputView` for caret geometry.
4. Caret geometry uses `CaretRectService`, `LineController`, and
   `TextInputStringTokenizer` state that depends on the target line's line fragment
   tree.

Runestone only fully typesets line fragments for the current viewport during layout.
If the restored caret is on a line that is still off-viewport, that line fragment
tree may not exist yet. In DEBUG this can crash while UIKit/Runestone asks for
selection or tokenizer geometry on that line.

## Why the new order is safe

The current order is:

1. Reset selection to location `0`.
2. `setState(...)`.
3. Clear highlights and force layout.
4. Restore the saved selection.
5. Restore the saved content offset.

The forced layout in step 3 flushes the deferred selection callback while the caret
is still at `0`, which is safe because that location is in the initial viewport.

Restoring the saved selection in step 4 only queues another deferred
selection-change callback. It is not flushed synchronously because we no longer call
`layoutIfNeeded()` after that assignment.

Restoring `contentOffset` in step 5 updates Runestone's viewport and marks layout as
needed. On the next natural layout cycle, Runestone lays out the restored viewport
first and only then delivers the deferred selection callback. At that point caret
geometry for the restored location is available.
