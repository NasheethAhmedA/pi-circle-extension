---
name: implementation-analysis
description: Assess an implementation or requirement in architectural terms: boundaries, interfaces, constraints, and trade-offs.
---
# Implementation Analysis

## When This Applies
Use for architecture, design, structure, interfaces, or trade-off analysis.

## Process
1. Read the requirement and the relevant existing structure.
2. Identify constraints, boundaries, interfaces, and failure risks.
3. Propose the simplest structure that fits the problem.
4. State trade-offs and what would change the recommendation.
5. Return a concrete design summary, then invoke `center`.

## Tool Pattern
- `read` relevant files first
- `bash` to inspect project structure if needed
- `write` or `edit` only when explicitly asked for design docs

## Anti-Patterns
- ❌ Pattern names without justification
- ❌ Redesigning what already works
- ❌ Ignoring constraints already in the codebase
