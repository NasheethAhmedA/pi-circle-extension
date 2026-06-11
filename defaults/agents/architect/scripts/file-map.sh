#!/bin/bash
set -euo pipefail
# Display directory tree with file types and sizes
# Usage: file-map.sh [path] [depth]

PATH_ARG="${1:-.}"
DEPTH="${2:-3}"

echo "📁 Project Structure (depth=$DEPTH)"
echo "─────────────────────────────────────"

find "$PATH_ARG" -maxdepth "$DEPTH" -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/dist/*' -not -path '*/__pycache__/*' -not -path '*/.next/*' -not -path '*/target/*' -not -path '*/.venv/*' | sort | while read -r f; do
  if [ -d "$f" ]; then
    depth=$(echo "$f" | tr -cd '/' | wc -c)
    indent=$(printf '%*s' $((depth * 2)) '')
    echo "${indent}📂 $(basename "$f")/"
  else
    depth=$(echo "$f" | tr -cd '/' | wc -c)
    indent=$(printf '%*s' $((depth * 2)) '')
    size=$(wc -c < "$f" 2>/dev/null | xargs)
    if [ "$size" -gt 1048576 ]; then
      size_fmt="$(( size / 1048576 ))MB"
    elif [ "$size" -gt 1024 ]; then
      size_fmt="$(( size / 1024 ))KB"
    else
      size_fmt="${size}B"
    fi
    echo "${indent}  $(basename "$f") ($size_fmt)"
  fi
done
