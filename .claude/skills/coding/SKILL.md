---
description: |
  General coding style preferences. Always active when writing or modifying code.
  When writing or modifying Racket code, also load the racket-coding skill.
  When writing or modifying Swift code, also load the swift-coding skill.
---

# Coding Style

- Only write comments when they are absolutely necessary to explain a concept
  or a behavior, not for things that you can read the code and understand.
- It's OK to use empty lines to separate logical blocks of code, but
  avoid unnecessary empty lines otherwise.
- Simplify boolean expressions, avoid pleonasms like
  `#expect(expression == true)` or `#expect(expression == false)`.
