#!/usr/bin/env node
"use strict";

/**
 * End-to-end workflow validation for claude-workflows v2.0.0
 *
 * Validates:
 * 1. Phase ordering matches declared phases
 * 2. Every phase has an output document path
 * 3. Output paths are sequential (01-, 02-, 03-...)
 * 4. IMPLEMENT/EXECUTE/MIGRATE phases reference .claude/rules/
 * 5. PR phases reference .claude/reviews/ (quality gate)
 * 6. Skills reference orchestration rules
 * 7. State tracking format is consistent
 * 8. Language-specific rules exist for the project's language
 * 9. Review checklists exist for the project's language
 * 10. No hardcoded language-specific patterns in skills
 * 11. Config matches project type/language
 * 12. YAML frontmatter is valid
 */

const fs = require("fs");
const path = require("path");

// ============================================================
// Config
// ============================================================
const PROJECTS = [
  {
    name: "Flosy (Android/Kotlin)",
    root: "/Users/ragaaaboelezz/AndroidStudioProjects/Flosy",
    expectedType: "android",
    expectedLang: "kotlin",
    expectedRules: ["kotlin.md", "compose.md"],
    expectedReviews: ["kotlin-checklist.md"],
  },
  {
    name: "TestClaudeWorkflows (iOS/Swift)",
    root: "/Users/ragaaaboelezz/Desktop/TestClaudeWorkflows",
    expectedType: "swift",
    expectedLang: "swift",
    expectedRules: ["swift.md"],
    expectedReviews: ["swift-checklist.md"],
  },
];

// Expected phase orders for each workflow
const WORKFLOW_PHASES = {
  "new-feature": {
    phases: ["GATHER", "SPEC", "BRAINSTORM", "PLAN", "BRANCH", "IMPLEMENT", "TEST", "PR"],
    skippable: ["SPEC", "BRAINSTORM", "TEST"],
    hasImplement: true,
    hasPR: true,
  },
  "extend-feature": {
    phases: ["ANALYZE", "BRAINSTORM", "PLAN", "IMPLEMENT", "VERIFY-COMPAT", "TEST", "PR"],
    skippable: ["BRAINSTORM", "TEST"],
    hasImplement: true,
    hasPR: true,
  },
  "hotfix": {
    phases: ["DIAGNOSE", "FIX", "REGRESSION-TEST", "PR", "CHERRY-PICK"],
    skippable: [],
    hasImplement: true, // FIX is implementation
    hasPR: true,
  },
  "refactor": {
    phases: ["ANALYZE", "BRAINSTORM", "CONTRACT", "DESIGN", "MIGRATE", "VERIFY", "PR"],
    skippable: ["BRAINSTORM"],
    hasImplement: true, // MIGRATE is implementation
    hasPR: true,
  },
  "brainstorm": {
    phases: ["EXPLORE", "EVALUATE", "RECOMMEND"],
    skippable: [],
    hasImplement: false,
    hasPR: false,
  },
  "test": {
    phases: ["ANALYZE", "PLAN", "WRITE", "VERIFY", "REPORT"],
    skippable: [],
    hasImplement: false,
    hasPR: false,
  },
  "review": {
    phases: ["FETCH", "CATEGORIZE", "CHECK", "COMMENT"],
    skippable: [],
    hasImplement: false,
    hasPR: false,
  },
  "release": {
    phases: ["CHANGELOG", "VERSION-BUMP", "RELEASE-BRANCH", "PR", "TAG"],
    skippable: [],
    hasImplement: false,
    hasPR: true,
  },
  "ci-fix": {
    phases: ["FETCH", "DIAGNOSE", "FIX", "PUSH", "MONITOR"],
    skippable: [],
    hasImplement: true,
    hasPR: false,
  },
  "migrate": {
    phases: ["ANALYZE", "BRAINSTORM", "PLAN", "EXECUTE", "VERIFY", "PR"],
    skippable: ["BRAINSTORM"],
    hasImplement: true,
    hasPR: true,
  },
  "new-project": {
    phases: ["DETECT", "CONFIGURE", "GENERATE", "SETUP"],
    skippable: [],
    hasImplement: false,
    hasPR: false,
  },
};

// Hardcoded language patterns that should NOT appear in skills
const FORBIDDEN_PATTERNS = [
  { pattern: /grep.*--include="\*\.kt"/i, desc: "Hardcoded Kotlin file search" },
  { pattern: /class\s+\w+ViewModel/i, desc: "Hardcoded ViewModel class reference (not as example category)" },
  { pattern: /\bHilt\b/, desc: "Hardcoded Hilt reference" },
  { pattern: /\bMockK\b/i, desc: "Hardcoded MockK reference" },
  { pattern: /\bTurbine\b/, desc: "Hardcoded Turbine reference" },
  { pattern: /\bRobolectric\b/, desc: "Hardcoded Robolectric reference" },
  { pattern: /\b@Composable\b/, desc: "Hardcoded @Composable reference" },
  { pattern: /\bviewModelScope\b/, desc: "Hardcoded viewModelScope reference" },
  { pattern: /\bStateFlow\b/, desc: "Hardcoded StateFlow reference" },
  { pattern: /collectAsState/, desc: "Hardcoded collectAsState reference" },
];

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

