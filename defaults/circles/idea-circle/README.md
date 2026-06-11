# Idea Circle

Idea Circle is for structured idea exploration and refinement.

Use it when you want to:
- expand an idea
- challenge assumptions
- compare directions
- shape an idea into something more buildable
- maintain idea notes and supporting context over time

## Focus

Idea Circle helps move an idea through multiple perspectives:
- exploration
- critique
- structure
- documentation

## Agents used by this circle

| Agent | Role |
|-------|------|
| visionary | expands possibilities and finds new directions |
| critic | stress-tests the idea and surfaces risks |
| architect | shapes the idea into a more concrete structure |
| documentor | maintains idea documentation and supporting artifacts |

## Typical workflow

1. the user presents an idea
2. the center routes to `visionary` for expansion
3. the center routes to `critic` for evaluation
4. the center routes to `architect` for structure
5. the center records outcomes and keeps the idea artifacts organized

## Scripts

This circle uses circle-owned scripts for idea tracking and documentation tasks.
They are called through the circle's script directory:

```bash
bash <resolved-circle-root>/scripts/<script-name>.sh [args]
```
