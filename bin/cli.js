#!/usr/bin/env node

"use strict";

const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

// ============================================================
// Paths
// ============================================================
const PKG_ROOT = path.resolve(__dirname, "..");
const VERSION = fs
  .readFileSync(path.join(PKG_ROOT, "VERSION"), "utf8")
  .trim();

// ============================================================
// Argument parsing
// ============================================================
function parseArgs(argv) {
  const args = { command: null, type: "all", team: "", withGuards: false };
  let i = 0;

  if (argv.length === 0) {
    args.command = "help";
    return args;
  }

  if (!argv[0].startsWith("--")) {
    args.command = argv[0];
    i = 1;
  } else {
    args.command = "help";
  }

  while (i < argv.length) {
    switch (argv[i]) {
      case "--type":
        args.type = argv[++i] || "all";
        break;
      case "--team":
        args.team = argv[++i] || "";
        break;
      case "--with-guards":
        args.withGuards = true;
        break;
      case "--help":
      case "-h":
        args.command = "help";
        break;
      default:
        console.error(`Unknown option: ${argv[i]}`);
        process.exit(1);
    }
    i++;
  }

  return args;
}

// ============================================================
// Helpers
// ============================================================
function detectProjectRoot() {
  try {
    return execSync("git rev-parse --show-toplevel", {
      encoding: "utf8",
      stdio: ["pipe", "pipe", "pipe"],
    }).trim();
  } catch {
    return process.cwd();
  }
}

function copyDirRecursive(src, dest) {
  fs.mkdirSync(dest, { recursive: true });
  for (const entry of fs.readdirSync(src, { withFileTypes: true })) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);
    if (entry.isDirectory()) {
      copyDirRecursive(srcPath, destPath);
    } else {
      fs.copyFileSync(srcPath, destPath);
    }
  }
}

function getRuleFiles(type) {
  const map = {
    android: ["kotlin.md", "compose.md"],
    react: ["typescript.md", "react.md"],
    python: ["python.md"],
    swift: ["swift.md"],
    go: ["go.md"],
    generic: [],
    all: [
      "kotlin.md", "compose.md", "typescript.md", "react.md",
      "python.md", "swift.md", "go.md",
    ],
  };
  if (!map[type]) {
    console.error(
      `ERROR: Unknown type '${type}'. Valid: android, react, python, swift, go, generic, all`
    );
    process.exit(1);
  }
  return map[type];
}

function getReviewLabel(type) {
  const map = {
    android: "kotlin-checklist",
    react: "typescript-checklist",
    python: "python-checklist",
    swift: "swift-checklist",
    go: "go-checklist",
    generic: "general-checklist",
    all: "all",
  };
  return map[type] || "";
}

function addToGitignore(gitignorePath, entry) {
  if (fs.existsSync(gitignorePath)) {
    const content = fs.readFileSync(gitignorePath, "utf8");
    if (content.split("\n").some((line) => line.trim() === entry)) return;
    fs.appendFileSync(gitignorePath, `\n${entry}`);
  } else {
    fs.writeFileSync(gitignorePath, entry + "\n");
  }
}

// Write a manifest of core skill names for safe upgrades
function writeCoreManifest(root, skillNames) {
  const manifest = `# Core skills installed by claude-workflows v${VERSION}\n` +
    `# Used by upgrade to know which skills to replace\n` +
    skillNames.join("\n") + "\n";
  fs.writeFileSync(path.join(root, ".claude/.core-skills"), manifest);
}

function readCoreManifest(root) {
  const manifestPath = path.join(root, ".claude/.core-skills");
  if (!fs.existsSync(manifestPath)) return [];
  return fs.readFileSync(manifestPath, "utf8")
    .split("\n")
    .map((l) => l.trim())
    .filter((l) => l && !l.startsWith("#"));
}

