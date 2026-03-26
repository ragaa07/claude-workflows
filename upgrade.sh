#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# claude-workflows upgrader
# ============================================================
# Usage:
#   bash upgrade.sh                    # Upgrade everything
#   bash upgrade.sh --type android     # Upgrade core + android rules/reviews
#   bash upgrade.sh --team android     # Also upgrade team-specific skills
#   bash upgrade.sh --with-guards      # Also upgrade guards template
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
      echo "Usage: bash upgrade.sh [--type TYPE] [--team NAME] [--with-guards]"
      exit 1
      ;;
  esac
done

# ============================================================
# Determine source and project root
# ============================================================
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  SCRIPT_DIR="$(pwd)"
fi

if [[ -f "$SCRIPT_DIR/VERSION" ]]; then
  NEW_VERSION="$(tr -d '[:space:]' < "$SCRIPT_DIR/VERSION")"
else
  echo "ERROR: VERSION file not found in $SCRIPT_DIR"
  exit 1
fi

# Validate team
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

if git rev-parse --show-toplevel &>/dev/null; then
  PROJECT_ROOT="$(git rev-parse --show-toplevel)"
else
  PROJECT_ROOT="$(pwd)"
fi

VERSION_FILE="$PROJECT_ROOT/.claude/.workflows-version"
if [[ ! -f "$VERSION_FILE" ]]; then
  echo "ERROR: No existing claude-workflows installation found."
  echo "Run install.sh first."
  exit 1
fi

CURRENT_VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"

echo "=== claude-workflows upgrade ==="
echo "Current version: ${CURRENT_VERSION}"
echo "New version:     ${NEW_VERSION}"
[[ -n "$INSTALL_TYPE" ]] && echo "Install type:    ${INSTALL_TYPE}"
[[ -n "$TEAM_NAME" ]]    && echo "Team:            ${TEAM_NAME}"
echo ""

if [[ "$CURRENT_VERSION" == "$NEW_VERSION" ]]; then
  echo "Already up to date (v${CURRENT_VERSION})."
  exit 0
fi

# ============================================================
# Helpers
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
# 1. Replace core skills (manifest-based, preserves custom skills)
# ============================================================
echo "Upgrading core skills..."
MANIFEST="$PROJECT_ROOT/.claude/.core-skills"

