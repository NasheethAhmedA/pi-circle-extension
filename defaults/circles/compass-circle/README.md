# Compass Circle

Compass Circle is the meta-circle for building and refining Circle-based systems.

Use it when you want to:
- create a new circle
- refine an existing circle
- create a new global agent
- refine an existing global agent

## What it is for

Compass Circle exists to help you design for the current Circle extension model.

That means it works around these rules:
- every circle has one circle-specific `center`
- circles reference reusable global agents by name
- global agents should stay generic and reusable
- centers should coordinate rather than contain all specialist logic
- center skills should stay thin and workflow-oriented
- deeper specialist behavior should live in agent-owned skills
- reusable scripts should live with the owning specialist
- circle-owned scripts should exist only when they are truly circle-specific

## Agents used by Compass Circle

| Agent | Role in this circle |
|-------|---------------------|
| visionary | explores directions, roles, and workflow options |
| architect | defines concrete structure and boundaries |
| critic | stress-tests clarity, overlap, and ownership |
| coder | writes or rewrites the actual files |

## Main workflows

| Goal | Center skill |
|------|--------------|
| Create a new circle | `new-circle` |
| Refine an existing circle | `refine-circle` |
| Create a new global agent | `new-agent` |
| Refine an existing global agent | `refine-agent` |

## Scripts

Compass Circle provides scripts that scaffold or inspect **user-owned** circles and agents.
These scripts are for creating or validating overrides under the user agent root.

| Script | Purpose |
|--------|---------|
| `create-circle.sh <name>` | scaffold a new user-owned circle |
| `create-agent.sh <name>` | scaffold a new user-owned global agent |
| `validate-circle.sh <name>` | validate a user-owned circle structure |
| `list-agents.sh` | list currently available user-owned global agents |
