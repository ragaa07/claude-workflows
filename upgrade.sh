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
#   bash upgrade.sh --team android     # Also upgrade team-specific skills/rules/reviews
#   bash upgrade.sh --type android --team android  # Full android team upgrade
# ============================================================

# ============================================================
# Parse arguments
# ============================================================
INSTALL_TYPE=""
WITH_GUARDS=false
TEAM_NAME=""

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
    --team)
      TEAM_NAME="${2:-}"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: bash upgrade.sh [--type android|react|python|swift|go|generic] [--team <name>] [--with-guards]"
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

# Validate team (if specified)
if [[ -n "$TEAM_NAME" ]]; then
  TEAM_DIR="$SCRIPT_DIR/teams/$TEAM_NAME"
  if [[ ! -d "$TEAM_DIR" ]]; then
    echo "ERROR: Team '$TEAM_NAME' not found at $TEAM_DIR"
    echo "Available teams:"
    for d in "$SCRIPT_DIR/teams/"*/; do
      [[ "$(basename "$d")" == "_template" ]] && continue
      [[ -d "$d" ]] && echo "  - $(basename "$d")"
    done
    exit 1
  fi
fi

echo "=== claude-workflows upgrade ==="
echo "Current version: ${CURRENT_VERSION}"
echo "New version:     ${NEW_VERSION}"
if [[ -n "$INSTALL_TYPE" ]]; then
  echo "Install type:    ${INSTALL_TYPE}"
fi
if [[ -n "$TEAM_NAME" ]]; then
  echo "Team:            ${TEAM_NAME}"
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
    android)  echo "kotlin.md compose.md" ;;
    react)    echo "typescript.md react.md" ;;
    python)   echo "python.md" ;;
    swift)    echo "swift.md" ;;
    go)       echo "go.md" ;;
    generic)  echo "" ;;
    all)      echo "kotlin.md compose.md typescript.md react.md python.md swift.md go.md" ;;
    *)        echo "" ;;
  esac
}

get_review_label() {
  local type="$1"
  case "$type" in
    android)  echo "kotlin-checklist" ;;
    react)    echo "typescript-checklist" ;;
    python)   echo "python-checklist" ;;
    swift)    echo "swift-checklist" ;;
    go)       echo "go-checklist" ;;
    generic)  echo "general-checklist" ;;
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
# 1b. Replace team skills (if --team specified)
# ============================================================
if [[ -n "$TEAM_NAME" ]]; then
  echo "Upgrading team skills for: $TEAM_NAME..."
  TEAM_DIR="$SCRIPT_DIR/teams/$TEAM_NAME"

  if [[ -d "$TEAM_DIR/skills" ]]; then
    rm -rf "$PROJECT_ROOT/.claude/skills/_team"
    mkdir -p "$PROJECT_ROOT/.claude/skills/_team"
    cp -R "$TEAM_DIR/skills/"* "$PROJECT_ROOT/.claude/skills/_team/"
    echo "  Replaced .claude/skills/_team/"
  fi

  if [[ -d "$TEAM_DIR/rules" ]]; then
    mkdir -p "$PROJECT_ROOT/.claude/rules"
    cp "$TEAM_DIR/rules/"* "$PROJECT_ROOT/.claude/rules/" 2>/dev/null || true
    echo "  Updated team rules in .claude/rules/"
  fi

  if [[ -d "$TEAM_DIR/reviews" ]]; then
    mkdir -p "$PROJECT_ROOT/.claude/reviews"
    cp "$TEAM_DIR/reviews/"* "$PROJECT_ROOT/.claude/reviews/" 2>/dev/null || true
    echo "  Updated team review checklists in .claude/reviews/"
  fi
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
echo "  .claude/skills/ (project skills outside _core/ and _team/)"
if [[ -z "$INSTALL_TYPE" ]]; then
  echo "  .claude/rules/ (use --type to update)"
  echo "  .claude/reviews/ (use --type to update)"
fi
if [[ -z "$TEAM_NAME" ]]; then
  echo "  .claude/skills/_team/ (use --team to update)"
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
