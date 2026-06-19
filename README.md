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

Circle uses progressive skill disclosure with ephemeral capsule injection.
The agent only sees a compact index of available skills by default.
When a task clearly matches a skill, the agent calls `load_skill` to activate it.

Typical uses:
- list skills: `load_skill({ skill_name: "list" })`
- load one skill: `load_skill({ skill_name: "implementation" })`

Key behaviors:
- **One skill at a time.** Only one skill can be loaded per agent at any time. Loading a new skill automatically evicts the previous one.
- **Ephemeral injection.** Loaded skill content is injected into the active-agent capsule, not stored in session history. It appears in `<loaded_skills>` within the capsule and disappears when the agent switches.
- **Per-agent isolation.** Each agent's loaded skill is cleared on `invoke`. The new agent starts with a clean skill slate.
- **User visibility.** Skill content is passed via tool result `details` so users can inspect it with `ctrl+o`, without polluting the LLM context.

This design keeps routine requests lighter while still allowing deep domain knowledge when needed.

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
Instead, they receive a compact index of available skills (name + one-line description).
When a task matches one of them, the agent calls `load_skill` to activate it.

The loaded skill content is injected ephemerally into the active-agent capsule — not stored as a tool result in session history. When a different skill is loaded, the previous one is evicted (K=1 limit). When the agent switches via `invoke`, all loaded skills are cleared.

This matters because it changes the scaling behavior:

**Standard skill loading** (tool result in history) stores the full skill content permanently. Every subsequent LLM turn pays to send it as cached-read input, even when a different agent is active. Over a multi-agent session, skill content accumulates: agent A's skills + agent B's skills + agent C's skills are all in every request. The cost grows as **O(agents² × turns × skill_size)** — quadratic in the number of agents.

**Circle's ephemeral skill loading** injects only the current agent's loaded skill into the capsule. When the agent switches, the skill disappears. No accumulation, no cross-agent pollution. The cost is **O(agents × turns × skill_size)** — linear.

The tradeoff: the capsule is at the tail of the message array, so it is uncached on every turn (unlike history-based skills which benefit from prefix caching at ~10% cost). For short sessions with few agents, history-based loading can be cheaper per-token. But for longer circle sessions with multiple agent switches — exactly the use case this extension is built for — the linear scaling wins decisively.

### Authoring agents and skills

Keep `AGENT.md` small and identity-focused: the agent's role, core rules, and behavioral guidelines. This content is always present in the capsule on every turn.

Put domain knowledge, operational playbooks, and detailed procedures into skills. Skills are loaded on demand and only one is active at a time, so they can be larger without permanently inflating the context.

This separation means:
- `AGENT.md` (~200-500 tokens): always present, defines who the agent is
- Skills (~500-2000 tokens each): loaded when needed, defines how the agent operates for a specific task type

### Context layering

The runtime builds the request in layers:

1. stable system prompt (unchanged across agent switches)
2. session history (cached by providers via prefix matching)
3. active-agent capsule (ephemeral, injected fresh each turn)
4. the current live user message

The active-agent capsule contains:
- the current acting agent identity and circle/mode metadata
- the agent's `AGENT.md` or center prompt
- `<skills_available>` index of unloaded skills
- `<loaded_skills>` with the full content of the currently loaded skill (if any)

The capsule is injected by the `context` hook via `transformContext` and is never persisted in session history. It exists only for the duration of one LLM API call. This means:
- The system prompt and session history form a stable prefix that providers can cache across turns.
- Agent switches only change the capsule at the tail — the cached prefix is unaffected.
- Loaded skill content lives in the capsule and vanishes on agent switch, preventing context accumulation.

This arrangement minimizes cache invalidation on agent switches: the entire history prefix stays cached, and only the capsule (typically 500-2000 tokens) is re-sent uncached.

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
