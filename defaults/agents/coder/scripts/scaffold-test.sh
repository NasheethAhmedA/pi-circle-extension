#!/bin/bash
set -euo pipefail
# Create a test file mirroring source structure
# Usage: scaffold-test.sh <source-file>

SOURCE="${1:-}"

if [ -z "$SOURCE" ]; then
  echo "Usage: $(basename "$0") <source-file>"
  echo ""
  echo "Creates a test file matching the source file's location and naming."
  echo ""
  echo "Examples:"
  echo "  $(basename "$0") src/utils/parser.ts"
  echo "  $(basename "$0") lib/auth.py"
  exit 1
fi

if [ ! -f "$SOURCE" ]; then
  echo "❌ Source file not found: $SOURCE"
  exit 1
fi

echo "🧪 Scaffolding Test"
echo "─────────────────────────────────────"

# Determine test file path based on extension and project conventions
EXT="${SOURCE##*.}"
BASENAME=$(basename "$SOURCE" ".$EXT")
DIR=$(dirname "$SOURCE")

case "$EXT" in
  ts|tsx)
    # Check for __tests__ convention vs .test.ts convention
    if [ -d "__tests__" ] || find . -path "*/__tests__/*" -name "*.ts" 2>/dev/null | grep -q .; then
      TEST_DIR="${DIR}/__tests__"
      TEST_FILE="$TEST_DIR/$BASENAME.test.$EXT"
    else
      TEST_FILE="$DIR/$BASENAME.test.$EXT"
    fi
    ;;
  js|jsx)
    TEST_FILE="$DIR/$BASENAME.test.$EXT"
    ;;
  py)
    # Python: tests/ directory or test_ prefix
    if [ -d "tests" ]; then
      TEST_DIR="tests/$(echo "$DIR" | sed 's|^src/||; s|^lib/||')"
      TEST_FILE="$TEST_DIR/test_$BASENAME.py"
    else
      TEST_FILE="$DIR/test_$BASENAME.py"
    fi
    ;;
  go)
    TEST_FILE="$DIR/${BASENAME}_test.go"
    ;;
  *)
    TEST_FILE="$DIR/$BASENAME.test.$EXT"
    ;;
esac

# Create directory if needed
mkdir -p "$(dirname "$TEST_FILE")"

if [ -f "$TEST_FILE" ]; then
  echo "⚠️  Test file already exists: $TEST_FILE"
  exit 0
fi

touch "$TEST_FILE"
echo "✅ Created: $TEST_FILE"
echo "   Source:  $SOURCE"
echo ""
echo "Fill in test cases for the functions/classes in the source file."
