---
name: add-task
description: |
  Add a new task to docs/tasks/. Use when the user wants to file a task,
  log a bug, or note a codebase issue for later. Invoked with "/add-task".
user_invocable: true
---

# Add Task

Create a new task file in `docs/tasks/`.

## Workflow

1. **Determine the next number.** List files in `docs/tasks/` and pick the
   an available two-digit number.

2. **Gather information.** The user provides a description of the issue — this
   can be brief. If necessary, read the relevant source files to fill in
   details. Ask the user for clarification only if the issue is ambiguous.

3. **Write the task file.** Create `docs/tasks/NN-slug.md` following the
   format below. The slug should be a short kebab-case summary (2-4 words).

4. **Confirm.** Tell the user the task was created and print the filename.

## Task File Format

Every task file must follow this structure:

```markdown
# Title

## Summary

One or two paragraphs describing the problem. Be specific — mention exact
symptoms, not just vague concerns.

## Affected Code

### `FileName.swift:lineRange`

<relevant code snippet>

Explain what's wrong with this code.

(Repeat for each affected location.)

## Impact

What goes wrong in practice? Under what conditions?

## Suggested Fix

Concrete fix proposal with code sketches. Include alternatives if there
are meaningful trade-offs.

## Related

- Links to related tasks, if any.
```

## Guidelines

- **Be concrete.** Include file paths, line numbers, and code snippets. The
  task will be read by an agent that needs to locate and verify the issue.
- **Keep it actionable.** Every task should describe a specific change, not a
  vague aspiration like "improve error handling".
- **One issue per task.** If there are multiple related problems, file separate
  tasks and cross-reference them.
- **Verify the issue exists.** Read the affected code before writing the task
  to make sure the problem is real and current.
