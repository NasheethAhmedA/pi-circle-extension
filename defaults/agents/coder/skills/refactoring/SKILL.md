---
name: refactoring
description: Improve structure while preserving intended behavior.
---
# Refactoring

## When This Applies
Use for structural cleanup, readability improvement, simplification, or modularization without changing intended behavior.

## Process
1. Define the exact boundary of the refactor.
2. Read the affected code and the nearby patterns.
3. Make the smallest structural improvement that solves the problem.
4. Preserve behavior and verify after the change.
5. Return what improved and what risk remains, then use the `invoke` tool with `agent: "center"`.

## Anti-Patterns
- ❌ Expanding scope mid-refactor
- ❌ Mixing refactor and unrelated feature work
- ❌ Skipping verification
