#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# claude-workflows upgrader
# ============================================================

# Determine where the upgrade source files live
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  SCRIPT_DIR="$(pwd)"
fi

# Read new version
if [[ -f "$SCRIPT_DIR/VERSION" ]]; then
  NEW_VERSION="$(cat "$SCRIPT_DIR/VERSION" | tr -d '[:space:]')"
else
  echo "ERROR: VERSION file not found in $SCRIPT_DIR"
  echo "Please run this script from the claude-workflows repository root."
  exit 1
fi

# Detect project root
if git rev-parse --show-toplevel &>/dev/null; then
  PROJECT_ROOT="$(git rev-parse --show-toplevel)"
else
  PROJECT_ROOT="$(pwd)"
fi

# ============================================================
# Check existing installation
# ============================================================
VERSION_FILE="$PROJECT_ROOT/.claude/.workflows-version"

if [[ ! -f "$VERSION_FILE" ]]; then
  echo "ERROR: No existing claude-workflows installation found."
  echo "  Expected version file at: $VERSION_FILE"
  echo ""
  echo "Run install.sh first to set up claude-workflows."
  exit 1
fi

CURRENT_VERSION="$(cat "$VERSION_FILE" | tr -d '[:space:]')"

echo "=== claude-workflows upgrade ==="
echo "Current version: ${CURRENT_VERSION}"
echo "New version:     ${NEW_VERSION}"
echo ""

if [[ "$CURRENT_VERSION" == "$NEW_VERSION" ]]; then
  echo "Already up to date (v${CURRENT_VERSION})."
  exit 0
fi

# ============================================================
# 1. Replace core skills entirely
# ============================================================
echo "Upgrading core skills..."

if [[ -d "$SCRIPT_DIR/core/skills" ]]; then
  # Remove old core skills and replace
  rm -rf "$PROJECT_ROOT/.claude/skills/_core"
  mkdir -p "$PROJECT_ROOT/.claude/skills/_core"
  cp -R "$SCRIPT_DIR/core/skills/"* "$PROJECT_ROOT/.claude/skills/_core/" 2>/dev/null || true
  echo "  Replaced .claude/skills/_core/"
else
  echo "  WARNING: No core skills found at $SCRIPT_DIR/core/skills/"
fi

# ============================================================
# 2. Replace templates entirely
# ============================================================
echo "Upgrading templates..."

if [[ -d "$SCRIPT_DIR/core/templates" ]]; then
  rm -rf "$PROJECT_ROOT/.claude/templates"
  mkdir -p "$PROJECT_ROOT/.claude/templates"
  cp -R "$SCRIPT_DIR/core/templates/"* "$PROJECT_ROOT/.claude/templates/" 2>/dev/null || true
  echo "  Replaced .claude/templates/"
else
  echo "  WARNING: No templates found at $SCRIPT_DIR/core/templates/"
fi

# ============================================================
# 3. Preserve user config
# ============================================================
echo ""
echo "Preserved (not modified):"
echo "  .claude/workflows.yml"
echo "  .claude/skills/ (project skills outside _core/)"

# ============================================================
# 4. Update version marker
# ============================================================
echo "$NEW_VERSION" > "$VERSION_FILE"

# ============================================================
# Done
# ============================================================
echo ""
echo "=== Upgrade complete! ==="
echo "  ${CURRENT_VERSION} → ${NEW_VERSION}"
echo ""
echo "Review the changelog for breaking changes:"
echo "  https://github.com/4SaleTech/claude-workflows/releases/tag/v${NEW_VERSION}"
