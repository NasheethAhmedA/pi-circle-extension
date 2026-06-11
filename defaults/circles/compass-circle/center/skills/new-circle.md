---
name: new-circle
description: Design and create a new circle for the Circle extension model.
---
# New Circle

## Trigger
Use when a new circle should be created.

## Steps
1. Clarify the domain, main workflows, and the specialist roles the circle needs.
2. Keep the center circle-specific and the specialists reusable.
3. Invoke `visionary` if roster or workflow options are unclear.
4. Invoke `architect` to define the concrete structure: center scope, referenced global agents, center skills, optional circle-shared skills, and any truly circle-owned scripts.
5. Invoke `critic` to check overlap, prompt weight, and ownership mistakes.
6. If helpful, scaffold the user-owned circle with `bash defaults/circles/compass-circle/scripts/create-circle.sh <name>` after adapting the command to the installed package path.
7. Invoke `coder` to write or finalize the files.
8. Validate the resulting circle structure and summarize the final design.
