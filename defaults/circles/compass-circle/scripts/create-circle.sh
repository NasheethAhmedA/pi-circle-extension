#!/bin/bash
set -euo pipefail
# Scaffold a new user-owned circle override.
# Usage: create-circle.sh <circle-name>

NAME="${1:-}"

if [ -z "$NAME" ]; then
  echo "Usage: $(basename "$0") <circle-name>"
  echo "Example: $(basename "$0") research-circle"
  exit 1
fi

CIRCLE_DIR="$HOME/.pi/agent/circles/$NAME"

if [ -d "$CIRCLE_DIR" ]; then
  echo "⚠️  Circle '$NAME' already exists at $CIRCLE_DIR"
  exit 0
fi

mkdir -p "$CIRCLE_DIR/center/skills"
mkdir -p "$CIRCLE_DIR/skills"
mkdir -p "$CIRCLE_DIR/scripts"

NOW="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

cat > "$CIRCLE_DIR/circle.json" << EOF
{
  "name": "$NAME",
  "description": "TODO: describe what this circle coordinates",
  "agents": [],
  "createdAt": "$NOW",
  "updatedAt": "$NOW"
}
EOF

cat > "$CIRCLE_DIR/center/AGENT.md" << EOF
# Center — ${NAME} Coordinator

You coordinate the \"${NAME}\" circle.

## Your role
- Understand the user's goal
- Route work to the right specialist with \`invoke\`
- Keep summaries short and decision-focused
- Coordinate the workflow without owning all specialist behavior
EOF

cat > "$CIRCLE_DIR/center/skills/primary-workflow.md" << EOF
---
name: primary-workflow
description: Main workflow for this circle.
---
# Primary Workflow

## Trigger
TODO: describe when this workflow applies.

## Steps
1. Clarify the user's goal.
2. Route to the right specialist.
3. Summarize the result.
EOF

cat > "$CIRCLE_DIR/README.md" << EOF
# ${NAME}

TODO: describe this circle.

## Design notes
- The center should stay circle-specific.
- Referenced global agents should stay generic and reusable.
- Center skills should stay thin and orchestration-focused.
- Deep specialist behavior should live in agent-owned skills.
- Add circle-owned scripts only when they are truly specific to this circle.
EOF

echo "✅ User-owned circle scaffolded: $CIRCLE_DIR/"
echo ""
echo "Next steps:"
echo "  1. Edit circle.json and add the referenced global agents"
echo "  2. Refine center/AGENT.md so the center is concise and circle-specific"
echo "  3. Replace center/skills/primary-workflow.md with real orchestration skills"
echo "  4. Add circle-shared skills or scripts only when they are truly circle-specific"
