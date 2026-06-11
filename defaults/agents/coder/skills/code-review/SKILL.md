---
name: code-review
description: Review code for correctness, maintainability, consistency, and implementation risk.
---
# Code Review

## When This Applies
Use for reviewing code changes, pull requests, diffs, or implementation quality.

## Process
1. Read the changed files and surrounding context.
2. Check correctness, edge cases, consistency, and maintainability.
3. Prioritize findings into blockers, important issues, and small improvements.
4. Be concrete: point to files, lines, and failure modes.
5. Return concise findings, then use the `invoke` tool with `agent: "center"`.

## Anti-Patterns
- ❌ Vague feedback
- ❌ Pure style nitpicks with no impact
- ❌ Recommending large rewrites without necessity
