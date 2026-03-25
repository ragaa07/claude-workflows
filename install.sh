#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# claude-workflows installer
# ============================================================
# Usage:
#   bash install.sh                    # Install everything (default)
#   bash install.sh --type android     # Install core + kotlin + compose rules + Android review checklist
#   bash install.sh --type react       # Install core + typescript + react rules + TS review checklist
#   bash install.sh --type python      # Install core + python rules + Python review checklist
#   bash install.sh --type swift       # Install core + swift rules + Swift review checklist
#   bash install.sh --type go          # Install core + go rules + Go review checklist
#   bash install.sh --type generic     # Install core only, no language rules
#   bash install.sh --with-guards      # Also install safety guards
#   bash install.sh --team android     # Also install team-specific skills/rules/reviews
#   bash install.sh --type android --team android  # Full android team setup
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
  # Likely piped via curl — look for a local clone
  SCRIPT_DIR="$(pwd)"
fi

# Read version
if [[ -f "$SCRIPT_DIR/VERSION" ]]; then
  VERSION="$(cat "$SCRIPT_DIR/VERSION" | tr -d '[:space:]')"
else
  echo "ERROR: VERSION file not found in $SCRIPT_DIR"
  echo "Please run this script from the claude-workflows repository root."
  exit 1
fi

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

# Detect project root (git root or cwd)
if git rev-parse --show-toplevel &>/dev/null; then
  PROJECT_ROOT="$(git rev-parse --show-toplevel)"
else
  PROJECT_ROOT="$(pwd)"
fi

echo "=== claude-workflows installer v${VERSION} ==="
echo "Project root: ${PROJECT_ROOT}"
echo "Install type: ${INSTALL_TYPE}"
if [[ -n "$TEAM_NAME" ]]; then
echo "Team:         ${TEAM_NAME}"
fi
echo "With guards:  ${WITH_GUARDS}"
echo ""

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
    *)
      echo "ERROR: Unknown type '$type'. Valid types: android, react, python, swift, go, generic, all" >&2
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

# ============================================================
# 1. Create directory structure
# ============================================================
echo "Creating directory structure..."

mkdir -p "$PROJECT_ROOT/.claude/skills/_core"
mkdir -p "$PROJECT_ROOT/.claude/templates"
mkdir -p "$PROJECT_ROOT/.claude/rules"
mkdir -p "$PROJECT_ROOT/.claude/reviews"
mkdir -p "$PROJECT_ROOT/.workflows/specs"
mkdir -p "$PROJECT_ROOT/.workflows/history"
mkdir -p "$PROJECT_ROOT/.workflows/learned"

# ============================================================
# 2. Copy core skills
# ============================================================
echo "Installing core skills..."

if [[ -d "$SCRIPT_DIR/core/skills" ]]; then
  cp -R "$SCRIPT_DIR/core/skills/"* "$PROJECT_ROOT/.claude/skills/_core/" 2>/dev/null || true
  echo "  Copied core skills to .claude/skills/_core/"
else
  echo "  WARNING: No core skills found at $SCRIPT_DIR/core/skills/"
fi

# ============================================================
# 2b. Copy team skills (if --team specified)
# ============================================================
if [[ -n "$TEAM_NAME" ]]; then
  echo "Installing team skills for: $TEAM_NAME..."
  TEAM_DIR="$SCRIPT_DIR/teams/$TEAM_NAME"

  if [[ -d "$TEAM_DIR/skills" ]]; then
    mkdir -p "$PROJECT_ROOT/.claude/skills/_team"
    cp -R "$TEAM_DIR/skills/"* "$PROJECT_ROOT/.claude/skills/_team/"
    echo "  Copied team skills to .claude/skills/_team/"
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
# 3. Copy templates
# ============================================================
echo "Installing templates..."

if [[ -d "$SCRIPT_DIR/core/templates" ]]; then
  cp -R "$SCRIPT_DIR/core/templates/"* "$PROJECT_ROOT/.claude/templates/" 2>/dev/null || true
  echo "  Copied templates to .claude/templates/"
else
  echo "  WARNING: No templates found at $SCRIPT_DIR/core/templates/"
fi

# ============================================================
# 4. Copy language rules (based on --type)
# ============================================================
echo "Installing language rules..."

RULE_FILES="$(get_rule_files "$INSTALL_TYPE")"

if [[ -n "$RULE_FILES" && -d "$SCRIPT_DIR/core/rules" ]]; then
  for rule_file in $RULE_FILES; do
    if [[ -f "$SCRIPT_DIR/core/rules/$rule_file" ]]; then
      cp "$SCRIPT_DIR/core/rules/$rule_file" "$PROJECT_ROOT/.claude/rules/"
      echo "  Copied rule: $rule_file"
    else
      echo "  WARNING: Rule file not found: $rule_file"
    fi
  done
elif [[ -z "$RULE_FILES" ]]; then
  echo "  Skipping language rules (type: $INSTALL_TYPE)"
else
  echo "  WARNING: No rules directory found at $SCRIPT_DIR/core/rules/"
fi

# ============================================================
# 5. Copy review checklists (based on --type)
# ============================================================
echo "Installing review checklists..."

REVIEW_LABEL="$(get_review_label "$INSTALL_TYPE")"