# Remove old core skills listed in manifest
if [[ -f "$MANIFEST" ]]; then
  while IFS= read -r skill_name; do
    [[ -z "$skill_name" || "$skill_name" == \#* ]] && continue
    if [[ -d "$PROJECT_ROOT/.claude/skills/$skill_name" ]]; then
      rm -rf "$PROJECT_ROOT/.claude/skills/$skill_name"
    fi
  done < "$MANIFEST"
fi

# Copy new core skills
CORE_SKILLS=""
if [[ -d "$SCRIPT_DIR/core/skills" ]]; then
  for skill_dir in "$SCRIPT_DIR/core/skills"/*/; do
    skill_name="$(basename "$skill_dir")"
    cp -R "$skill_dir" "$PROJECT_ROOT/.claude/skills/$skill_name"
    CORE_SKILLS="$CORE_SKILLS$skill_name\n"
  done
  echo "  Replaced core skills in .claude/skills/"
fi

# Update manifest
printf "# Core skills installed by claude-workflows v%s\n%b" "$NEW_VERSION" "$CORE_SKILLS" > "$MANIFEST"

# ============================================================
# 2. Copy team skills on top (overwrites core if same name)
# ============================================================
if [[ -n "$TEAM_NAME" ]]; then
  echo "Upgrading team skills for: $TEAM_NAME..."
  TEAM_DIR="$SCRIPT_DIR/teams/$TEAM_NAME"

  if [[ -d "$TEAM_DIR/skills" ]]; then
    for skill_dir in "$TEAM_DIR/skills"/*/; do
      skill_name="$(basename "$skill_dir")"
      cp -R "$skill_dir" "$PROJECT_ROOT/.claude/skills/$skill_name"
    done
    echo "  Updated team skills in .claude/skills/"
  fi

  if [[ -d "$TEAM_DIR/rules" ]]; then
    mkdir -p "$PROJECT_ROOT/.claude/rules"
    cp "$TEAM_DIR/rules/"* "$PROJECT_ROOT/.claude/rules/" 2>/dev/null || true
    echo "  Updated team rules"
  fi

  if [[ -d "$TEAM_DIR/reviews" ]]; then
    mkdir -p "$PROJECT_ROOT/.claude/reviews"
    cp "$TEAM_DIR/reviews/"* "$PROJECT_ROOT/.claude/reviews/" 2>/dev/null || true
    echo "  Updated team review checklists"
  fi
fi

# ============================================================
# 3. Replace templates
# ============================================================
echo "Upgrading templates..."
if [[ -d "$SCRIPT_DIR/core/templates" ]]; then
  rm -rf "$PROJECT_ROOT/.claude/templates"
  mkdir -p "$PROJECT_ROOT/.claude/templates"
  cp -R "$SCRIPT_DIR/core/templates/"* "$PROJECT_ROOT/.claude/templates/"
  echo "  Replaced .claude/templates/"
fi

# ============================================================
# 4. Upgrade language rules
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
  fi
else
  echo "Skipping language rules (no --type specified)"
fi

# ============================================================
# 5. Upgrade review checklists
# ============================================================
if [[ -n "$INSTALL_TYPE" ]]; then
  echo "Upgrading review checklists..."
  mkdir -p "$PROJECT_ROOT/.claude/reviews"
  REVIEW_LABEL="$(get_review_label "$INSTALL_TYPE")"
  if [[ -n "$REVIEW_LABEL" && -d "$SCRIPT_DIR/core/reviews" ]]; then
    if [[ "$REVIEW_LABEL" == "all" ]]; then
      cp "$SCRIPT_DIR/core/reviews/"*.md "$PROJECT_ROOT/.claude/reviews/" 2>/dev/null || true
      echo "  Updated all review checklists"
    else
      if [[ -f "$SCRIPT_DIR/core/reviews/${REVIEW_LABEL}.md" ]]; then
        cp "$SCRIPT_DIR/core/reviews/${REVIEW_LABEL}.md" "$PROJECT_ROOT/.claude/reviews/"
        echo "  Updated review checklist: ${REVIEW_LABEL}.md"
      fi
    fi
  fi
else
  echo "Skipping review checklists (no --type specified)"
fi

# ============================================================
# 6. Upgrade guards
# ============================================================
if [[ "$WITH_GUARDS" == true ]]; then
  echo "Upgrading safety guards..."
  if [[ -f "$SCRIPT_DIR/core/templates/guards.yml.tmpl" ]]; then
    cp "$SCRIPT_DIR/core/templates/guards.yml.tmpl" "$PROJECT_ROOT/.claude/guards.yml"
    echo "  Updated .claude/guards.yml"
  fi
fi

# ============================================================
# 7. Update version
# ============================================================
echo "$NEW_VERSION" > "$VERSION_FILE"

# ============================================================
# Done
# ============================================================
# ============================================================
# 8. Update .gitignore
# ============================================================
GITIGNORE="$PROJECT_ROOT/.gitignore"
add_to_gitignore() {
  local entry="$1"
  if [[ -f "$GITIGNORE" ]]; then
    if ! grep -qxF "$entry" "$GITIGNORE"; then
      echo "$entry" >> "$GITIGNORE"
    fi
  else
    echo "$entry" > "$GITIGNORE"
  fi
}
add_to_gitignore ".workflows/current-state.md"
add_to_gitignore ".workflows/history/"
add_to_gitignore ".workflows/learned/"

echo ""
echo "Preserved (not modified):"
echo "  .claude/workflows.yml"
echo "  .claude/skills/ (project-specific skills)"
[[ -z "$INSTALL_TYPE" ]] && echo "  .claude/rules/ (use --type to update)"
[[ -z "$TEAM_NAME" ]]    && echo "  .claude/skills/ team skills (use --team to update)"
[[ "$WITH_GUARDS" != true ]] && echo "  .claude/guards.yml (use --with-guards to update)"

echo ""
echo "=== Upgrade complete! ==="
echo "  ${CURRENT_VERSION} → ${NEW_VERSION}"
