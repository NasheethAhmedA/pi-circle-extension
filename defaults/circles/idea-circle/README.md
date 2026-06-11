# Idea Circle

A structured idea refinement circle that evolves ideas through diverse specialist perspectives.

## Architecture

- **Center** — The coordinator. Owns all idea-circle-specific logic: scripts, workflows, folder structure knowledge. Orchestrates the flow between agents.
- **Agents** — Generic specialists (visionary, critic, architect, documentor). They have no idea-circle-specific knowledge and can be reused in any circle.

## Agents

| Agent | Role | Focus |
|-------|------|-------|
| visionary | Divergent Thinker | Expands possibilities, probes assumptions, finds new angles |
| critic | Constructive Analyst | Stress-tests ideas, identifies risks, pairs problems with solutions |
| architect | System Design | Proposes buildable approaches with patterns, trade-offs, and structure |
| documentor | Documentation | Maintains /SPEC folder or idea documentation structure |

## Structure

```
circles/idea-circle/
├── center/
│   ├── AGENT.md           # Coordinator (idea-circle-specific)
│   └── skills/            # Workflow definitions (loaded as skills for center)
├── scripts/               # Shell scripts (NOT auto-loaded, called via bash by center)
├── circle.json
└── README.md
```

## Workflow

1. User presents idea → Center scaffolds and invokes visionary (expand mode)
2. Visionary expands → Center summarizes and invokes critic
3. Critic evaluates → Center summarizes and invokes architect
4. Architect proposes → Center summarizes and invokes critic (refinement mode)
5. Visionary narrows → Center records decision and reports to user

Center handles ALL script execution and documentation updates directly.

## Scripts

All in `scripts/` — called by center via full path:
```bash
bash <resolved-circle-root>/scripts/<script-name>.sh [args]
```

See center's AGENT.md for the complete script reference.
