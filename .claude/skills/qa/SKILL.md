---
name: qa
description: |
  Use after making changes to visually validate the app in the iOS Simulator.
  Builds, installs, launches the app, then uses screenshots and accessibility
  descriptions to verify the change looks and behaves correctly.
user_invocable: true
---

# QA — Visual Validation via iOS Simulator

Validate changes by building, installing, and inspecting the app in the
iOS Simulator using the `ios-simulator` MCP server.

## Prerequisites

The iOS Simulator must be booted before starting. Use
`mcp__ios-simulator__get_booted_sim_id` to confirm. If no simulator is
booted, use `mcp__ios-simulator__open_simulator` first.

## Workflow

1. **Regenerate the Tuist project** so the workspace reflects any file
   changes:

       tuist generate --no-open

2. **Build for simulator** using the workspace (required for
   dependency resolution):

       xcodebuild build -workspace Ruckus.xcworkspace -scheme Ruckus \
         -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

   This uses Xcode's default DerivedData location. If the build fails,
   fix the errors before continuing.

3. **Find the built `.app` bundle.** After a successful build, locate
   it in Xcode's DerivedData:

       find ~/Library/Developer/Xcode/DerivedData \
         -name "Ruckus.app" \
         -path "*/Debug-iphonesimulator/*" \
         -maxdepth 5 \
         -newer Ruckus.xcworkspace \
         2>/dev/null | head -1

   Use the most recently modified match.

4. **Install the app.**

   Use `mcp__ios-simulator__install_app` with the `.app` path found
   in the previous step.

5. **Launch the app.**

   Use `mcp__ios-simulator__launch_app` with `bundle_id: io.defn.Ruckus`
   and `terminate_running: true` to ensure a fresh start.

6. **Take a screenshot and describe the UI.**

   - Use `mcp__ios-simulator__screenshot` to capture the current state.
   - Use `mcp__ios-simulator__ui_describe_all` to get the accessibility
     tree for the visible screen.
   - Read the screenshot to visually inspect the result.

7. **Navigate to the relevant screen.** If the change is not on the
   initial screen, use taps, swipes, and text input to navigate there:
   - `mcp__ios-simulator__ui_tap` — tap coordinates
   - `mcp__ios-simulator__ui_swipe` — scroll or swipe
   - `mcp__ios-simulator__ui_type` — enter text

   After each navigation action, take another screenshot and describe
   the UI to confirm you reached the right screen.

8. **Validate the change.** Compare what you see against the expected
   behavior:
   - Does the UI reflect the change?
   - Are labels, colors, and layout correct?
   - Is the accessibility tree reasonable?

   Report your findings — what looks correct and what (if anything)
   looks wrong.

9. **If something is wrong,** describe the issue clearly. Do NOT
   attempt to fix it automatically unless the caller asks you to.

## Tips

- When you don't know the coordinates of a UI element, use
  `mcp__ios-simulator__ui_describe_all` to find it in the accessibility
  tree — elements include their frame coordinates.
- Take screenshots liberally. They are the ground truth for visual QA.
- If the app crashes on launch, check the build logs and simulator
  system log for clues.
