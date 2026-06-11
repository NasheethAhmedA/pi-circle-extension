---
name: implementation
description: Write, modify, refactor, debug, and verify code with a tool-first, verification-first workflow.
---
# Implementation

## When This Applies
Use for writing, changing, refactoring, debugging, or verifying code, including adding or improving tests.

## Process
1. Read the target file, one nearby example, and any immediate dependencies.
2. Use tools/generators/package managers before hand-writing boilerplate.
3. Make the smallest correct edits.
4. Write or improve tests when behavior or regression coverage needs proof.
5. Verify with the appropriate build, typecheck, test, or syntax command.
6. Summarize what changed, then invoke `center`.

## Tool Pattern
- `read` before `edit`
- `edit` for existing files, `write` for new files
- `bash` for generators, installs, and verification

## Anti-Patterns
- ❌ Editing without reading
- ❌ Large unrelated refactors
- ❌ Leaving broken code unverified
- ❌ Skipping tests when verification is part of the task
