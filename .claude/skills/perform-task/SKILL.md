---
name: perform-task
description: |
  Perform a task from docs/tasks/. Reads the task description, verifies it
  still applies to the current code, discusses a plan with the operator, then
  implements the fix. Use when the user says "/task" followed by a task number
  or filename.
user-invocable: true
---

# Perform Task

Execute a task from the `docs/tasks/` directory.

## Workflow

1. **Identify the task.** The user provides a task number or filename
   (e.g. `/perform-task 01` or `/perform-task 04-unsanitized-filenames`).
   Find the matching file under `docs/tasks/`.

2. **Read the task description.** Read the full markdown file.

3. **Verify the issue still exists.** Read the affected source files listed in
   the task. Check whether the described problem is still present — it may have
   been fixed since the task was written. If the issue no longer applies, tell
   the operator and delete the task file.

4. **Present a plan.** Summarize what you found and propose a concrete fix.
   Include:
   - Which files will be modified
   - What the change looks like (brief code sketch)
   - Any trade-offs or alternatives from the task description
   - Whether tests need to be added or updated

   Wait for the operator to approve, adjust, or reject the plan before
   proceeding.

5. **Implement the fix.** Make the changes. Follow existing code style and
   conventions. Keep the change minimal — don't refactor surrounding code.

6. **Verify.** Run `swiftlint lint` on modified Swift files. Then **build**
   the project to catch compiler errors (access control, missing imports, etc.):

       xcodebuild build -workspace Ruckus.xcworkspace -scheme Ruckus \
         -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

   If tests are relevant (e.g. indenter changes), run the test suite too.
   Fix any issues before proceeding.

7. **QA in the simulator.** After the build succeeds, run the `/qa`
   skill to install the app in the iOS Simulator and visually validate
   that the change works as expected. If QA reveals issues, fix them
   and re-verify before proceeding.

8. **Delete the task file.** Once the fix is verified, delete the task
   markdown from `docs/tasks/`.

## If the user just says `/task` with no argument

List all task files with their titles so the operator can pick one.
Use the **Glob** tool with pattern `docs/tasks/*.md` to find task files, then
**Read** the first 2 lines of each file to extract the title. Do NOT use Bash
commands (`ls`, `head`, `for` loops, etc.) for listing — Glob and Read do not
require user approval.
