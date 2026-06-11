#!/bin/bash
set -euo pipefail
# Run a named script from package.json or Makefile
# Usage: run-script.sh <name>

SCRIPT_NAME="${1:-}"

if [ -z "$SCRIPT_NAME" ]; then
  echo "Usage: $(basename "$0") <script-name>"
  echo ""
  echo "Available scripts:"
  if [ -f "package.json" ]; then
    echo "  (from package.json)"
    grep -A100 '"scripts"' package.json 2>/dev/null | grep -E '^\s+"' | sed 's/[",]//g' | sed 's/^/    /' | head -20
  fi
  if [ -f "Makefile" ]; then
    echo "  (from Makefile)"
    grep -E '^[a-zA-Z_-]+:' Makefile | sed 's/:.*//; s/^/    /' | head -20
  fi
  exit 1
fi

# Try package.json scripts first
if [ -f "package.json" ] && grep -q "\"$SCRIPT_NAME\"" package.json 2>/dev/null; then
  if [ -f "pnpm-lock.yaml" ]; then
    pnpm "$SCRIPT_NAME"
  elif [ -f "yarn.lock" ]; then
    yarn "$SCRIPT_NAME"
  elif [ -f "bun.lockb" ]; then
    bun run "$SCRIPT_NAME"
  else
    npm run "$SCRIPT_NAME"
  fi
  exit $?
fi

# Try Makefile targets
if [ -f "Makefile" ] && grep -q "^${SCRIPT_NAME}:" Makefile 2>/dev/null; then
  make "$SCRIPT_NAME"
  exit $?
fi

echo "❌ Script '$SCRIPT_NAME' not found in package.json or Makefile"
exit 1
