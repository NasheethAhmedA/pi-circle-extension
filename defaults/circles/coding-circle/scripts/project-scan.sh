#!/bin/bash
set -euo pipefail
# Scans project to detect type, languages, frameworks, and structure
# Usage: project-scan.sh [path]
# Output: JSON summary

PATH_ARG="${1:-.}"
cd "$PATH_ARG"

echo "{"

# Detect languages
LANGS=""
[ -f "package.json" ] && LANGS="${LANGS}javascript,"
[ -f "tsconfig.json" ] && LANGS="${LANGS}typescript,"
[ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "requirements.txt" ] && LANGS="${LANGS}python,"
[ -f "go.mod" ] && LANGS="${LANGS}go,"
[ -f "Cargo.toml" ] && LANGS="${LANGS}rust,"
[ -f "Gemfile" ] && LANGS="${LANGS}ruby,"
[ -f "pom.xml" ] || [ -f "build.gradle" ] && LANGS="${LANGS}java,"
LANGS="${LANGS%,}"
echo "  \"languages\": [$(echo "$LANGS" | sed 's/\([^,]*\)/"\1"/g')],"

# Detect frameworks
FRAMEWORKS=""
if [ -f "package.json" ]; then
  grep -q "\"next\"" package.json 2>/dev/null && FRAMEWORKS="${FRAMEWORKS}next.js,"
  grep -q "\"react\"" package.json 2>/dev/null && FRAMEWORKS="${FRAMEWORKS}react,"
  grep -q "\"vue\"" package.json 2>/dev/null && FRAMEWORKS="${FRAMEWORKS}vue,"
  grep -q "\"express\"" package.json 2>/dev/null && FRAMEWORKS="${FRAMEWORKS}express,"
  grep -q "\"fastify\"" package.json 2>/dev/null && FRAMEWORKS="${FRAMEWORKS}fastify,"
  grep -q "\"nest\"" package.json 2>/dev/null && FRAMEWORKS="${FRAMEWORKS}nestjs,"
  grep -q "\"svelte\"" package.json 2>/dev/null && FRAMEWORKS="${FRAMEWORKS}svelte,"
fi
[ -f "pyproject.toml" ] && grep -q "django" pyproject.toml 2>/dev/null && FRAMEWORKS="${FRAMEWORKS}django,"
[ -f "pyproject.toml" ] && grep -q "fastapi" pyproject.toml 2>/dev/null && FRAMEWORKS="${FRAMEWORKS}fastapi,"
[ -f "pyproject.toml" ] && grep -q "flask" pyproject.toml 2>/dev/null && FRAMEWORKS="${FRAMEWORKS}flask,"
FRAMEWORKS="${FRAMEWORKS%,}"
echo "  \"frameworks\": [$(echo "$FRAMEWORKS" | sed 's/\([^,]*\)/"\1"/g')],"

# Detect test framework
TEST_FW=""
if [ -f "package.json" ]; then
  grep -q "\"jest\"" package.json 2>/dev/null && TEST_FW="jest"
  grep -q "\"vitest\"" package.json 2>/dev/null && TEST_FW="vitest"
  grep -q "\"mocha\"" package.json 2>/dev/null && TEST_FW="mocha"
  grep -q "\"playwright\"" package.json 2>/dev/null && TEST_FW="${TEST_FW:+$TEST_FW,}playwright"
fi
[ -f "pyproject.toml" ] && grep -q "pytest" pyproject.toml 2>/dev/null && TEST_FW="pytest"
[ -f "go.mod" ] && TEST_FW="go-test"
echo "  \"testFramework\": \"${TEST_FW:-unknown}\","

# Detect package manager
PKG_MGR="unknown"
[ -f "pnpm-lock.yaml" ] && PKG_MGR="pnpm"
[ -f "yarn.lock" ] && PKG_MGR="yarn"
[ -f "package-lock.json" ] && PKG_MGR="npm"
[ -f "bun.lockb" ] && PKG_MGR="bun"
[ -f "Pipfile.lock" ] && PKG_MGR="pipenv"
[ -f "poetry.lock" ] && PKG_MGR="poetry"
[ -f "uv.lock" ] && PKG_MGR="uv"
echo "  \"packageManager\": \"$PKG_MGR\","

# Detect linter
LINTER=""
[ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ] || [ -f "eslint.config.js" ] || [ -f "eslint.config.mjs" ] && LINTER="eslint"
[ -f "biome.json" ] && LINTER="biome"
[ -f "ruff.toml" ] || ([ -f "pyproject.toml" ] && grep -q "\[tool.ruff\]" pyproject.toml 2>/dev/null) && LINTER="ruff"
[ -f ".golangci.yml" ] && LINTER="golangci-lint"
echo "  \"linter\": \"${LINTER:-none}\","

# File counts
echo "  \"fileCount\": $(find . -type f -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/dist/*' -not -path '*/__pycache__/*' | wc -l),"
echo "  \"hasTests\": $([ -d "tests" ] || [ -d "test" ] || [ -d "__tests__" ] || find . -name "*.test.*" -not -path '*/node_modules/*' 2>/dev/null | grep -q . && echo "true" || echo "false"),"
echo "  \"hasGit\": $([ -d ".git" ] && echo "true" || echo "false"),"
echo "  \"hasCi\": $([ -d ".github/workflows" ] || [ -f ".gitlab-ci.yml" ] || [ -f "Jenkinsfile" ] && echo "true" || echo "false")"

echo "}"
