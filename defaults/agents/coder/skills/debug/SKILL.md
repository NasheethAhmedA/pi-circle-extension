---
name: debug
description: Diagnose and fix unclear failures through reproduction, tracing, and verification.
---
# Debug

## When This Applies
Use when the cause of a failure is unclear, intermittent, or needs tracing.

## Process
1. Clarify the symptom and reproduce it when possible.
2. Trace backwards from the failure to the likely cause.
3. Add narrow diagnostics only if needed.
4. Implement the smallest correct fix.
5. Verify the original issue is resolved.
6. Return cause, fix, and confidence, then use the `invoke` tool with `agent: "center"`.

## Anti-Patterns
- ❌ Guessing without reproduction or evidence
- ❌ Leaving temporary debug code behind
- ❌ Declaring success without verification
