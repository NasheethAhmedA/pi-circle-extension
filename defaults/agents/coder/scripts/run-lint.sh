#!/bin/bash
set -euo pipefail
# Auto-detect linter and run
# Usage: run-lint.sh [path]

PATH_ARG="${1:-.}"
cd "$PATH_ARG"

echo "🔍 Running Linter"
echo "─────────────────────────────────────"

# ESLint
if [ -f "eslint.config.js" ] || [ -f "eslint.config.mjs" ] || [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ] || [ -f ".eslintrc.yml" ]; then
  echo "Linter: eslint"
  npx eslint . ${1:+--fix}
  exit $?
fi

# Biome
if [ -f "biome.json" ] || [ -f "biome.jsonc" ]; then
  echo "Linter: biome"
  npx biome check .
  exit $?
fi

# Ruff (Python)
if [ -f "ruff.toml" ] || ([ -f "pyproject.toml" ] && grep -q "\[tool.ruff\]" pyproject.toml 2>/dev/null); then
  echo "Linter: ruff"
  ruff check .
  exit $?
fi

# Flake8 (Python fallback)
if command -v flake8 &>/dev/null && ([ -f "setup.cfg" ] || [ -f ".flake8" ]); then
  echo "Linter: flake8"
  flake8 .
  exit $?
fi

# golangci-lint (Go)
if [ -f ".golangci.yml" ] || [ -f ".golangci.yaml" ]; then
  echo "Linter: golangci-lint"
  golangci-lint run
  exit $?
fi

# Clippy (Rust)
if [ -f "Cargo.toml" ]; then
  echo "Linter: clippy"
  cargo clippy -- -W warnings
  exit $?
fi

echo "⚠️  No linter configuration detected"
echo "Hint: Set up eslint, biome, ruff, or golangci-lint"
exit 0
