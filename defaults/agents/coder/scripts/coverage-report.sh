#!/bin/bash
set -euo pipefail
# Generate test coverage summary
# Usage: coverage-report.sh [path]

PATH_ARG="${1:-.}"
cd "$PATH_ARG"

echo "📊 Coverage Report"
echo "─────────────────────────────────────"

# Node.js
if [ -f "package.json" ]; then
  if grep -q "\"vitest\"" package.json 2>/dev/null; then
    echo "Runner: vitest --coverage"
    npx vitest run --coverage --reporter=verbose 2>&1 | tail -30
    exit $?
  elif grep -q "\"jest\"" package.json 2>/dev/null; then
    echo "Runner: jest --coverage"
    npx jest --coverage --coverageReporters=text 2>&1 | tail -30
    exit $?
  fi
fi

# Python
if command -v pytest &>/dev/null && ([ -f "pyproject.toml" ] || [ -d "tests" ]); then
  echo "Runner: pytest --cov"
  pytest --cov --cov-report=term-missing 2>&1 | tail -30
  exit $?
fi

# Go
if [ -f "go.mod" ]; then
  echo "Runner: go test -cover"
  go test -cover ./... 2>&1
  exit $?
fi

echo "❌ No coverage tool detected"
exit 1
