---
name: racket-docs
description: |
  Use when the user asks about Racket functions, modules, or syntax, or
  when you need to look up Racket documentation to complete a task.
user_invocable: false
---

# Reading Racket Documentation

To look up Racket documentation, use a subagent with web search:

1. Use the Agent tool with a query like "look up <topic> on docs.racket-lang.org".
2. The subagent should use WebFetch to retrieve `https://docs.racket-lang.org/search/index.html?q=<query>` and read the results.
3. Follow links to the relevant documentation page and read it with WebFetch.
4. Summarize the findings.
