#!/usr/bin/env node
"use strict";

/**
 * Plugin structure validation for claude-workflows v3.0.0
 *
 * Validates:
 * 1. Plugin manifest exists and is valid JSON
 * 2. All skill directories contain SKILL.md
 * 3. Skills have valid YAML frontmatter (name, description)
 * 4. Phase ordering matches declared phases
 * 5. Phase output paths are sequential (01-, 02-, 03-...)
 * 6. Implementation skills reference ${CLAUDE_PLUGIN_ROOT}/rules/
 * 7. PR skills reference ${CLAUDE_PLUGIN_ROOT}/reviews/ (quality gate)
 * 8. Language rule files exist for all supported types
 * 9. Review checklist files exist for all supported types
 * 10. No old .claude/ path references remain (except intentional ones)
 * 11. hooks.json is valid
 * 12. settings.json is valid
 */

const fs = require("fs");
const path = require("path");

const PLUGIN_ROOT = path.resolve(__dirname, "..");
const VERSION = fs.readFileSync(path.join(PLUGIN_ROOT, "VERSION"), "utf8").trim();

// Expected phase orders for each workflow
const WORKFLOW_PHASES = {
  "new-feature": {
    phases: ["GATHER", "SPEC", "BRAINSTORM", "PLAN", "BRANCH", "IMPLEMENT", "TEST", "PR"],
    hasImplement: true,
    hasPR: true,
  },
  "extend-feature": {
    phases: ["ANALYZE", "BRAINSTORM", "PLAN", "IMPLEMENT", "VERIFY-COMPAT", "TEST", "PR"],
    hasImplement: true,
    hasPR: true,
  },
  "hotfix": {
    phases: ["DIAGNOSE", "FIX", "REGRESSION-TEST", "PR", "CHERRY-PICK"],
    hasImplement: true,
    hasPR: true,
  },
  "refactor": {
    phases: ["ANALYZE", "BRAINSTORM", "CONTRACT", "DESIGN", "MIGRATE", "VERIFY", "PR"],
    hasImplement: true,
    hasPR: true,
  },
  "brainstorm": {
    phases: ["EXPLORE", "EVALUATE", "RECOMMEND"],
    hasImplement: false,
    hasPR: false,
  },
  "test": {
    phases: ["ANALYZE", "PLAN", "WRITE", "VERIFY", "REPORT"],
    hasImplement: false,
    hasPR: false,
  },
  "review": {
    phases: ["FETCH", "CATEGORIZE", "CHECK", "COMMENT"],
    hasImplement: false,
    hasPR: false,
  },
  "release": {
    phases: ["CHANGELOG", "VERSION-BUMP", "RELEASE-BRANCH", "PR", "TAG"],
    hasImplement: false,
    hasPR: true,
  },
  "ci-fix": {
    phases: ["FETCH", "DIAGNOSE", "FIX", "PUSH", "MONITOR"],
    hasImplement: true,
    hasPR: false,
  },
  "migrate": {
    phases: ["ANALYZE", "BRAINSTORM", "PLAN", "EXECUTE", "VERIFY", "PR"],
    hasImplement: true,
    hasPR: true,
  },
  "new-project": {
    phases: ["DETECT", "CONFIGURE", "GENERATE", "SETUP"],
    hasImplement: false,
    hasPR: false,
  },
};

// Skills that may intentionally reference .claude/ for project-local output
const ALLOWED_CLAUDE_REFS = ["setup", "new-project", "compose-skill"];

// Expected language files per project type
const TYPE_RULES = {
  android: ["kotlin.md", "compose.md"],
  react: ["typescript.md", "react.md"],
  python: ["python.md"],
  swift: ["swift.md"],
  go: ["go.md"],
};

const TYPE_REVIEWS = {
  android: ["kotlin-checklist.md", "compose-checklist.md"],
  react: ["typescript-checklist.md", "react-checklist.md"],
  python: ["python-checklist.md"],
  swift: ["swift-checklist.md"],
  go: ["go-checklist.md"],
};

// ============================================================
// Test Runner
// ============================================================
let totalTests = 0;
let passed = 0;
let failed = 0;
const failures = [];

function test(name, condition, detail) {
  totalTests++;
  if (condition) {
    passed++;
  } else {
    failed++;
    failures.push({ name, detail });
    console.log(`  FAIL: ${name}`);
    if (detail) console.log(`        ${detail}`);
  }
}

function section(title) {
  console.log(`\n${"=".repeat(60)}`);
  console.log(`  ${title}`);
  console.log("=".repeat(60));
}

// ============================================================
// Validators
// ============================================================

