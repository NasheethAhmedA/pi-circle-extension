#!/bin/bash
set -euo pipefail
# Auto-detect build system and build
# Usage: run-build.sh [path]

PATH_ARG="${1:-.}"
cd "$PATH_ARG"

echo "🔨 Running Build"
echo "─────────────────────────────────────"

# Node.js
if [ -f "package.json" ]; then
  if grep -q "\"build\"" package.json 2>/dev/null; then
    # Detect package manager
    if [ -f "pnpm-lock.yaml" ]; then
      echo "Builder: pnpm build"
      pnpm build
    elif [ -f "yarn.lock" ]; then
      echo "Builder: yarn build"
      yarn build
    elif [ -f "bun.lockb" ]; then
      echo "Builder: bun run build"
      bun run build
    else
      echo "Builder: npm run build"
      npm run build
    fi
    exit $?
  elif [ -f "tsconfig.json" ]; then
    echo "Builder: tsc"
    npx tsc
    exit $?
  fi
fi

# Go
if [ -f "go.mod" ]; then
  echo "Builder: go build"
  go build ./...
  exit $?
fi

# Rust
if [ -f "Cargo.toml" ]; then
  echo "Builder: cargo build"
  cargo build
  exit $?
fi

# Make
if [ -f "Makefile" ]; then
  echo "Builder: make"
  make
  exit $?
fi

echo "⚠️  No build system detected"
exit 0