// ============================================================
// Init command
// ============================================================
function cmdInit(args) {
  const root = detectProjectRoot();
  const { type, team, withGuards } = args;

  console.log(`=== claude-workflows v${VERSION} ===`);
  console.log(`Project root: ${root}`);
  console.log(`Install type: ${type}`);
  if (team) console.log(`Team:         ${team}`);
  console.log(`With guards:  ${withGuards}`);
  console.log();

  // Validate team
  const teamDir = team ? path.join(PKG_ROOT, "teams", team) : null;
  if (team) {
    if (!fs.existsSync(teamDir)) {
      console.error(`ERROR: Team '${team}' not found.`);
      console.log("Available teams:");
      listTeamsQuiet();
      process.exit(1);
    }
  }

  // 1. Create directory structure
  console.log("Creating directory structure...");
  for (const dir of [
    ".claude/skills",
    ".claude/templates",
    ".claude/rules",
    ".claude/reviews",
    ".workflows/specs",
    ".workflows/history",
    ".workflows/learned",
  ]) {
    fs.mkdirSync(path.join(root, dir), { recursive: true });
  }

  // 2. Copy core skills (flat into .claude/skills/)
  console.log("Installing core skills...");
  const coreSkillsSrc = path.join(PKG_ROOT, "core", "skills");
  const coreSkillNames = [];
  if (fs.existsSync(coreSkillsSrc)) {
    for (const entry of fs.readdirSync(coreSkillsSrc, { withFileTypes: true })) {
      if (!entry.isDirectory()) continue;
      copyDirRecursive(
        path.join(coreSkillsSrc, entry.name),
        path.join(root, ".claude/skills", entry.name)
      );
      coreSkillNames.push(entry.name);
    }
    console.log(`  Installed ${coreSkillNames.length} core skills to .claude/skills/`);
  }

  // Write core manifest for upgrade tracking
  writeCoreManifest(root, coreSkillNames);

  // 3. Copy team skills (flat into .claude/skills/, overwrites core if same name)
  if (team && teamDir) {
    console.log(`Installing team skills for: ${team}...`);
    const teamSkills = path.join(teamDir, "skills");
    if (fs.existsSync(teamSkills)) {
      let teamCount = 0;
      for (const entry of fs.readdirSync(teamSkills, { withFileTypes: true })) {
        if (!entry.isDirectory()) continue;
        copyDirRecursive(
          path.join(teamSkills, entry.name),
          path.join(root, ".claude/skills", entry.name)
        );
        teamCount++;
      }
      console.log(`  Installed ${teamCount} team skills to .claude/skills/`);
    }
    const teamRules = path.join(teamDir, "rules");
    if (fs.existsSync(teamRules)) {
      for (const f of fs.readdirSync(teamRules)) {
        fs.copyFileSync(
          path.join(teamRules, f),
          path.join(root, ".claude/rules", f)
        );
      }
      console.log("  Copied team rules to .claude/rules/");
    }
    const teamReviews = path.join(teamDir, "reviews");
    if (fs.existsSync(teamReviews)) {
      for (const f of fs.readdirSync(teamReviews)) {
        fs.copyFileSync(
          path.join(teamReviews, f),
          path.join(root, ".claude/reviews", f)
        );
      }
      console.log("  Copied team review checklists to .claude/reviews/");
    }
  }

  // 4. Copy templates
  console.log("Installing templates...");
  const templatesSrc = path.join(PKG_ROOT, "core", "templates");
  if (fs.existsSync(templatesSrc)) {
    const dest = path.join(root, ".claude/templates");
    for (const f of fs.readdirSync(templatesSrc)) {
      fs.copyFileSync(path.join(templatesSrc, f), path.join(dest, f));
    }
    console.log("  Copied templates to .claude/templates/");
  }

  // 5. Copy language rules
  console.log("Installing language rules...");
  const ruleFiles = getRuleFiles(type);
  const rulesSrc = path.join(PKG_ROOT, "core", "rules");
  if (ruleFiles.length > 0 && fs.existsSync(rulesSrc)) {
    for (const f of ruleFiles) {
      const src = path.join(rulesSrc, f);
      if (fs.existsSync(src)) {
        fs.copyFileSync(src, path.join(root, ".claude/rules", f));
        console.log(`  Copied rule: ${f}`);
      } else {
        console.log(`  WARNING: Rule file not found: ${f}`);
      }
    }
  } else if (ruleFiles.length === 0) {
    console.log(`  Skipping language rules (type: ${type})`);
  }

  // 6. Copy review checklists
  console.log("Installing review checklists...");
  const reviewLabel = getReviewLabel(type);
  const reviewsSrc = path.join(PKG_ROOT, "core", "reviews");
  if (reviewLabel && fs.existsSync(reviewsSrc)) {
    if (reviewLabel === "all") {
      for (const f of fs.readdirSync(reviewsSrc).filter((f) => f.endsWith(".md"))) {
        fs.copyFileSync(
          path.join(reviewsSrc, f),
          path.join(root, ".claude/reviews", f)
        );
      }
      console.log("  Copied all review checklists");
    } else {
      const src = path.join(reviewsSrc, `${reviewLabel}.md`);
      if (fs.existsSync(src)) {
        fs.copyFileSync(src, path.join(root, ".claude/reviews", `${reviewLabel}.md`));
        console.log(`  Copied review checklist: ${reviewLabel}.md`);
      } else {
        console.log(`  No review checklist found for: ${reviewLabel}`);
      }
    }
  }

  // 7. Safety guards
  if (withGuards) {
    console.log("Installing safety guards...");
    const guardsSrc = path.join(PKG_ROOT, "core", "templates", "guards.yml.tmpl");
    const guardsDest = path.join(root, ".claude/guards.yml");
    if (fs.existsSync(guardsSrc)) {
      if (!fs.existsSync(guardsDest)) {
        fs.copyFileSync(guardsSrc, guardsDest);
        console.log("  Created .claude/guards.yml from template");
      } else {
        console.log("  Skipping .claude/guards.yml (already exists)");
      }
    }
  } else {
    console.log("Skipping safety guards (use --with-guards to install)");
  }

  // 8. Create workflows.yml
  const workflowsYml = path.join(root, ".claude/workflows.yml");
  if (!fs.existsSync(workflowsYml)) {
    const defaultsSrc = path.join(PKG_ROOT, "config", "defaults.yml");
    if (fs.existsSync(defaultsSrc)) {
      let content = fs.readFileSync(defaultsSrc, "utf8");
      if (team) {
        content = content.replace('  team: ""', `  team: "${team}"`);
      }
      fs.writeFileSync(workflowsYml, content);
      console.log("Created .claude/workflows.yml from defaults");
    }
  } else {
    console.log("Skipping .claude/workflows.yml (already exists)");
  }

  // 9. Write version marker
  fs.writeFileSync(path.join(root, ".claude/.workflows-version"), VERSION + "\n");
  console.log(`Wrote version ${VERSION} to .claude/.workflows-version`);

  // 10. Update CLAUDE.md
  updateClaudeMd(root, team);

  // 11. Update .gitignore
  console.log("Updating .gitignore...");
  const gitignore = path.join(root, ".gitignore");
  addToGitignore(gitignore, ".workflows/current-state.md");
  addToGitignore(gitignore, ".workflows/history/");
  addToGitignore(gitignore, ".workflows/learned/");

  // Done
  console.log();
  console.log("=== Installation complete! ===");
  console.log();
  console.log("Installed:");
  console.log("  Skills:            .claude/skills/");
  console.log("  Templates:         .claude/templates/");
  if (ruleFiles.length > 0)
    console.log(`  Language rules:    .claude/rules/ (${ruleFiles.join(", ")})`);
  if (withGuards) console.log("  Safety guards:     .claude/guards.yml");
  console.log();
  console.log("Next steps:");
  console.log("  1. Edit .claude/workflows.yml to configure for your project");
  console.log("  2. Run /workflow-engine to start your first workflow");
  console.log("  3. Commit the .claude/ directory to your repository");
  console.log();
  console.log(`Installed version: ${VERSION}`);
}