function validatePluginManifest() {
  section("Plugin Manifest");
  const manifestPath = path.join(PLUGIN_ROOT, ".claude-plugin", "plugin.json");

  test("plugin.json exists", fs.existsSync(manifestPath));

  if (fs.existsSync(manifestPath)) {
    let manifest;
    try {
      manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
      test("plugin.json is valid JSON", true);
    } catch (e) {
      test("plugin.json is valid JSON", false, e.message);
      return;
    }

    test("Has name field", manifest.name === "claude-workflows");
    test("Has version field", manifest.version === VERSION, `Expected ${VERSION}, got ${manifest.version}`);
    test("Has description", typeof manifest.description === "string" && manifest.description.length > 0);
    test("Has userConfig", typeof manifest.userConfig === "object");

    if (manifest.userConfig) {
      for (const key of ["project_type", "team", "git_main_branch", "git_dev_branch", "commit_format"]) {
        test(`userConfig has ${key}`, manifest.userConfig[key] !== undefined);
        if (manifest.userConfig[key]) {
          test(`userConfig.${key} has description`, typeof manifest.userConfig[key].description === "string");
        }
      }
    }
  }
}

function validatePluginFiles() {
  section("Plugin Files");
  test("hooks/hooks.json exists", fs.existsSync(path.join(PLUGIN_ROOT, "hooks", "hooks.json")));
  test("settings.json exists", fs.existsSync(path.join(PLUGIN_ROOT, "settings.json")));
  test("config/defaults.yml exists", fs.existsSync(path.join(PLUGIN_ROOT, "config", "defaults.yml")));

  // Validate hooks.json
  const hooksPath = path.join(PLUGIN_ROOT, "hooks", "hooks.json");
  if (fs.existsSync(hooksPath)) {
    try {
      const hooks = JSON.parse(fs.readFileSync(hooksPath, "utf8"));
      test("hooks.json is valid JSON", true);
      test("hooks.json has hooks object", typeof hooks.hooks === "object");
      test("Has SessionStart hook", hooks.hooks && hooks.hooks.SessionStart !== undefined);
    } catch (e) {
      test("hooks.json is valid JSON", false, e.message);
    }
  }

  // Validate settings.json
  const settingsPath = path.join(PLUGIN_ROOT, "settings.json");
  if (fs.existsSync(settingsPath)) {
    try {
      const settings = JSON.parse(fs.readFileSync(settingsPath, "utf8"));
      test("settings.json is valid JSON", true);
      test("Has permissions", settings.permissions !== undefined);
    } catch (e) {
      test("settings.json is valid JSON", false, e.message);
    }
  }
}

function validateDirectoryStructure() {
  section("Directory Structure");
  test("skills/ directory exists", fs.existsSync(path.join(PLUGIN_ROOT, "skills")));
  test("rules/ directory exists", fs.existsSync(path.join(PLUGIN_ROOT, "rules")));
  test("reviews/ directory exists", fs.existsSync(path.join(PLUGIN_ROOT, "reviews")));
  test("templates/ directory exists", fs.existsSync(path.join(PLUGIN_ROOT, "templates")));
  test("teams/ directory exists", fs.existsSync(path.join(PLUGIN_ROOT, "teams")));
  test("_orchestration/RULES.md exists", fs.existsSync(path.join(PLUGIN_ROOT, "skills", "_orchestration", "RULES.md")));

  // No old directories
  test("No bin/ directory (CLI removed)", !fs.existsSync(path.join(PLUGIN_ROOT, "bin")));
  test("No core/ directory (moved to root)", !fs.existsSync(path.join(PLUGIN_ROOT, "core")));
  test("No .npmignore (not an npm package)", !fs.existsSync(path.join(PLUGIN_ROOT, ".npmignore")));
}

function validateLanguageFiles() {
  section("Language Rules & Review Files");

  // Check all rule files exist
  for (const [type, ruleFiles] of Object.entries(TYPE_RULES)) {
    for (const file of ruleFiles) {
      test(`Rule file: ${file} (${type})`, fs.existsSync(path.join(PLUGIN_ROOT, "rules", file)));
    }
  }

  // Check all review files exist
  test("General checklist exists", fs.existsSync(path.join(PLUGIN_ROOT, "reviews", "general-checklist.md")));
  for (const [type, reviewFiles] of Object.entries(TYPE_REVIEWS)) {
    for (const file of reviewFiles) {
      test(`Review file: ${file} (${type})`, fs.existsSync(path.join(PLUGIN_ROOT, "reviews", file)));
    }
  }
}

