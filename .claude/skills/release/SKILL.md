---
name: release
description: |
  Prepare a release by bumping the build number, collecting user-facing
  changes into a changelog, and committing the result.
user_invocable: true
---

# Prepare Release

## Workflow

1. **Read current build number.** Parse `CURRENT_PROJECT_VERSION` from
   `xcconfigs/Ruckus.xcconfig`. Let `OLD` = that value and `NEW` = `OLD + 1`.

2. **Bump the build number.** Update `CURRENT_PROJECT_VERSION` in both:
   - `xcconfigs/Ruckus.xcconfig`
   - `xcconfigs/RuckusWidgets.xcconfig`

   Set the value to `NEW` in both files.

3. **Collect changes.** Run `git log` from the commit that last changed
   `CURRENT_PROJECT_VERSION` (i.e. the previous bump) to `HEAD`. Summarize
   user-facing changes — skip CI, refactor, and internal-only commits. Keep
   each entry to one short line.

4. **Write the changelog.** Create `doc/changelogs/<BUILD>.md` where `<BUILD>`
   is `NEW` formatted as `%05d` (e.g. build 4 → `00004`). Use this format:

   ```markdown
   # Build <NEW>
   ## Added

   - Addition one.
   - Addition two.

   ## Changed

   - Change one.
   - Change two.

   ## Fixed

   - Fix one.
   - Fix two.

   ## Removed

   - Removal one.
   - Removal two.
   ```

5. **Commit.** Stage the two xcconfig files and the new changelog, then commit
   with the message:

   ```
   release: build <NEW>
   ```