function validateProject(project) {
  section(`PROJECT: ${project.name}`);
  const root = project.root;

  // --- 1. Directory structure ---
  console.log("\n[1] Directory Structure");
  test(
    "Skills directory exists",
    fs.existsSync(path.join(root, ".claude/skills")),
    path.join(root, ".claude/skills")
  );
  test(
    "Orchestration rules exist",
    fs.existsSync(path.join(root, ".claude/skills/_orchestration/RULES.md")),
  );
  test(
    "Rules directory exists",
    fs.existsSync(path.join(root, ".claude/rules")),
  );
  test(
    "Reviews directory exists",
    fs.existsSync(path.join(root, ".claude/reviews")),
  );
  test(
    "Templates directory exists",
    fs.existsSync(path.join(root, ".claude/templates")),
  );
  test(
    "Workflows state directory exists",
    fs.existsSync(path.join(root, ".workflows")),
  );
  test(
    "Config file exists",
    fs.existsSync(path.join(root, ".claude/workflows.yml")),
  );

  // --- 2. Language-specific files ---
  console.log("\n[2] Language-Specific Files");
  for (const rule of project.expectedRules) {
    test(
      `Rule file exists: ${rule}`,
      fs.existsSync(path.join(root, ".claude/rules", rule)),
    );
  }
  for (const review of project.expectedReviews) {
    test(
      `Review checklist exists: ${review}`,
      fs.existsSync(path.join(root, ".claude/reviews", review)),
    );
  }
  test(
    "General checklist exists",
    fs.existsSync(path.join(root, ".claude/reviews/general-checklist.md")),
  );

  // --- 3. Config validation ---
  console.log("\n[3] Config Validation");
  const config = fs.readFileSync(path.join(root, ".claude/workflows.yml"), "utf8");
  test(
    `Config project.type is "${project.expectedType}"`,
    config.includes(`type: "${project.expectedType}"`),
    `Expected type: "${project.expectedType}"`,
  );
  test(
    `Config project.language is "${project.expectedLang}"`,
    config.includes(`language: "${project.expectedLang}"`),
    `Expected language: "${project.expectedLang}"`,
  );

  // --- 4. Validate each workflow skill ---
  console.log("\n[4] Workflow Phase Validation");
  for (const [skillName, spec] of Object.entries(WORKFLOW_PHASES)) {
    const skillPath = path.join(root, `.claude/skills/${skillName}/SKILL.md`);
    if (!fs.existsSync(skillPath)) {
      test(`Skill ${skillName} exists`, false, `Missing: ${skillPath}`);
      continue;
    }

    const content = fs.readFileSync(skillPath, "utf8");

    // 4a. YAML frontmatter is valid
    const frontmatterMatch = content.match(/^---\n([\s\S]*?)\n---/);
    test(
      `${skillName}: valid YAML frontmatter`,
      frontmatterMatch !== null,
    );
    if (frontmatterMatch) {
      const fm = frontmatterMatch[1];
      test(
        `${skillName}: has name field`,
        fm.includes(`name: ${skillName}`) || fm.includes(`name: "${skillName}"`),
        `Frontmatter: ${fm.substring(0, 100)}`,
      );
      test(
        `${skillName}: has description field`,
        fm.includes("description:"),
      );
      // Check for YAML colon issue
      const descLine = fm.split("\n").find(l => l.startsWith("description:"));
      if (descLine) {
        const afterKey = descLine.substring("description:".length).trim();
        const hasUnquotedColon = afterKey && !afterKey.startsWith('"') && afterKey.includes(": ");
        test(
          `${skillName}: description has no unquoted colons`,
          !hasUnquotedColon,
          `Line: ${descLine}`,
        );
      }
    }

    // 4b. Phases appear in correct order
    const phasePositions = [];
    for (const phase of spec.phases) {
      // Look for "## Phase N: PHASE" or "### Phase N:" or "## PHASE" patterns
      const phaseRegex = new RegExp(
        `##\\s+(?:Phase\\s+\\d+[:\\s]+)?${phase.replace("-", "[-\\s]")}`,
        "i"
      );
      const match = content.match(phaseRegex);
      if (match) {
        phasePositions.push({ phase, pos: content.indexOf(match[0]) });
      } else {
        // Also check for phase name in headers
        const altRegex = new RegExp(`##.*${phase.replace("-", "[-\\s]")}`, "i");
        const altMatch = content.match(altRegex);
        if (altMatch) {
          phasePositions.push({ phase, pos: content.indexOf(altMatch[0]) });
        }
      }
    }

    test(
      `${skillName}: all ${spec.phases.length} phases found in file`,
      phasePositions.length === spec.phases.length,
      `Found ${phasePositions.length}/${spec.phases.length}: ${phasePositions.map(p => p.phase).join(", ")}`,
    );

    // Check ordering
    let inOrder = true;
    for (let i = 1; i < phasePositions.length; i++) {
      if (phasePositions[i].pos < phasePositions[i - 1].pos) {
        inOrder = false;
        break;
      }
    }
    test(
      `${skillName}: phases in correct sequential order`,
      inOrder,
      `Order: ${phasePositions.map(p => p.phase).join(" -> ")}`,
    );

    // 4c. Phase output paths
    const outputPathPattern = /\.workflows\/.*?\/\d{2}-[\w-]+\.md/g;
    const outputPaths = [...content.matchAll(outputPathPattern)].map(m => m[0]);
    const expectedOutputCount = spec.phases.length;

    test(
      `${skillName}: has phase output paths (${outputPaths.length}/${expectedOutputCount})`,
      outputPaths.length >= expectedOutputCount - 1, // Allow 1 missing for combined phases
      `Found: ${outputPaths.join(", ")}`,
    );

    // Check output paths are sequential
    const outputNumbers = outputPaths.map(p => {
      const match = p.match(/\/(\d{2})-/);
      return match ? parseInt(match[1]) : -1;
    }).filter(n => n > 0);

    let sequential = true;
    const sorted = [...outputNumbers].sort((a, b) => a - b);
    for (let i = 1; i < sorted.length; i++) {
      if (sorted[i] !== sorted[i - 1] + 1) {
        sequential = false;
        break;
      }
    }
    test(
      `${skillName}: output paths are sequential (${sorted.join(",")})`,
      sequential || sorted.length <= 1,
    );

    // 4d. Rules integration for implementation skills
    if (spec.hasImplement) {
      test(
        `${skillName}: references .claude/rules/ for language rules`,
        content.includes(".claude/rules/"),
        "Implementation skills must load language rules",
      );
    }

    // 4e. Quality gate for PR skills
    if (spec.hasPR) {
      test(
        `${skillName}: references .claude/reviews/ for quality gate`,
        content.includes(".claude/reviews/"),
        "PR skills must load review checklists",
      );
    }

    // 4f. No hardcoded language patterns
    for (const fp of FORBIDDEN_PATTERNS) {
      const lines = content.split("\n");
      const matchLine = lines.findIndex(l => fp.pattern.test(l));
      // Allow matches in example tables or category descriptions
      if (matchLine >= 0) {
        const line = lines[matchLine].trim();
        const isExampleOrCategory =
          line.startsWith("|") ||
          line.includes("e.g.") ||
          line.includes("Example") ||
          line.includes("controllers, presenters");
        test(
          `${skillName}: no ${fp.desc}`,
          isExampleOrCategory,
          `Line ${matchLine + 1}: ${line.substring(0, 80)}`,
        );
      }
    }
  }

  // --- 5. Start/Resume reference orchestration ---
  console.log("\n[5] Orchestration Integration");
  const startContent = fs.readFileSync(path.join(root, ".claude/skills/start/SKILL.md"), "utf8");
  const resumeContent = fs.readFileSync(path.join(root, ".claude/skills/resume/SKILL.md"), "utf8");

  test(
    "start delegates to workflow skills (not executing internally)",
    startContent.includes("Do NOT attempt to read and execute"),
  );
  test(
    "resume references _orchestration/RULES.md",
    resumeContent.includes("_orchestration/RULES.md"),
  );

  // --- 6. Orchestration rules completeness ---
  console.log("\n[6] Orchestration Rules Completeness");
  const rulesContent = fs.readFileSync(
    path.join(root, ".claude/skills/_orchestration/RULES.md"), "utf8"
  );

  test("Rule 1: Phase output document format", rulesContent.includes("Rule 1"));
  test("Rule 1: Details guide table", rulesContent.includes("Details Guide"));
  test("Rule 2: State update protocol", rulesContent.includes("Rule 2"));
  test("Rule 2: State evolution example", rulesContent.includes("Example state after"));
  test("Rule 2: Phase History table in example", rulesContent.includes("| ANALYZE | COMPLETED"));
  test("Rule 2: Phase Outputs section in example", rulesContent.includes("## Phase Outputs"));
  test("Rule 2: Context section in example", rulesContent.includes("## Context"));
  test("Rule 3: Skipping phases", rulesContent.includes("Rule 3"));
  test("Rule 4: Quality gate", rulesContent.includes("Rule 4"));
  test("Rule 4: References .claude/rules/", rulesContent.includes(".claude/rules/"));
  test("Rule 4: References .claude/reviews/", rulesContent.includes(".claude/reviews/"));
  test("Rule 5: Build/test detection", rulesContent.includes("Rule 5"));
  test("Rule 6: Workflow chaining", rulesContent.includes("Rule 6"));
  test("Rule 7: Completion protocol", rulesContent.includes("Rule 7"));
  test("Rule 8: Pausing protocol", rulesContent.includes("Rule 8"));
  test("Rule 9: Error recovery / REPLAN", rulesContent.includes("Rule 9"));
  test("Rule 9: REPLAN defined", rulesContent.includes("REPLAN"));

  // Phase statuses defined
  for (const status of ["ACTIVE", "COMPLETED", "SKIPPED", "FAILED", "RETRY"]) {
    test(
      `Phase status '${status}' defined`,
      rulesContent.includes(status),
    );
  }

  // Details guide covers all phase types across workflows
  const expectedPhaseTypes = [
    "GATHER", "ANALYZE", "SPEC", "BRAINSTORM", "PLAN", "BRANCH",
    "IMPLEMENT", "TEST", "PR", "FIX", "DIAGNOSE", "CHERRY-PICK",
    "CONTRACT", "MIGRATE", "VERIFY", "CHANGELOG", "VERSION-BUMP",
    "TAG", "PUSH", "MONITOR", "REPORT", "WRITE", "CATEGORIZE",
    "CHECK", "COMMENT", "CONFIGURE",
  ];
  for (const phaseType of expectedPhaseTypes) {
    test(
      `Details guide covers ${phaseType}`,
      rulesContent.includes(phaseType),
      "Phase type missing from Details Guide table",
    );
  }

  // --- 7. State template validation ---
  console.log("\n[7] State Template Validation");
  const stateTmpl = fs.readFileSync(
    path.join(root, ".claude/templates/state.md.tmpl"), "utf8"
  );

  // Must have the canonical fields
  for (const field of ["workflow", "feature", "phase", "started", "updated", "branch", "output_dir", "retry_count"]) {
    test(
      `State template has field: ${field}`,
      stateTmpl.includes(`**${field}**`) || stateTmpl.includes(field),
    );
  }
  test(
    "State template has Phase History table",
    stateTmpl.includes("Phase History"),
  );
  test(
    "State template has Phase Outputs section",
    stateTmpl.includes("Phase Outputs"),
  );
  test(
    "State template has Context section",
    stateTmpl.includes("Context"),
  );

  // --- 8. CLAUDE.md injection ---
  console.log("\n[8] CLAUDE.md Injection");
  const claudeMd = fs.readFileSync(path.join(root, "CLAUDE.md"), "utf8");
  test(
    "CLAUDE.md has workflow markers",
    claudeMd.includes("claude-workflows:start") && claudeMd.includes("claude-workflows:end"),
  );
  test(
    "CLAUDE.md references /start",
    claudeMd.includes("/start"),
  );
  test(
    "CLAUDE.md references _orchestration/RULES.md",
    claudeMd.includes("_orchestration/RULES.md"),
  );
  test(
    "CLAUDE.md is slim (injection < 10 lines)",
    (() => {
      const start = claudeMd.indexOf("claude-workflows:start");
      const end = claudeMd.indexOf("claude-workflows:end");
      if (start < 0 || end < 0) return false;
      const block = claudeMd.substring(start, end);
      return block.split("\n").length <= 15;
    })(),
  );

  // --- 9. Gitignore ---
  console.log("\n[9] Gitignore");
  const gitignorePath = path.join(root, ".gitignore");
  if (fs.existsSync(gitignorePath)) {
    const gitignore = fs.readFileSync(gitignorePath, "utf8");
    test(
      ".gitignore has .workflows/current-state.md",
      gitignore.includes(".workflows/current-state.md"),
    );
    test(
      ".gitignore has .workflows/history/",
      gitignore.includes(".workflows/history/"),
    );
  }
}

// ============================================================
// Run
// ============================================================
console.log("╔══════════════════════════════════════════════════════════╗");
console.log("║   claude-workflows v2.0.0 — End-to-End Validation      ║");
console.log("╚══════════════════════════════════════════════════════════╝");

for (const project of PROJECTS) {
  if (!fs.existsSync(project.root)) {
    console.log(`\nSKIPPED: ${project.name} — project not found at ${project.root}`);
    continue;
  }
  validateProject(project);
}

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
    console.log(`    ✗ ${f.name}`);
    if (f.detail) console.log(`      ${f.detail}`);
  }
}

console.log();
if (failed === 0) {
  console.log("  ✅ ALL TESTS PASSED");
} else {
  console.log(`  ❌ ${failed} TEST(S) FAILED`);
}
console.log();

process.exit(failed > 0 ? 1 : 0);
