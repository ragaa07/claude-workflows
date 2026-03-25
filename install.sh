#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# claude-workflows installer
# ============================================================
# Usage:
#   bash install.sh                    # Install everything (default)
#   bash install.sh --type android     # Install core + kotlin + compose rules
#   bash install.sh --type react       # Install core + typescript + react rules
#   bash install.sh --type python      # Install core + python rules
#   bash install.sh --type swift       # Install core + swift rules
#   bash install.sh --type go          # Install core + go rules
#   bash install.sh --type generic     # Install core only, no language rules
#   bash install.sh --with-guards      # Also install safety guards
#   bash install.sh --team android     # Also install team-specific skills/rules/reviews
# ============================================================

# ============================================================
# Parse arguments
# ============================================================
INSTALL_TYPE="all"
WITH_GUARDS=false
TEAM_NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type)
      INSTALL_TYPE="${2:-all}"
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
      echo "Usage: bash install.sh [--type android|react|python|swift|go|generic] [--team <name>] [--with-guards]"
      exit 1
      ;;
  esac
done

# ============================================================
# Determine where the installer source files live
# ============================================================
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  SCRIPT_DIR="$(pwd)"
fi

# Read version
if [[ -f "$SCRIPT_DIR/VERSION" ]]; then
  VERSION="$(tr -d '[:space:]' < "$SCRIPT_DIR/VERSION")"
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

# Detect project root
if git rev-parse --show-toplevel &>/dev/null; then
  PROJECT_ROOT="$(git rev-parse --show-toplevel)"
else
  PROJECT_ROOT="$(pwd)"
fi

echo "=== claude-workflows installer v${VERSION} ==="
echo "Project root: ${PROJECT_ROOT}"
echo "Install type: ${INSTALL_TYPE}"
[[ -n "$TEAM_NAME" ]] && echo "Team:         ${TEAM_NAME}"
echo "With guards:  ${WITH_GUARDS}"
echo ""

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
    *)
      echo "ERROR: Unknown type '$type'" >&2
      exit 1
      ;;
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

# ============================================================
# 1. Create directory structure
# ============================================================
echo "Creating directory structure..."
mkdir -p "$PROJECT_ROOT/.claude/skills"
mkdir -p "$PROJECT_ROOT/.claude/templates"
mkdir -p "$PROJECT_ROOT/.claude/rules"
mkdir -p "$PROJECT_ROOT/.claude/reviews"
mkdir -p "$PROJECT_ROOT/.workflows/specs"
mkdir -p "$PROJECT_ROOT/.workflows/history"
mkdir -p "$PROJECT_ROOT/.workflows/learned"

# ============================================================
# 2. Copy core skills (flat into .claude/skills/)
# ============================================================
echo "Installing core skills..."
CORE_SKILLS=""
if [[ -d "$SCRIPT_DIR/core/skills" ]]; then
  for skill_dir in "$SCRIPT_DIR/core/skills"/*/; do
    skill_name="$(basename "$skill_dir")"
    cp -R "$skill_dir" "$PROJECT_ROOT/.claude/skills/$skill_name"
    CORE_SKILLS="$CORE_SKILLS$skill_name\n"
  done
  echo "  Installed core skills to .claude/skills/"
fi

# Write core manifest for upgrade tracking
printf "# Core skills installed by claude-workflows v%s\n%b" "$VERSION" "$CORE_SKILLS" > "$PROJECT_ROOT/.claude/.core-skills"

# ============================================================
# 3. Copy team skills (flat into .claude/skills/, overwrites core)
# ============================================================
if [[ -n "$TEAM_NAME" ]]; then
  echo "Installing team skills for: $TEAM_NAME..."
  TEAM_DIR="$SCRIPT_DIR/teams/$TEAM_NAME"

  if [[ -d "$TEAM_DIR/skills" ]]; then
    for skill_dir in "$TEAM_DIR/skills"/*/; do
      skill_name="$(basename "$skill_dir")"
      cp -R "$skill_dir" "$PROJECT_ROOT/.claude/skills/$skill_name"
    done
    echo "  Installed team skills to .claude/skills/"
  fi

  if [[ -d "$TEAM_DIR/rules" ]]; then
    cp "$TEAM_DIR/rules/"* "$PROJECT_ROOT/.claude/rules/" 2>/dev/null || true
    echo "  Copied team rules to .claude/rules/"
  fi

  if [[ -d "$TEAM_DIR/reviews" ]]; then
    cp "$TEAM_DIR/reviews/"* "$PROJECT_ROOT/.claude/reviews/" 2>/dev/null || true
    echo "  Copied team review checklists to .claude/reviews/"
  fi
