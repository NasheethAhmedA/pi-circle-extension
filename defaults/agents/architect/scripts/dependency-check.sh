#!/bin/bash
set -euo pipefail
# Check dependencies for outdated/vulnerable packages
# Usage: dependency-check.sh [path]

PATH_ARG="${1:-.}"
cd "$PATH_ARG"

echo "🔍 Dependency Check"
echo "─────────────────────────────────────"

if [ -f "package.json" ]; then
  echo ""
  echo "## Node.js Dependencies"
  
  if command -v npm &>/dev/null && [ -f "package-lock.json" ]; then
    echo ""
    echo "### Security Audit"
    npm audit --omit=dev 2>/dev/null || echo "  (audit failed or no lockfile)"
    echo ""
    echo "### Outdated"
    npm outdated 2>/dev/null || echo "  (all up to date)"
  elif command -v pnpm &>/dev/null && [ -f "pnpm-lock.yaml" ]; then
    echo ""
    echo "### Security Audit"
    pnpm audit 2>/dev/null || echo "  (audit failed)"
    echo ""
    echo "### Outdated"
    pnpm outdated 2>/dev/null || echo "  (all up to date)"
  else
    echo "  No lockfile found or package manager not available"
  fi
fi

if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
  echo ""
  echo "## Python Dependencies"
  
  if command -v pip &>/dev/null; then
    echo ""
    echo "### Outdated"
    pip list --outdated 2>/dev/null | head -20 || echo "  (check failed)"
  fi
  
  if command -v pip-audit &>/dev/null; then
    echo ""
    echo "### Security Audit"
    pip-audit 2>/dev/null || echo "  (pip-audit not available)"
  fi
fi

if [ -f "go.mod" ]; then
  echo ""
  echo "## Go Dependencies"
  echo ""
  echo "### Vulnerabilities"
  if command -v govulncheck &>/dev/null; then
    govulncheck ./... 2>/dev/null || echo "  (govulncheck not available)"
  else
    echo "  govulncheck not installed"
  fi
fi

echo ""
echo "─────────────────────────────────────"
echo "✅ Check complete"
