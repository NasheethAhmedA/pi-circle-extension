#!/bin/bash
set -euo pipefail
# Scaffold a new module with standard structure
# Usage: scaffold-module.sh <name> <type>
# Types: component, service, util, route, model

NAME="${1:-}"
TYPE="${2:-}"

if [ -z "$NAME" ] || [ -z "$TYPE" ]; then
  echo "Usage: $(basename "$0") <name> <type>"
  echo ""
  echo "Types: component, service, util, route, model"
  echo ""
  echo "Examples:"
  echo "  $(basename "$0") UserProfile component"
  echo "  $(basename "$0") auth service"
  echo "  $(basename "$0") payment model"
  exit 1
fi

echo "🏗️  Scaffolding: $NAME ($TYPE)"
echo "─────────────────────────────────────"

# Detect project type
if [ -f "tsconfig.json" ] || [ -f "package.json" ]; then
  EXT="ts"
  TEST_EXT="test.ts"
elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
  EXT="py"
  TEST_EXT="test.py"
elif [ -f "go.mod" ]; then
  EXT="go"
  TEST_EXT="test.go"
else
  EXT="ts"
  TEST_EXT="test.ts"
fi

# Create based on type
case "$TYPE" in
  component)
    DIR="src/components/$NAME"
    mkdir -p "$DIR"
    touch "$DIR/$NAME.$EXT"
    touch "$DIR/$NAME.$TEST_EXT"
    touch "$DIR/index.$EXT"
    echo "  Created: $DIR/"
    ;;
  service)
    DIR="src/services"
    mkdir -p "$DIR"
    touch "$DIR/$NAME.$EXT"
    touch "$DIR/$NAME.$TEST_EXT"
    echo "  Created: $DIR/$NAME.$EXT"
    ;;
  util)
    DIR="src/utils"
    mkdir -p "$DIR"
    touch "$DIR/$NAME.$EXT"
    touch "$DIR/$NAME.$TEST_EXT"
    echo "  Created: $DIR/$NAME.$EXT"
    ;;
  route)
    DIR="src/routes"
    mkdir -p "$DIR"
    touch "$DIR/$NAME.$EXT"
    touch "$DIR/$NAME.$TEST_EXT"
    echo "  Created: $DIR/$NAME.$EXT"
    ;;
  model)
    DIR="src/models"
    mkdir -p "$DIR"
    touch "$DIR/$NAME.$EXT"
    touch "$DIR/$NAME.$TEST_EXT"
    echo "  Created: $DIR/$NAME.$EXT"
    ;;
  *)
    echo "❌ Unknown type: $TYPE"
    echo "Valid: component, service, util, route, model"
    exit 1
    ;;
esac

echo ""
echo "✅ Module scaffolded. Fill in the implementation."
