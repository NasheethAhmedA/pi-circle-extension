#!/bin/bash
set -euo pipefail
# List user-owned global agents that can be referenced by circles.

AGENTS_DIR="$HOME/.pi/agent/agents"
CIRCLES_DIR="$HOME/.pi/agent/circles"

echo "📋 User-owned Global Agents"
echo "─────────────────────────────────────"

if [ ! -d "$AGENTS_DIR" ]; then
  echo "No user-owned agents directory found."
  exit 0
fi

COUNT=0
for dir in "$AGENTS_DIR"/*/; do
  [ -d "$dir" ] || continue
  COUNT=$((COUNT + 1))
  name=$(basename "$dir")
  role=""
  size=0

  if [ -f "$dir/AGENT.md" ]; then
    role=$(grep "^# " "$dir/AGENT.md" | head -1 | sed 's/^# //')
    size=$(wc -c < "$dir/AGENT.md")
  fi

  skill_count=$(find "$dir/skills" -name "SKILL.md" 2>/dev/null | wc -l)
  echo "  @$name ($size B, $skill_count skill(s))"
  [ -n "$role" ] && echo "    $role"
  echo ""
done

echo "─────────────────────────────────────"
echo "Total: $COUNT agent(s)"

echo ""
echo "Referenced by user-owned circles:"
if [ -d "$CIRCLES_DIR" ]; then
  for circle in "$CIRCLES_DIR"/*/; do
    [ -f "$circle/circle.json" ] || continue
    cname=$(basename "$circle")
    agents=$(grep -oP '"agents":\s*\[\K[^]]+' "$circle/circle.json" | tr -d '"')
    echo "  $cname: ${agents:-<none>}"
  done
fi
