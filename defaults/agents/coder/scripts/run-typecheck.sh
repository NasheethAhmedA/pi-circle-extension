#!/bin/bash
set -euo pipefail
# Auto-detect type checker and run
# Usage: run-typecheck.sh [path]

PATH_ARG="${1:-.}"
cd "$PATH_ARG"

echo "📐 Running Type Check"
echo "─────────────────────────────────────"

# TypeScript
if [ -f "tsconfig.json" ]; then
  echo "Checker: tsc"
  npx tsc --noEmit
  exit $?
fi

# Python (mypy)
if [ -f "pyproject.toml" ] && grep -q "mypy\|pyright" pyproject.toml 2>/dev/null; then
  if command -v mypy &>/dev/null; then
    echo "Checker: mypy"
    mypy .
    exit $?
  elif command -v pyright &>/dev/null; then
    echo "Checker: pyright"
    pyright
    exit $?
  fi
fi

# Go (built-in)
if [ -f "go.mod" ]; then
  echo "Checker: go vet"
  go vet ./...
  exit $?
fi

echo "⚠️  No type checker detected"
exit 0