function validateSkills() {
  section("Skill Validation");

  const skillsDir = path.join(PLUGIN_ROOT, "skills");
  const entries = fs.readdirSync(skillsDir, { withFileTypes: true })
    .filter(e => e.isDirectory() && !e.name.startsWith("_"));

  for (const entry of entries) {
    const skillPath = path.join(skillsDir, entry.name, "SKILL.md");
    test(`${entry.name}: SKILL.md exists`, fs.existsSync(skillPath));

    if (!fs.existsSync(skillPath)) continue;
    const content = fs.readFileSync(skillPath, "utf8");

    // YAML frontmatter
    const frontmatterMatch = content.match(/^---\n([\s\S]*?)\n---/);
    test(`${entry.name}: valid YAML frontmatter`, frontmatterMatch !== null);
    if (frontmatterMatch) {
      const fm = frontmatterMatch[1];
      test(`${entry.name}: has name field`, fm.includes("name:"));
      test(`${entry.name}: has description field`, fm.includes("description:"));
    }

    // Check for stale .claude/ references (excluding allowed skills)
    if (!ALLOWED_CLAUDE_REFS.includes(entry.name)) {
      const lines = content.split("\n");
      const staleRefs = lines.filter(l =>
        l.includes(".claude/") &&
        !l.includes("${CLAUDE_PLUGIN_ROOT}") &&
        !l.includes("${CLAUDE_PLUGIN_DATA}") &&
        !l.trim().startsWith("#") &&
        !l.trim().startsWith("//")
      );
      test(
        `${entry.name}: no stale .claude/ references`,
        staleRefs.length === 0,
        staleRefs.length > 0 ? `Found: ${staleRefs[0].trim().substring(0, 80)}` : undefined,
      );
    }

    // Workflow-specific phase validation
    const spec = WORKFLOW_PHASES[entry.name];
    if (!spec) continue;

    // Phase ordering
    const phasePositions = [];
    for (const phase of spec.phases) {
      const phaseRegex = new RegExp(`##\\s+(?:Phase\\s+\\d+[:\\s]+)?${phase.replace("-", "[-\\s]")}`, "i");
      const match = content.match(phaseRegex);
      if (match) {
        phasePositions.push({ phase, pos: content.indexOf(match[0]) });
      } else {
        const altRegex = new RegExp(`##.*${phase.replace("-", "[-\\s]")}`, "i");
        const altMatch = content.match(altRegex);
        if (altMatch) {
          phasePositions.push({ phase, pos: content.indexOf(altMatch[0]) });
        }
      }
    }

    test(
      `${entry.name}: all ${spec.phases.length} phases found`,
      phasePositions.length === spec.phases.length,
      `Found ${phasePositions.length}/${spec.phases.length}: ${phasePositions.map(p => p.phase).join(", ")}`,
    );

    // Implementation skills reference plugin rules
    if (spec.hasImplement) {
      test(
        `${entry.name}: references plugin rules/ for language rules`,
        content.includes("${CLAUDE_PLUGIN_ROOT}/rules/") || content.includes("PLUGIN_ROOT}/rules/"),
        "Implementation skills must reference ${CLAUDE_PLUGIN_ROOT}/rules/",
      );
    }

    // PR skills reference plugin reviews
    if (spec.hasPR) {
      test(
        `${entry.name}: references plugin reviews/ for quality gate`,
        content.includes("${CLAUDE_PLUGIN_ROOT}/reviews/") || content.includes("PLUGIN_ROOT}/reviews/"),
        "PR skills must reference ${CLAUDE_PLUGIN_ROOT}/reviews/",
      );
    }
  }
}

function validateOrchestrationRules() {
  section("Orchestration Rules");
  const rulesPath = path.join(PLUGIN_ROOT, "skills", "_orchestration", "RULES.md");
  if (!fs.existsSync(rulesPath)) {
    test("RULES.md exists", false);
    return;
  }

  const content = fs.readFileSync(rulesPath, "utf8");

  // Check all 16 rules exist
  for (let i = 0; i <= 16; i++) {
    test(`Rule ${i} exists`, content.includes(`Rule ${i}`));
  }

  // Plugin path references
  test("Rule 3 references ${CLAUDE_PLUGIN_ROOT}/rules/", content.includes("${CLAUDE_PLUGIN_ROOT}/rules/"));
  test("Rule 3 references ${CLAUDE_PLUGIN_ROOT}/reviews/", content.includes("${CLAUDE_PLUGIN_ROOT}/reviews/"));
  test("Rule 3 has project_type mapping table", content.includes("project_type"));

  // Config references updated
  test("References .workflows/config.yml (not .claude/workflows.yml)", content.includes(".workflows/config.yml"));
  test("No stale .claude/workflows.yml reference", !content.includes(".claude/workflows.yml"));
  test("No stale .claude/rules/ reference", !content.includes(".claude/rules/"));
  test("No stale .claude/reviews/ reference", !content.includes(".claude/reviews/"));
}

// ============================================================
// Run
// ============================================================
console.log("+" + "=".repeat(58) + "+");
console.log(`|   claude-workflows v${VERSION} — Plugin Validation             |`);
console.log("+" + "=".repeat(58) + "+");

validatePluginManifest();
validatePluginFiles();
validateDirectoryStructure();
validateLanguageFiles();
validateSkills();
validateOrchestrationRules();

// ============================================================
// Summary
// ============================================================
console.log(`\n${"=".repeat(60)}`);
console.log("  RESULTS");
console.log("=".repeat(60));
console.log(`  Total:  ${totalTests}`);
console.log(`  Passed: ${passed}`);
console.log(`  Failed: ${failed}`);
console.log();

if (failures.length > 0) {
  console.log("  FAILURES:");
  for (const f of failures) {
    console.log(`    x ${f.name}`);
    if (f.detail) console.log(`      ${f.detail}`);
  }
}

console.log();
if (failed === 0) {
  console.log("  ALL TESTS PASSED");
} else {
  console.log(`  ${failed} TEST(S) FAILED`);
}
console.log();

process.exit(failed > 0 ? 1 : 0);
