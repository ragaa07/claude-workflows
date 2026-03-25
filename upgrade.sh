#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# claude-workflows upgrader
# ============================================================
# Usage:
#   bash upgrade.sh                    # Upgrade everything
#   bash upgrade.sh --type android     # Upgrade core + android rules/reviews
#   bash upgrade.sh --type react       # Upgrade core + react rules/reviews
#   bash upgrade.sh --with-guards      # Also upgrade guards template
# ============================================================

# ============================================================
# Parse arguments
# ============================================================
INSTALL_TYPE=""
WITH_GUARDS=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type)
      INSTALL_TYPE="${2:-}"
      shift 2
      ;;
    --with-guards)
      WITH_GUARDS=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: bash upgrade.sh [--type android|react|python|swift|go|generic] [--with-guards]"
      exit 1
      ;;
  esac
done

# ============================================================
# Determine where the upgrade source files live
# ============================================================
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
if [[ -n "$INSTALL_TYPE" ]]; then
  echo "Install type:    ${INSTALL_TYPE}"
fi
echo ""

if [[ "$CURRENT_VERSION" == "$NEW_VERSION" ]]; then
  echo "Already up to date (v${CURRENT_VERSION})."
  exit 0
fi

# ============================================================
# Helper: map --type to language rule files
# ============================================================
get_rule_files() {
  local type="$1"
  case "$type" in
    android)  echo "kotlin.md" ;;
    react)    echo "typescript.md" ;;
    python)   echo "python.md" ;;
    swift)    echo "swift.md" ;;
    go)       echo "go.md" ;;
    generic)  echo "" ;;
    all)      echo "kotlin.md typescript.md python.md swift.md go.md" ;;
    *)        echo "" ;;
  esac
}

get_review_label() {
  local type="$1"
  case "$type" in
    android)  echo "android" ;;
    react)    echo "typescript" ;;
    python)   echo "python" ;;
    swift)    echo "swift" ;;
    go)       echo "go" ;;
    generic)  echo "" ;;
    all)      echo "all" ;;
    *)        echo "" ;;
  esac
}

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
# 3. Upgrade language rules (if --type specified)
# ============================================================
if [[ -n "$INSTALL_TYPE" ]]; then
  echo "Upgrading language rules..."
  mkdir -p "$PROJECT_ROOT/.claude/rules"

  RULE_FILES="$(get_rule_files "$INSTALL_TYPE")"

  if [[ -n "$RULE_FILES" && -d "$SCRIPT_DIR/core/rules" ]]; then
    for rule_file in $RULE_FILES; do
      if [[ -f "$SCRIPT_DIR/core/rules/$rule_file" ]]; then
        cp "$SCRIPT_DIR/core/rules/$rule_file" "$PROJECT_ROOT/.claude/rules/"
        echo "  Updated rule: $rule_file"
      fi
    done
  elif [[ -z "$RULE_FILES" ]]; then
    echo "  Skipping language rules (type: $INSTALL_TYPE)"
  fi
else
  echo "Skipping language rules (no --type specified, preserving existing)"
fi

# ============================================================
# 4. Upgrade review checklists (if --type specified)
# ============================================================
if [[ -n "$INSTALL_TYPE" ]]; then
  echo "Upgrading review checklists..."
  mkdir -p "$PROJECT_ROOT/.claude/reviews"

  REVIEW_LABEL="$(get_review_label "$INSTALL_TYPE")"

  if [[ -n "$REVIEW_LABEL" && -d "$SCRIPT_DIR/core/reviews" ]]; then
    if [[ "$REVIEW_LABEL" == "all" ]]; then
      if ls "$SCRIPT_DIR/core/reviews/"*.md &>/dev/null; then
        cp "$SCRIPT_DIR/core/reviews/"*.md "$PROJECT_ROOT/.claude/reviews/" 2>/dev/null || true
        echo "  Updated all review checklists"
      fi
    else
      if [[ -f "$SCRIPT_DIR/core/reviews/${REVIEW_LABEL}.md" ]]; then
        cp "$SCRIPT_DIR/core/reviews/${REVIEW_LABEL}.md" "$PROJECT_ROOT/.claude/reviews/"
        echo "  Updated review checklist: ${REVIEW_LABEL}.md"
      fi
    fi
  fi
else
  echo "Skipping review checklists (no --type specified, preserving existing)"
fi

# ============================================================
# 5. Upgrade guards (if --with-guards)
# ============================================================
if [[ "$WITH_GUARDS" == true ]]; then
  echo "Upgrading safety guards..."
  if [[ -f "$SCRIPT_DIR/core/templates/guards.yml.tmpl" ]]; then
    cp "$SCRIPT_DIR/core/templates/guards.yml.tmpl" "$PROJECT_ROOT/.claude/guards.yml"
    echo "  Updated .claude/guards.yml from template"
  else
    echo "  WARNING: guards.yml.tmpl not found"
  fi
fi

# ============================================================
# 6. Ensure new directories exist
# ============================================================
mkdir -p "$PROJECT_ROOT/.claude/rules"
mkdir -p "$PROJECT_ROOT/.claude/reviews"
mkdir -p "$PROJECT_ROOT/.workflows/learned"

# ============================================================
# 7. Preserve user config
# ============================================================
echo ""
echo "Preserved (not modified):"
echo "  .claude/workflows.yml"
echo "  .claude/skills/ (project skills outside _core/)"
if [[ -z "$INSTALL_TYPE" ]]; then
  echo "  .claude/rules/ (use --type to update)"
  echo "  .claude/reviews/ (use --type to update)"
fi
if [[ "$WITH_GUARDS" != true ]]; then
  echo "  .claude/guards.yml (use --with-guards to update)"
fi

# ============================================================
# 8. Update version marker
# ============================================================
echo "$NEW_VERSION" > "$VERSION_FILE"

# ============================================================
# 9. Update .gitignore for new entries
# ============================================================
GITIGNORE="$PROJECT_ROOT/.gitignore"

add_to_gitignore() {
  local entry="$1"
  if [[ -f "$GITIGNORE" ]]; then
    if ! grep -qxF "$entry" "$GITIGNORE"; then
      echo "$entry" >> "$GITIGNORE"
    fi
  fi
}

add_to_gitignore ".workflows/learned/"

# ============================================================
# Done
# ============================================================
echo ""
echo "=== Upgrade complete! ==="
echo "  ${CURRENT_VERSION} → ${NEW_VERSION}"
echo ""
echo "Review the changelog for breaking changes:"
echo "  https://github.com/4SaleTech/claude-workflows/releases/tag/v${NEW_VERSION}"