// ============================================================
// CLAUDE.md injection
// ============================================================
function updateClaudeMd(root, team) {
  const claudeMdPath = path.join(root, "CLAUDE.md");
  const MARKER_START = "<!-- claude-workflows:start -->";
  const MARKER_END = "<!-- claude-workflows:end -->";

  const teamLine = team ? ` (team: ${team})` : "";

  const block = `${MARKER_START}
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
- Skills${teamLine}: \`.claude/skills/\`
- Language rules: \`.claude/rules/\`
- Review checklists: \`.claude/reviews/\`
- Workflow state: \`.workflows/\`
${MARKER_END}`;

  if (fs.existsSync(claudeMdPath)) {
    let content = fs.readFileSync(claudeMdPath, "utf8");
    if (content.includes(MARKER_START)) {
      console.log("Updating workflow section in CLAUDE.md...");
      const regex = new RegExp(
        `${escapeRegex(MARKER_START)}[\\s\\S]*?${escapeRegex(MARKER_END)}`,
        "g"
      );
      content = content.replace(regex, block);
      fs.writeFileSync(claudeMdPath, content);
      console.log("  Updated workflow instructions in CLAUDE.md");
    } else {
      fs.appendFileSync(claudeMdPath, "\n" + block);
      console.log("Appended workflow instructions to CLAUDE.md");
    }
  } else {
    fs.writeFileSync(claudeMdPath, block);
    console.log("Created CLAUDE.md with workflow instructions");
  }
}

