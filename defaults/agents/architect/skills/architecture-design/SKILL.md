---
name: architecture-design
description: Design system structure, boundaries, interfaces, and trade-offs for a feature or product.
---
# Architecture Design

## When This Applies
Use for system design, feature structure, interfaces, boundaries, and architectural trade-offs.

## Process
1. Read the requirement and relevant existing structure.
2. Identify constraints, boundaries, interfaces, and major risks.
3. Propose the simplest structure that fits the problem.
4. State trade-offs, assumptions, and what could change the recommendation.
5. Return a concrete design summary, then use the `invoke` tool with `agent: "center"`.

## Anti-Patterns
- ❌ Pattern names without justification
- ❌ Redesigning what already works
- ❌ Ignoring current codebase constraints
