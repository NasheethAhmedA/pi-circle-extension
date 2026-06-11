# Compass Circle

Compass Circle is the meta-circle for building and refining Circle-based systems.

Use it when you want to:
- create a new circle
- refine an existing circle
- create a new global agent
- refine an existing global agent

## Focus

Compass Circle is specifically for designing within the current Circle extension model.

It helps you produce circles and agents that follow these rules:
- every circle has one circle-specific `center`
- circles reference reusable global agents by name
- global agents stay generic and reusable
- centers coordinate rather than contain all specialist behavior
- center skills stay thin and workflow-oriented
- deeper specialist behavior lives in agent-owned skills
- reusable scripts live with the owning specialist
- circle-owned scripts exist only when they are truly specific to that circle

## Agents used by this circle

| Agent | Role |
|-------|------|
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

Compass Circle provides scripts for creating or validating user-owned circles and agents.

| Script | Purpose |
|--------|---------|
| `create-circle.sh <name>` | scaffold a new user-owned circle |
| `create-agent.sh <name>` | scaffold a new user-owned global agent |
| `validate-circle.sh <name>` | validate a user-owned circle structure |
| `list-agents.sh` | list currently available user-owned global agents |
