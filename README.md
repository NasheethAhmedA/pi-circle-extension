# Circle Extension

Circle is a Pi package for center-led multi-agent orchestration.

It adds a reusable structure for organizing work around:
- **circles** with a dedicated `center` coordinator
- **global agents** that can be reused across circles
- **dynamic routing** with `invoke`
- **agent-scoped skill loading** with `load_skill`
- **isolated parallel sub-agents** with `spawn`
- **layered context injection** that keeps stable circle guidance separate from active agent instructions

## Core idea

A circle is a domain-specific coordination layer.

Each circle has:
- one circle-specific `center`
- a list of referenced global agents
- optional center skills
- optional circle-shared skills
- optional circle-owned scripts

The center owns orchestration.
The specialists stay reusable.
A circle references global agents by name instead of redefining them.

This works best when ownership stays clear:
- **center skills** stay thin and orchestration-focused
- **agent-owned skills** hold the deeper operating playbooks
- **reusable specialist scripts** live with the owning agent
- **circle-specific scripts** stay with the owning circle

## Why the package includes default circles

The bundled circles are examples of the model, not a fixed set you must keep.

They exist so you can:
- see the architecture working end-to-end
- start from real examples instead of a blank slate
- copy, adapt, or replace them with your own circles

One of those examples is [`compass-circle`](defaults/circles/compass-circle/README.md), the meta-circle for creating and refining circles and global agents for this extension model.

## Install

From GitHub:

```bash
pi install git:github.com/NasheethAhmedA/pi-circle-extension
```

From a local checkout:

```bash
pi install /absolute/path/to/pi-circle-extension
```

## Basic usage

### Activate a circle

```bash
/circle
```

Activates a circle interactively.
You can also activate one directly by name:

```bash
/circle compass-circle
```

### List available circles

```bash
/circle-list
```

Shows the circles currently available through project overrides, user overrides, and bundled defaults.

### Deactivate the current circle or point session

```bash
/circle-off
```

Returns Pi to normal mode.

### Point directly to a global agent

```bash
/circle-point
```

This starts direct 1:1 interaction with a single global agent outside circle coordination.

## Core tools

### `invoke`

Use `invoke` to switch agents or activate a circle.

Typical uses:
- switch from the center to a specialist
- return from a specialist back to `center`
- activate a circle and optionally choose its starting agent
- point to a global agent outside any circle

Examples:
- activate a circle: `invoke({ circle: "compass-circle", agent: "center" })`
- route to a specialist: `invoke({ agent: "architect" })`
- return to the coordinator: `invoke({ agent: "center" })`

### `load_skill`

Circle uses progressive skill disclosure.
The agent only sees a list of available skills by default.
When a task clearly matches a skill, load the full skill before using it.

Typical uses:
- list skills: `load_skill({ skill_name: "list" })`
- load one skill: `load_skill({ skill_name: "implementation" })`

This keeps routine requests lighter while still allowing deep operating playbooks when needed.

### `spawn`

`spawn` runs isolated parallel sub-agents.

Use it only for tasks that are truly independent.
Spawned sub-agents:
- do **not** see session history
- only know the task text you give them
- return results to the center

Typical use cases:
- parallel research
- parallel code review of separate areas
- independent read-only analysis
- safe non-overlapping write tasks when explicitly allowed

## Typical workflow

1. install the package
2. activate one of the example circles
3. let the center coordinate the work
4. use `compass-circle` to create or refine your own circles and agents
5. keep your custom work in project or user overrides
6. let bundled defaults remain as fallback examples

## Technical details

### Resolution order

Circle resolves content in this order:

1. project overrides
2. user overrides
3. bundled package defaults

That means you can install the package and use it immediately, while still overriding any part of it locally without modifying the package itself.

### Active agent model

A circle does not permanently rewrite the whole prompt around one agent.
Instead, the runtime tracks:
- the active circle
- the active agent
- optional point mode for direct global-agent interaction

The current acting agent can change during a session through `invoke`.

### Progressive skill disclosure

Agents are not injected with every full skill by default.
Instead, they receive a compact list of available skills.
When a task matches one of them, the full skill is loaded on demand with `load_skill`.

This keeps the default working context smaller and more focused while still allowing deep behavior when it is actually needed.

### Context layering

The runtime builds the request in layers:

1. stable system prompt and circle preamble
2. session history
3. active-agent capsule
4. the current live user message

The active-agent capsule contains:
- the current acting agent identity
- circle/point mode information
- the agent's `AGENT.md` or center prompt
- the active agent's available skills

Placing the active-agent capsule near the live request keeps the stable part of the prompt more reusable while keeping the most changeable agent-specific instructions close to the active turn.

### Why the extension is structured this way

The package is optimized around a few goals:
- **reusability** — specialists can be used across many circles
- **clarity** — centers coordinate, specialists specialize
- **lighter default context** — skills are loaded only when needed
- **better prompt locality** — stable circle semantics stay separate from volatile active-agent context
- **safe parallelism** — `spawn` uses isolated subprocesses instead of sharing the parent session state

## Package contents

### Runtime
- `index.ts`
- `parallel.ts`

### Bundled defaults
- `defaults/agents/`
- `defaults/circles/`
- `defaults/prompts/`
- `defaults/manifests/`
