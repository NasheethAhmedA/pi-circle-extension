---
name: new-agent
description: Design and create a new reusable global agent.
---
# New Agent

## Trigger
Use when a new reusable specialist is needed.

## Steps
1. Clarify the role, boundaries, and what work should belong to this agent versus the center or other agents.
2. Keep the agent globally reusable rather than circle-specific.
3. Invoke `visionary` if role options are unclear.
4. Invoke `architect` to define the concise prompt shape, skill boundaries, and any reusable scripts.
5. Invoke `critic` to check overlap and ambiguity with existing agents.
6. If helpful, scaffold the user-owned agent with `bash defaults/circles/compass-circle/scripts/create-agent.sh <name>` after adapting the command to the installed package path.
7. Invoke `coder` to write the files.
8. Summarize the final agent design.
