#!/bin/bash
set -euo pipefail
# Validate a user-owned circle override.
# Usage: validate-circle.sh <circle-name>

NAME="${1:-}"

if [ -z "$NAME" ]; then
  echo "Usage: $(basename "$0") <circle-name>"
  exit 1
fi

CIRCLE_DIR="$HOME/.pi/agent/circles/$NAME"
AGENTS_DIR="$HOME/.pi/agent/agents"
ERRORS=0
WARNINGS=0

echo "🔍 Validating user-owned circle: $NAME"
echo "─────────────────────────────────────"

if [ ! -d "$CIRCLE_DIR" ]; then
  echo "❌ Circle directory not found: $CIRCLE_DIR"
  exit 1
fi

if [ ! -f "$CIRCLE_DIR/circle.json" ]; then
  echo "❌ Missing: circle.json"
  ERRORS=$((ERRORS + 1))
else
  echo "✅ circle.json exists"
  AGENTS=$(grep -oP '"agents":\s*\[\K[^]]+' "$CIRCLE_DIR/circle.json" | tr -d '"' | tr ',' '\n' | tr -d ' ')
  if [ -z "$AGENTS" ]; then
    echo "⚠️  No referenced agents listed in circle.json yet"
    WARNINGS=$((WARNINGS + 1))
  else
    echo "   Referenced agents: $(echo $AGENTS | tr '\n' ' ')"
    for agent in $AGENTS; do
      if [ ! -f "$AGENTS_DIR/$agent/AGENT.md" ]; then
        echo "⚠️  Referenced agent '$agent' was not found in the user global agent directory"
        WARNINGS=$((WARNINGS + 1))
      else
        echo "   ✅ @$agent exists"
      fi
    done
  fi
fi

if [ ! -f "$CIRCLE_DIR/center/AGENT.md" ]; then
  echo "❌ Missing: center/AGENT.md"
  ERRORS=$((ERRORS + 1))
else
  echo "✅ center/AGENT.md exists"
fi

SKILL_COUNT=$(find "$CIRCLE_DIR/center/skills" -name "*.md" 2>/dev/null | wc -l)
if [ "$SKILL_COUNT" -eq 0 ]; then
  echo "⚠️  No center skills found in center/skills/"
  WARNINGS=$((WARNINGS + 1))
else
  echo "✅ Center skills: $SKILL_COUNT"
fi

if [ -d "$CIRCLE_DIR/scripts" ]; then
  SCRIPT_COUNT=$(find "$CIRCLE_DIR/scripts" -name "*.sh" 2>/dev/null | wc -l)
  if [ "$SCRIPT_COUNT" -gt 0 ]; then
    echo "✅ Circle-owned scripts: $SCRIPT_COUNT"
    for s in "$CIRCLE_DIR/scripts"/*.sh; do
      [ -f "$s" ] || continue
      if [ ! -x "$s" ]; then
        echo "   ⚠️  Not executable: $(basename "$s")"
        WARNINGS=$((WARNINGS + 1))
      fi
    done
  else
    echo "   (no circle-owned scripts — that is fine)"
  fi
fi

echo ""
echo "Checks to confirm manually:"
echo "  - center is circle-specific"
echo "  - referenced agents are reusable specialists"
echo "  - center skills are thin orchestration workflows"
echo "  - deep specialist behavior lives with the agents"

echo ""
echo "─────────────────────────────────────"
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  echo "✅ Circle '$NAME' looks structurally complete"
elif [ $ERRORS -eq 0 ]; then
  echo "⚠️  Circle '$NAME' is usable with $WARNINGS warning(s)"
else
  echo "❌ Circle '$NAME' has $ERRORS error(s) and $WARNINGS warning(s)"
  exit 1
fi