fi

# ============================================================
# 4. Copy templates
# ============================================================
echo "Installing templates..."
if [[ -d "$SCRIPT_DIR/core/templates" ]]; then
  cp -R "$SCRIPT_DIR/core/templates/"* "$PROJECT_ROOT/.claude/templates/" 2>/dev/null || true
  echo "  Copied templates to .claude/templates/"
fi

# ============================================================
# 5. Copy language rules
# ============================================================
echo "Installing language rules..."
RULE_FILES="$(get_rule_files "$INSTALL_TYPE")"
if [[ -n "$RULE_FILES" && -d "$SCRIPT_DIR/core/rules" ]]; then
  for rule_file in $RULE_FILES; do
    if [[ -f "$SCRIPT_DIR/core/rules/$rule_file" ]]; then
      cp "$SCRIPT_DIR/core/rules/$rule_file" "$PROJECT_ROOT/.claude/rules/"
      echo "  Copied rule: $rule_file"
    fi
  done
elif [[ -z "$RULE_FILES" ]]; then
  echo "  Skipping language rules (type: $INSTALL_TYPE)"
fi

# ============================================================
# 6. Copy review checklists
# ============================================================
echo "Installing review checklists..."
REVIEW_LABEL="$(get_review_label "$INSTALL_TYPE")"
if [[ -n "$REVIEW_LABEL" && -d "$SCRIPT_DIR/core/reviews" ]]; then
  if [[ "$REVIEW_LABEL" == "all" ]]; then
    cp "$SCRIPT_DIR/core/reviews/"*.md "$PROJECT_ROOT/.claude/reviews/" 2>/dev/null || true
    echo "  Copied all review checklists"
  else
    if [[ -f "$SCRIPT_DIR/core/reviews/${REVIEW_LABEL}.md" ]]; then
      cp "$SCRIPT_DIR/core/reviews/${REVIEW_LABEL}.md" "$PROJECT_ROOT/.claude/reviews/"
      echo "  Copied review checklist: ${REVIEW_LABEL}.md"
    fi
  fi
fi

# ============================================================
# 7. Safety guards
# ============================================================
if [[ "$WITH_GUARDS" == true ]]; then
  echo "Installing safety guards..."
  if [[ -f "$SCRIPT_DIR/core/templates/guards.yml.tmpl" ]]; then
    if [[ ! -f "$PROJECT_ROOT/.claude/guards.yml" ]]; then
      cp "$SCRIPT_DIR/core/templates/guards.yml.tmpl" "$PROJECT_ROOT/.claude/guards.yml"
      echo "  Created .claude/guards.yml from template"
    else
      echo "  Skipping .claude/guards.yml (already exists)"
    fi
  fi
else
  echo "Skipping safety guards (use --with-guards to install)"
fi

# ============================================================
# 8. Create workflows.yml
# ============================================================
if [[ ! -f "$PROJECT_ROOT/.claude/workflows.yml" ]]; then
  if [[ -f "$SCRIPT_DIR/config/defaults.yml" ]]; then
    cp "$SCRIPT_DIR/config/defaults.yml" "$PROJECT_ROOT/.claude/workflows.yml"
    if [[ -n "$TEAM_NAME" ]]; then
      sed -i '' "s/^  team: \"\"/  team: \"$TEAM_NAME\"/" "$PROJECT_ROOT/.claude/workflows.yml"
    fi
    echo "Created .claude/workflows.yml from defaults"
  fi
else
  echo "Skipping .claude/workflows.yml (already exists)"
fi

# ============================================================
# 9. Write version marker
# ============================================================
echo "$VERSION" > "$PROJECT_ROOT/.claude/.workflows-version"
echo "Wrote version $VERSION to .claude/.workflows-version"

