---
name: test-writing
description: Design and write tests that validate behavior and protect regressions.
---
# Test Writing

## When This Applies
Use for adding, improving, or reviewing tests.

## Process
1. Read the code under test and identify the intended behavior.
2. Choose the right test level and scope.
3. Cover key success paths, failure paths, and regressions.
4. Keep tests deterministic and readable.
5. Verify the tests.
6. Return coverage summary and gaps, then use the `invoke` tool with `agent: "center"`.

## Anti-Patterns
- ❌ Testing trivia instead of behavior
- ❌ Brittle timing-dependent tests
- ❌ Large tests with unclear purpose
