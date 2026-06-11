# Circle Extension

Circle is a Pi package for center-led multi-agent orchestration.

It gives Pi a reusable structure for organizing work around:
- **circles** with a dedicated `center` coordinator
- **global agents** that can be reused across circles
- **dynamic routing** with `invoke`
- **agent-scoped skill loading** with `load_skill`
- **isolated parallel sub-agents** with `spawn`
- **layered context injection** that keeps stable circle guidance separate from the active agent context

## Core model

### 1. Circles
A circle is a coordination layer for a domain or workflow.

Each circle has:
- one circle-specific `center`
- a list of referenced global agents
- optional center skills
- optional circle-shared skills
- optional circle-owned scripts

The center is responsible for routing, coordination, and user-facing flow.

### 2. Global agents
Global agents are reusable specialists.

They are designed to stay generic so the same agent can be reused across multiple circles.
A circle references them by name instead of redefining them.

### 3. Skill ownership
Circle works best when skill ownership is clear:
- **center skills** should stay thin and orchestration-focused
- **agent-owned skills** should contain the deeper operational playbooks
- **reusable specialist scripts** should live with the owning agent
- **circle-specific scripts** should stay with the owning circle

### 4. Runtime resolution
Circle resolves content in this order:
1. project overrides
2. user overrides
3. bundled package defaults

This lets you install the package and use it immediately while still overriding any part of it locally.

## Why the package includes default circles

The bundled circles are examples of the architecture, not a fixed set you must keep forever.

They are included so you can:
- see the model working end-to-end
- start from concrete examples instead of a blank slate
- copy, adapt, or replace them with your own circles

The package is meant to be extended. The examples exist to make that easier.

## Compass Circle

`compass-circle` is the package’s meta-circle.

Its purpose is to help you:
- create new circles
- refine existing circles
- create new global agents
- refine existing global agents

It is the example circle that knows how to design for the current Circle extension model: circle-specific centers, reusable global agents, thin center skills, and agent-owned specialist behavior.

## Install

From GitHub:

```bash
pi install git:github.com/NasheethAhmedA/pi-circle-extension
```

From a local checkout:

```bash
pi install /absolute/path/to/pi-circle-extension
```

## Package contents

### Runtime
- `index.ts`
- `parallel.ts`

### Bundled defaults
- `defaults/agents/`
- `defaults/circles/`
- `defaults/prompts/`
- `defaults/manifests/`

## Package philosophy

- centers should coordinate, not do all specialist work themselves
- specialists should stay reusable across circles
- skills should be loaded only when needed
- sub-agents should be isolated when parallel work is truly independent
- defaults should be useful examples while remaining easy to override

## Typical workflow

1. install the package
2. activate one of the example circles or point to a global agent
3. use `compass-circle` to create or refine your own circles and agents
4. keep your custom work in project or user overrides
5. let bundled defaults act as fallback examples and starters
