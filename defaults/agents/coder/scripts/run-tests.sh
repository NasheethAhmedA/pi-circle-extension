#!/bin/bash
set -euo pipefail
# Auto-detect test runner and execute tests
# Usage: run-tests.sh [path] [filter]

PATH_ARG="${1:-.}"
FILTER="${2:-}"
cd "$PATH_ARG"

echo "🧪 Running Tests"
echo "─────────────────────────────────────"

# Node.js projects
if [ -f "package.json" ]; then
  if grep -q "\"vitest\"" package.json 2>/dev/null; then
    echo "Runner: vitest"
    if [ -n "$FILTER" ]; then
      npx vitest run --reporter=verbose "$FILTER"
    else
      npx vitest run --reporter=verbose
    fi
    exit $?
  elif grep -q "\"jest\"" package.json 2>/dev/null; then
    echo "Runner: jest"
    if [ -n "$FILTER" ]; then
      npx jest --verbose "$FILTER"
    else
      npx jest --verbose
    fi
    exit $?
  elif grep -q "\"mocha\"" package.json 2>/dev/null; then
    echo "Runner: mocha"
    npx mocha ${FILTER:+--grep "$FILTER"}
    exit $?
  elif grep -q "\"test\"" package.json 2>/dev/null; then
    echo "Runner: npm test"
    npm test
    exit $?
  fi
fi

# Python projects
if [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "pytest.ini" ] || [ -d "tests" ]; then
  if command -v pytest &>/dev/null; then
    echo "Runner: pytest"
    pytest -v ${FILTER:+-k "$FILTER"}
    exit $?
  elif command -v python &>/dev/null; then
    echo "Runner: unittest"
    python -m unittest discover ${FILTER:+-p "$FILTER"}
    exit $?
  fi
fi

# Go projects
if [ -f "go.mod" ]; then
  echo "Runner: go test"
  if [ -n "$FILTER" ]; then
    go test -v -run "$FILTER" ./...
  else
    go test -v ./...
  fi
  exit $?
fi

# Rust projects
if [ -f "Cargo.toml" ]; then
  echo "Runner: cargo test"
  cargo test ${FILTER:+-- --test-threads=1 "$FILTER"}
  exit $?
fi

echo "❌ No test runner detected"
exit 1