function escapeRegex(str) {
  return str.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

// ============================================================
// Upgrade command
// ============================================================
function cmdUpgrade(args) {
  const root = detectProjectRoot();
  const { type, team, withGuards } = args;

  const versionFile = path.join(root, ".claude/.workflows-version");
  if (!fs.existsSync(versionFile)) {
    console.error("ERROR: No existing claude-workflows installation found.");
    console.error(`  Expected version file at: ${versionFile}`);
    console.error();
    console.error("Run 'claude-dev-workflows init' first.");
    process.exit(1);
  }

  const currentVersion = fs.readFileSync(versionFile, "utf8").trim();

  // Validate team
  if (team) {
    const teamDir = path.join(PKG_ROOT, "teams", team);
    if (!fs.existsSync(teamDir)) {
      console.error(`ERROR: Team '${team}' not found.`);
      console.log("Available teams:");
      listTeamsQuiet();
      process.exit(1);
    }
  }

  console.log("=== claude-workflows upgrade ===");
  console.log(`Current version: ${currentVersion}`);
  console.log(`New version:     ${VERSION}`);
  if (type) console.log(`Install type:    ${type}`);
  if (team) console.log(`Team:            ${team}`);
  console.log();

  if (currentVersion === VERSION) {
    console.log(`Already up to date (v${currentVersion}).`);
    return;
  }

  // 1. Replace core skills (only those tracked in manifest)
  console.log("Upgrading core skills...");
  const oldCoreSkills = readCoreManifest(root);
  const skillsDir = path.join(root, ".claude/skills");

  // Remove old core skills
  for (const name of oldCoreSkills) {
    const skillDir = path.join(skillsDir, name);
    if (fs.existsSync(skillDir)) {
      fs.rmSync(skillDir, { recursive: true, force: true });
    }
  }

  // Copy new core skills
  const coreSkillsSrc = path.join(PKG_ROOT, "core", "skills");
  const newCoreSkillNames = [];
  if (fs.existsSync(coreSkillsSrc)) {
    for (const entry of fs.readdirSync(coreSkillsSrc, { withFileTypes: true })) {
      if (!entry.isDirectory()) continue;
      copyDirRecursive(
        path.join(coreSkillsSrc, entry.name),
        path.join(skillsDir, entry.name)
      );
      newCoreSkillNames.push(entry.name);
    }
    console.log(`  Replaced ${newCoreSkillNames.length} core skills`);
  }

  // Update manifest
  writeCoreManifest(root, newCoreSkillNames);

  // 2. Copy team skills on top (overwrites core if same name)
  if (team) {
    console.log(`Upgrading team skills for: ${team}...`);
    const teamDir = path.join(PKG_ROOT, "teams", team);
    const teamSkillsSrc = path.join(teamDir, "skills");
    if (fs.existsSync(teamSkillsSrc)) {
      let teamCount = 0;
      for (const entry of fs.readdirSync(teamSkillsSrc, { withFileTypes: true })) {
        if (!entry.isDirectory()) continue;
        copyDirRecursive(
          path.join(teamSkillsSrc, entry.name),
          path.join(skillsDir, entry.name)
        );
        teamCount++;
      }
      console.log(`  Updated ${teamCount} team skills`);
    }
    const teamRules = path.join(teamDir, "rules");
    if (fs.existsSync(teamRules)) {
      fs.mkdirSync(path.join(root, ".claude/rules"), { recursive: true });
      for (const f of fs.readdirSync(teamRules)) {
        fs.copyFileSync(
          path.join(teamRules, f),
          path.join(root, ".claude/rules", f)
        );
      }
      console.log("  Updated team rules");
    }
    const teamReviews = path.join(teamDir, "reviews");
    if (fs.existsSync(teamReviews)) {
      fs.mkdirSync(path.join(root, ".claude/reviews"), { recursive: true });
      for (const f of fs.readdirSync(teamReviews)) {
        fs.copyFileSync(
          path.join(teamReviews, f),
          path.join(root, ".claude/reviews", f)
        );
      }
      console.log("  Updated team review checklists");
    }
  }

  // 3. Replace templates
  console.log("Upgrading templates...");
  const templatesSrc = path.join(PKG_ROOT, "core", "templates");
  const templatesDest = path.join(root, ".claude/templates");
  if (fs.existsSync(templatesSrc)) {
    fs.rmSync(templatesDest, { recursive: true, force: true });
    fs.mkdirSync(templatesDest, { recursive: true });
    for (const f of fs.readdirSync(templatesSrc)) {
      fs.copyFileSync(path.join(templatesSrc, f), path.join(templatesDest, f));
    }
    console.log("  Replaced .claude/templates/");
  }

  // 4. Upgrade language rules
  if (type) {
    console.log("Upgrading language rules...");
    fs.mkdirSync(path.join(root, ".claude/rules"), { recursive: true });
    const ruleFiles = getRuleFiles(type);
    const rulesSrc = path.join(PKG_ROOT, "core", "rules");
    if (ruleFiles.length > 0 && fs.existsSync(rulesSrc)) {
      for (const f of ruleFiles) {
        const src = path.join(rulesSrc, f);
        if (fs.existsSync(src)) {
          fs.copyFileSync(src, path.join(root, ".claude/rules", f));
          console.log(`  Updated rule: ${f}`);
        }
      }
    }
  } else {
    console.log("Skipping language rules (no --type specified)");
  }

  // 5. Upgrade review checklists
  if (type) {
    console.log("Upgrading review checklists...");
    fs.mkdirSync(path.join(root, ".claude/reviews"), { recursive: true });
    const reviewLabel = getReviewLabel(type);
    const reviewsSrc = path.join(PKG_ROOT, "core", "reviews");
    if (reviewLabel && fs.existsSync(reviewsSrc)) {
      if (reviewLabel === "all") {
        for (const f of fs.readdirSync(reviewsSrc).filter((f) => f.endsWith(".md"))) {
          fs.copyFileSync(
            path.join(reviewsSrc, f),
            path.join(root, ".claude/reviews", f)
          );
        }
        console.log("  Updated all review checklists");
      } else {
        const src = path.join(reviewsSrc, `${reviewLabel}.md`);
        if (fs.existsSync(src)) {
          fs.copyFileSync(src, path.join(root, ".claude/reviews", `${reviewLabel}.md`));
          console.log(`  Updated review checklist: ${reviewLabel}.md`);
        }
      }
    }
  } else {
    console.log("Skipping review checklists (no --type specified)");
  }

  // 6. Upgrade guards
  if (withGuards) {
    console.log("Upgrading safety guards...");
    const guardsSrc = path.join(PKG_ROOT, "core", "templates", "guards.yml.tmpl");
    if (fs.existsSync(guardsSrc)) {
      fs.copyFileSync(guardsSrc, path.join(root, ".claude/guards.yml"));
      console.log("  Updated .claude/guards.yml");
    }
  }

  // 7. Ensure directories
  fs.mkdirSync(path.join(root, ".claude/rules"), { recursive: true });
  fs.mkdirSync(path.join(root, ".claude/reviews"), { recursive: true });
  fs.mkdirSync(path.join(root, ".workflows/learned"), { recursive: true });

  // 8. Preserved
  console.log();
  console.log("Preserved (not modified):");
  console.log("  .claude/workflows.yml");
  console.log("  .claude/skills/ (project-specific skills)");
  if (!type) {
    console.log("  .claude/rules/ (use --type to update)");
    console.log("  .claude/reviews/ (use --type to update)");
  }
  if (!withGuards) {
    console.log("  .claude/guards.yml (use --with-guards to update)");
  }

  // 9. Update version
  fs.writeFileSync(versionFile, VERSION + "\n");

  // 10. Update .gitignore
  const gitignore = path.join(root, ".gitignore");
  addToGitignore(gitignore, ".workflows/learned/");

  console.log();
  console.log("=== Upgrade complete! ===");
  console.log(`  ${currentVersion} → ${VERSION}`);
}

// ============================================================
// List teams
// ============================================================
function listTeamsQuiet() {
  const teamsDir = path.join(PKG_ROOT, "teams");
  if (!fs.existsSync(teamsDir)) return;
  for (const entry of fs.readdirSync(teamsDir, { withFileTypes: true })) {
    if (entry.isDirectory() && entry.name !== "_template") {
      console.log(`  - ${entry.name}`);
    }
  }
}

function cmdListTeams() {
  console.log("Available teams:");
  const teamsDir = path.join(PKG_ROOT, "teams");
  if (!fs.existsSync(teamsDir)) {
    console.log("  (none)");
    return;
  }
  let found = false;
  for (const entry of fs.readdirSync(teamsDir, { withFileTypes: true })) {
    if (entry.isDirectory() && entry.name !== "_template") {
      const manifest = path.join(teamsDir, entry.name, "manifest.yml");
      let desc = "";
      if (fs.existsSync(manifest)) {
        const content = fs.readFileSync(manifest, "utf8");
        const match = content.match(/^description:\s*"?(.+?)"?\s*$/m);
        if (match) desc = ` — ${match[1]}`;
      }
      console.log(`  ${entry.name}${desc}`);
      found = true;
    }
  }
  if (!found) {
    console.log("  (none — copy teams/_template to create one)");
  }
}

// ============================================================
// Help
// ============================================================
function cmdHelp() {
  console.log(`claude-workflows v${VERSION}

Usage:
  claude-dev-workflows init     [--type TYPE] [--team TEAM] [--with-guards]
  claude-dev-workflows upgrade  [--type TYPE] [--team TEAM] [--with-guards]
  claude-dev-workflows version
  claude-dev-workflows list-teams

Commands:
  init          Install workflows into the current project
  upgrade       Upgrade an existing installation
  version       Print the current version
  list-teams    List available team configurations

Options:
  --type TYPE       Language type: android, react, python, swift, go, generic (default: all)
  --team TEAM       Team name for team-specific skills/rules/reviews
  --with-guards     Install or upgrade safety guards
  -h, --help        Show this help message
`);
}

// ============================================================
// Main
// ============================================================
const args = parseArgs(process.argv.slice(2));

switch (args.command) {
  case "init":
    cmdInit(args);
    break;
  case "upgrade":
    cmdUpgrade(args);
    break;
  case "version":
    console.log(VERSION);
    break;
  case "list-teams":
    cmdListTeams();
    break;
  case "help":
    cmdHelp();
    break;
  default:
    console.error(`Unknown command: ${args.command}`);
    cmdHelp();
    process.exit(1);
}
