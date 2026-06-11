#!/bin/bash
set -euo pipefail
# Start dev server
# Usage: run-dev.sh [path]

PATH_ARG="${1:-.}"
cd "$PATH_ARG"

echo "🚀 Starting Dev Server"
echo "─────────────────────────────────────"

if [ -f "package.json" ]; then
  if grep -q "\"dev\"" package.json 2>/dev/null; then
    if [ -f "pnpm-lock.yaml" ]; then
      echo "Running: pnpm dev"
      pnpm dev
    elif [ -f "yarn.lock" ]; then
      echo "Running: yarn dev"
      yarn dev
    else
      echo "Running: npm run dev"
      npm run dev
    fi
    exit $?
  elif grep -q "\"start\"" package.json 2>/dev/null; then
    echo "Running: npm start"
    npm start
    exit $?
  fi
fi

if [ -f "manage.py" ]; then
  echo "Running: python manage.py runserver"
  python manage.py runserver
  exit $?
fi

if [ -f "go.mod" ]; then
  MAIN=$(find . -name "main.go" -not -path '*/vendor/*' | head -1)
  if [ -n "$MAIN" ]; then
    echo "Running: go run $MAIN"
    go run "$MAIN"
    exit $?
  fi
fi

echo "❌ No dev server configuration found"
exit 1
