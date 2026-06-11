#!/bin/bash
set -euo pipefail
# Scaffold a new user-owned global agent.
# Usage: create-agent.sh <agent-name>

NAME="${1:-}"

if [ -z "$NAME" ]; then
  echo "Usage: $(basename "$0") <agent-name>"
  echo "Example: $(basename "$0") analyst"
  exit 1
fi

AGENT_DIR="$HOME/.pi/agent/agents/$NAME"

if [ -d "$AGENT_DIR" ]; then
  echo "⚠️  Agent '$NAME' already exists at $AGENT_DIR"
  exit 0
fi

mkdir -p "$AGENT_DIR/skills/${NAME}-core"

TITLE=$(echo "$NAME" | awk -F'-' '{for (i=1;i<=NF;i++) {$i=toupper(substr($i,1,1)) substr($i,2)}; print $0}' OFS=' ')

cat > "$AGENT_DIR/AGENT.md" << EOF
# ${TITLE} — TODO: Role Title

You are a reusable global specialist.

## Your role
- TODO: describe what this agent owns
- Keep the prompt concise
- Put deep operational method in skills
- Stay reusable across circles
EOF

cat > "$AGENT_DIR/skills/${NAME}-core/SKILL.md" << EOF
---
name: ${NAME}-core
description: Core operating workflow for ${NAME}.
---
# ${TITLE} Core

## When This Applies
TODO: describe when this skill should be used.

## Process
1. TODO: define the working process.
2. Keep steps tool-oriented and actionable.
3. Put the deep procedure here rather than in AGENT.md.

## Anti-Patterns
- TODO: define what this agent should avoid.
EOF

echo "✅ User-owned global agent scaffolded: $AGENT_DIR/"
echo ""
echo "Next steps:"
echo "  1. Refine AGENT.md so the role and boundaries are clear"
echo "  2. Replace the placeholder core skill with a real operating playbook"
echo "  3. Add more skills or reusable scripts only when they clearly belong to this agent"
