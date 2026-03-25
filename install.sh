#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# claude-workflows installer
# ============================================================

# Determine where the installer source files live
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

# Detect project root (git root or cwd)
if git rev-parse --show-toplevel &>/dev/null; then
  PROJECT_ROOT="$(git rev-parse --show-toplevel)"
else
  PROJECT_ROOT="$(pwd)"
fi

echo "=== claude-workflows installer v${VERSION} ==="
echo "Project root: ${PROJECT_ROOT}"
echo ""

# ============================================================
# 1. Create directory structure
# ============================================================
echo "Creating directory structure..."

mkdir -p "$PROJECT_ROOT/.claude/skills/_core"
mkdir -p "$PROJECT_ROOT/.claude/templates"
mkdir -p "$PROJECT_ROOT/.workflows/specs"
mkdir -p "$PROJECT_ROOT/.workflows/history"

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
# 4. Create workflows.yml from defaults (only if not exists)
# ============================================================
if [[ ! -f "$PROJECT_ROOT/.claude/workflows.yml" ]]; then
  if [[ -f "$SCRIPT_DIR/config/defaults.yml" ]]; then
    cp "$SCRIPT_DIR/config/defaults.yml" "$PROJECT_ROOT/.claude/workflows.yml"
    echo "Created .claude/workflows.yml from defaults"
  else
    echo "  WARNING: defaults.yml not found at $SCRIPT_DIR/config/defaults.yml"
  fi
else
  echo "Skipping .claude/workflows.yml (already exists)"
fi

# ============================================================
# 5. Write version marker
# ============================================================
echo "$VERSION" > "$PROJECT_ROOT/.claude/.workflows-version"
echo "Wrote version $VERSION to .claude/.workflows-version"

# ============================================================
# 6. Append workflow instructions to CLAUDE.md (idempotent)
# ============================================================
CLAUDE_MD="$PROJECT_ROOT/CLAUDE.md"
MARKER_START="<!-- claude-workflows:start -->"
MARKER_END="<!-- claude-workflows:end -->"

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
- \`/workflow:status\` — Check current workflow state
- \`/workflow:resume\` — Resume an in-progress workflow

### Configuration
- Workflow config: \`.claude/workflows.yml\`
- Core skills: \`.claude/skills/_core/\`
- Workflow state: \`.workflows/\`
$MARKER_END"

if [[ -f "$CLAUDE_MD" ]]; then
  if grep -qF "$MARKER_START" "$CLAUDE_MD"; then
    echo "Skipping CLAUDE.md (workflow section already present)"
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
# 7. Update .gitignore
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

# ============================================================
# Done
# ============================================================
echo ""
echo "=== Installation complete! ==="
echo ""
echo "Next steps:"
echo "  1. Edit .claude/workflows.yml to configure for your project"
echo "  2. Run /workflow:new-feature to start your first workflow"
echo "  3. Commit the .claude/ directory to your repository"
echo ""
echo "Installed version: $VERSION"