if [[ -n "$REVIEW_LABEL" && -d "$SCRIPT_DIR/core/reviews" ]]; then
  if [[ "$REVIEW_LABEL" == "all" ]]; then
    # Copy all review checklists
    if ls "$SCRIPT_DIR/core/reviews/"*.md &>/dev/null; then
      cp "$SCRIPT_DIR/core/reviews/"*.md "$PROJECT_ROOT/.claude/reviews/" 2>/dev/null || true
      echo "  Copied all review checklists"
    else
      echo "  No review checklists found yet"
    fi
  else
    # Copy specific review checklist
    if [[ -f "$SCRIPT_DIR/core/reviews/${REVIEW_LABEL}.md" ]]; then
      cp "$SCRIPT_DIR/core/reviews/${REVIEW_LABEL}.md" "$PROJECT_ROOT/.claude/reviews/"
      echo "  Copied review checklist: ${REVIEW_LABEL}.md"
    else
      echo "  No review checklist found for: ${REVIEW_LABEL} (not yet available)"
    fi
  fi
elif [[ -z "$REVIEW_LABEL" ]]; then
  echo "  Skipping review checklists (type: $INSTALL_TYPE)"
else
  echo "  WARNING: No reviews directory found at $SCRIPT_DIR/core/reviews/"
fi

# ============================================================
# 6. Install safety guards (if --with-guards)
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
  else
    echo "  WARNING: guards.yml.tmpl not found"
  fi
else
  echo "Skipping safety guards (use --with-guards to install)"
fi

# ============================================================
# 7. Create workflows.yml from defaults (only if not exists)
# ============================================================
if [[ ! -f "$PROJECT_ROOT/.claude/workflows.yml" ]]; then
  if [[ -f "$SCRIPT_DIR/config/defaults.yml" ]]; then
    cp "$SCRIPT_DIR/config/defaults.yml" "$PROJECT_ROOT/.claude/workflows.yml"
    if [[ -n "$TEAM_NAME" ]]; then
      sed -i '' "s/^  team: \"\"/  team: \"$TEAM_NAME\"/" "$PROJECT_ROOT/.claude/workflows.yml"
    fi
    echo "Created .claude/workflows.yml from defaults"
  else
    echo "  WARNING: defaults.yml not found at $SCRIPT_DIR/config/defaults.yml"
  fi
else
  echo "Skipping .claude/workflows.yml (already exists)"
fi

# ============================================================
# 8. Write version marker
# ============================================================
echo "$VERSION" > "$PROJECT_ROOT/.claude/.workflows-version"
echo "Wrote version $VERSION to .claude/.workflows-version"

# ============================================================
# 9. Append workflow instructions to CLAUDE.md (idempotent)
# ============================================================
CLAUDE_MD="$PROJECT_ROOT/CLAUDE.md"
MARKER_START="<!-- claude-workflows:start -->"
MARKER_END="<!-- claude-workflows:end -->"

# Build team skills line for CLAUDE.md
TEAM_SKILLS_LINE=""
if [[ -n "$TEAM_NAME" ]]; then
  TEAM_SKILLS_LINE="
- Team skills ($TEAM_NAME): \`.claude/skills/_team/\`"
fi

# Build team commands section
TEAM_COMMANDS=""
if [[ -n "$TEAM_NAME" && -d "$SCRIPT_DIR/teams/$TEAM_NAME/skills" ]]; then
  TEAM_COMMANDS="

### Team Skills ($TEAM_NAME)
Team-specific workflows available via \`/workflow:<skill-name>\`. Check \`.claude/skills/_team/\` for all available team skills."
fi

WORKFLOW_BLOCK="$MARKER_START
## Workflows

This project uses [claude-workflows](https://github.com/4SaleTech/claude-workflows) for structured development.

### Available Commands
- \`/workflow:new-feature\` — Start a new feature workflow
- \`/workflow:extend-feature\` — Extend an existing feature
- \`/workflow:hotfix\` — Quick production fix
- \`/workflow:refactor\` — Refactor existing code
- \`/workflow:release\` — Create a release
- \`/workflow:review\` — Code review workflow
- \`/workflow:brainstorm\` — Brainstorm solutions
- \`/workflow:learn\` — Capture patterns from completed workflows
- \`/workflow:status\` — Check current workflow state
- \`/workflow:resume\` — Resume an in-progress workflow
$TEAM_COMMANDS

### Configuration
- Workflow config: \`.claude/workflows.yml\`
- Core skills: \`.claude/skills/_core/\`$TEAM_SKILLS_LINE
- Language rules: \`.claude/rules/\`
- Review checklists: \`.claude/reviews/\`
- Workflow state: \`.workflows/\`
- Learned patterns: \`.workflows/learned/\`

### Dry Run
Append \`--dry-run\` to any workflow command to preview without executing.
$MARKER_END"

if [[ -f "$CLAUDE_MD" ]]; then
  if grep -qF "$MARKER_START" "$CLAUDE_MD"; then
    echo "Updating workflow section in CLAUDE.md..."
    # Remove old block and replace
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
# 10. Update .gitignore
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
echo "  Core skills:       .claude/skills/_core/"
if [[ -n "$TEAM_NAME" ]]; then
echo "  Team skills:       .claude/skills/_team/ ($TEAM_NAME)"
fi
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
echo "  2. Run /workflow:new-feature to start your first workflow"
echo "  3. Commit the .claude/ directory to your repository"
echo ""
echo "Installed version: $VERSION"