# ============================================================
# 10. Update CLAUDE.md
# ============================================================
CLAUDE_MD="$PROJECT_ROOT/CLAUDE.md"
MARKER_START="<!-- claude-workflows:start -->"
MARKER_END="<!-- claude-workflows:end -->"

TEAM_LINE=""
[[ -n "$TEAM_NAME" ]] && TEAM_LINE=" (team: $TEAM_NAME)"

WORKFLOW_BLOCK="$MARKER_START
## Workflows

This project uses [claude-workflows](https://github.com/ragaa07/claude-workflows) for structured development.

### Session Start — ALWAYS DO THIS
At the start of every session:
1. Check \`.workflows/current-state.md\` — if it exists, report the active workflow and current phase to the user. Offer to resume, restart, or abandon.
2. Check \`.workflows/paused-*.md\` — if paused workflows exist, mention them.
3. Read \`tasks/todo.md\` — check for in-progress items.
4. Read \`tasks/lessons.md\` — apply relevant lessons.

### Workflow State
- Active workflow state is tracked in \`.workflows/current-state.md\`
- Update this file at EVERY phase transition (phase name, status, timestamp)
- When pausing: rename to \`.workflows/paused-<name>.md\`
- When resuming: rename back to \`.workflows/current-state.md\`
- When done: move to \`.workflows/history/\`

### Available Skills
All workflow skills are auto-discovered from \`.claude/skills/\`. Key workflows:
- \`/new-feature\` — Full feature workflow: spec, brainstorm, plan, implement, test, PR
- \`/extend-feature\` — Extend an existing feature
- \`/hotfix\` — Quick production fix
- \`/refactor\` — Refactor existing code
- \`/release\` — Create a release
- \`/review\` — Code review workflow
- \`/brainstorm\` — Brainstorm solutions
- \`/test\` — Generate tests

### Configuration
- Workflow config: \`.claude/workflows.yml\`
- Skills${TEAM_LINE}: \`.claude/skills/\`
- Language rules: \`.claude/rules/\`
- Review checklists: \`.claude/reviews/\`
- Workflow state: \`.workflows/\`
$MARKER_END"

if [[ -f "$CLAUDE_MD" ]]; then
  if grep -qF "$MARKER_START" "$CLAUDE_MD"; then
    echo "Updating workflow section in CLAUDE.md..."
    TEMP_FILE="$(mktemp)"
    awk -v start="$MARKER_START" -v end="$MARKER_END" '
      $0 == start { skip=1; next }
      $0 == end { skip=0; next }
      !skip { print }
    ' "$CLAUDE_MD" > "$TEMP_FILE"
    echo "" >> "$TEMP_FILE"
    echo "$WORKFLOW_BLOCK" >> "$TEMP_FILE"
    mv "$TEMP_FILE" "$CLAUDE_MD"
    echo "  Updated workflow instructions in CLAUDE.md"
  else
    echo "" >> "$CLAUDE_MD"
    echo "$WORKFLOW_BLOCK" >> "$CLAUDE_MD"
    echo "Appended workflow instructions to CLAUDE.md"
  fi
else
  echo "$WORKFLOW_BLOCK" > "$CLAUDE_MD"
  echo "Created CLAUDE.md with workflow instructions"
fi

# ============================================================
# 11. Update .gitignore
# ============================================================
GITIGNORE="$PROJECT_ROOT/.gitignore"
echo "Updating .gitignore..."
add_to_gitignore ".workflows/current-state.md"
add_to_gitignore ".workflows/history/"
add_to_gitignore ".workflows/learned/"

# ============================================================
# Done
# ============================================================
echo ""
echo "=== Installation complete! ==="
echo ""
echo "Installed:"
echo "  Skills:            .claude/skills/"
echo "  Templates:         .claude/templates/"
if [[ -n "$RULE_FILES" ]]; then
echo "  Language rules:    .claude/rules/ ($RULE_FILES)"
fi
if [[ "$WITH_GUARDS" == true ]]; then
echo "  Safety guards:     .claude/guards.yml"
fi
echo ""
echo "Next steps:"
echo "  1. Edit .claude/workflows.yml to configure for your project"
echo "  2. Run /new-feature to start your first workflow"
echo "  3. Commit the .claude/ directory to your repository"
echo ""
echo "Installed version: $VERSION"
