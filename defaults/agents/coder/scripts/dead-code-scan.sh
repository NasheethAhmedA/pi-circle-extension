#!/bin/bash
set -euo pipefail
# Find potentially dead/unused code
# Usage: dead-code-scan.sh [path]

PATH_ARG="${1:-.}"
cd "$PATH_ARG"

echo "🧹 Dead Code Scan"
echo "─────────────────────────────────────"

# Find exported functions/classes that may be unused
echo ""
echo "## Potentially Unused Exports"

if [ -f "tsconfig.json" ] || [ -f "package.json" ]; then
  # Find all exported names
  echo "Scanning TypeScript/JavaScript exports..."
  echo ""
  
  # Find exports and check if they're imported elsewhere
  grep -rn "^export " --include="*.ts" --include="*.js" --include="*.tsx" --include="*.jsx" \
    -not -path '*/node_modules/*' -not -path '*/dist/*' -not -path '*/.next/*' 2>/dev/null | \
  while IFS=: read -r file line content; do
    # Extract the exported name
    name=$(echo "$content" | grep -oP '(?:export (?:function|class|const|let|var|type|interface|enum) )\K\w+' 2>/dev/null || true)
    if [ -n "$name" ] && [ "$name" != "default" ]; then
      # Check if it's imported/used anywhere else
      usages=$(grep -rn "\b$name\b" --include="*.ts" --include="*.js" --include="*.tsx" --include="*.jsx" \
        -not -path '*/node_modules/*' -not -path '*/dist/*' -l 2>/dev/null | grep -v "^$file$" | wc -l)
      if [ "$usages" -eq 0 ]; then
        echo "  ⚠️  $file:$line — export '$name' (0 usages found)"
      fi
    fi
  done | head -30
fi

echo ""
echo "## Unused Dependencies"
if [ -f "package.json" ] && command -v npx &>/dev/null; then
  # Quick check: deps listed but never imported
  if command -v depcheck &>/dev/null; then
    depcheck . 2>/dev/null | head -20
  else
    echo "  (install depcheck for detailed analysis: npm i -g depcheck)"
    echo "  Quick scan:"
    # Manual check of dependencies
    grep -oP '(?<="dependencies":\s*\{)[^}]*' package.json 2>/dev/null | \
      grep -oP '"(\K[^"]+)' | while read -r dep; do
        usages=$(grep -rn "\"$dep\"\|'$dep'\|from '$dep'\|from \"$dep\"\|require('$dep')\|require(\"$dep\")" \
          --include="*.ts" --include="*.js" --include="*.tsx" --include="*.jsx" \
          -not -path '*/node_modules/*' 2>/dev/null | wc -l)
        [ "$usages" -eq 0 ] && echo "  ⚠️  $dep — never imported"
      done
  fi
fi

echo ""
echo "─────────────────────────────────────"
echo "Note: Results are heuristic. Verify before removing."
