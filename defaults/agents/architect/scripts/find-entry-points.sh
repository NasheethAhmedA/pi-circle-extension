#!/bin/bash
set -euo pipefail
# Find main entry points in the project
# Usage: find-entry-points.sh [path]

PATH_ARG="${1:-.}"
cd "$PATH_ARG"

echo "🎯 Entry Points"
echo "─────────────────────────────────────"

# Package.json entry points
if [ -f "package.json" ]; then
  echo ""
  echo "## package.json"
  
  main=$(grep -o '"main":\s*"[^"]*"' package.json 2>/dev/null | cut -d'"' -f4)
  [ -n "$main" ] && echo "  main: $main"
  
  bin=$(grep -A5 '"bin"' package.json 2>/dev/null | head -6)
  [ -n "$bin" ] && echo "  bin: $bin"
  
  echo ""
  echo "  scripts:"
  grep -A50 '"scripts"' package.json 2>/dev/null | grep -E '^\s+"' | head -15 | sed 's/^/    /'
fi

# Python entry points
if [ -f "pyproject.toml" ]; then
  echo ""
  echo "## pyproject.toml"
  grep -A10 "\[project.scripts\]" pyproject.toml 2>/dev/null | head -10 | sed 's/^/  /'
  grep -A10 "\[tool.poetry.scripts\]" pyproject.toml 2>/dev/null | head -10 | sed 's/^/  /'
fi

# Go entry points
if [ -f "go.mod" ]; then
  echo ""
  echo "## Go"
  find . -name "main.go" -not -path '*/vendor/*' | sed 's/^/  /'
fi

# Common entry files
echo ""
echo "## Common Entry Files"
for f in "index.ts" "index.js" "main.ts" "main.js" "app.ts" "app.js" "server.ts" "server.js" "main.py" "app.py" "manage.py" "main.go" "Makefile" "Dockerfile"; do
  found=$(find . -maxdepth 3 -name "$f" -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null)
  [ -n "$found" ] && echo "$found" | sed 's/^/  /'
done

# API routes (if detectable)
echo ""
echo "## API Routes (detected)"
grep -rn "router\.\|app\.\(get\|post\|put\|delete\|patch\)\|@app\.\|@router\." --include="*.ts" --include="*.js" --include="*.py" -l 2>/dev/null | head -10 | sed 's/^/  /' || echo "  (none detected)"
