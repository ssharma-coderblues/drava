#!/usr/bin/env node
// pravartak: language-pack=typescript helper=delta-coverage
//
// Delta coverage (Gandiva lesson GAN-38): enforce the coverage threshold on CHANGED
// production files only — files modified on the current branch relative to a base ref —
// so pre-existing, untouched, sub-threshold code does not deadlock the first story of a
// brownfield adoption. Whole-repo absolute coverage is intentionally NOT enforced.
//
// Reads Istanbul/V8 coverage-final.json (emitted by vitest's coverage provider), computes
// per-file line coverage for the changed set, and fails if any changed production file is
// below the threshold.
//
// Usage:
//   node delta-coverage.mjs --coverage <coverage-final.json> --base <git-ref> --threshold <pct>
//
// Exit codes:
//   0  all changed production files meet the threshold (or none needed measuring)
//   1  at least one changed production file is below the threshold
//   5  no changed production files to measure (vacuous pass; caller treats as SKIP)
//
// Notes:
//   - "Production files" = changed files under a package/app src/ that are .ts/.tsx and not
//     test files (*.test.ts, *.spec.ts) and not type-only declarations (*.d.ts).
//   - Changed set = `git diff --name-only <base>...HEAD` plus currently-staged/unstaged
//     changes, so it works both pre-commit (hook) and post-commit (loop re-gate).

import { execSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { resolve, relative } from "node:path";

function parseArgs(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i += 2) {
    const key = argv[i]?.replace(/^--/, "");
    if (key) args[key] = argv[i + 1];
  }
  return args;
}

const { coverage, base, threshold } = parseArgs(process.argv.slice(2));
const THRESHOLD = Number(threshold ?? "95");
const repoRoot = execSync("git rev-parse --show-toplevel").toString().trim();

function isProductionFile(path) {
  if (!/\.(ts|tsx)$/.test(path)) return false;
  if (/\.(test|spec)\.tsx?$/.test(path)) return false;
  if (/\.d\.ts$/.test(path)) return false;
  // Must live under a src/ (package, app, or repo-root src).
  return /(^|\/)src\//.test(path);
}

function changedFiles(baseRef) {
  const out = new Set();
  const add = (cmd) => {
    try {
      execSync(cmd, { cwd: repoRoot })
        .toString()
        .split("\n")
        .map((s) => s.trim())
        .filter(Boolean)
        .forEach((f) => out.add(f));
    } catch {
      /* base ref may not exist on a fresh repo; ignore */
    }
  };
  // Committed changes vs base, plus working-tree changes (staged + unstaged).
  add(`git diff --name-only ${baseRef}...HEAD`);
  add(`git diff --name-only HEAD`);
  add(`git diff --name-only --cached`);
  return [...out].filter(isProductionFile);
}

function lineCoverageForFile(fileCov) {
  // Istanbul format: statementMap + s (hit counts). Approximate line coverage via statements.
  const counts = Object.values(fileCov.s ?? {});
  if (counts.length === 0) return null; // no statements instrumented
  const covered = counts.filter((c) => c > 0).length;
  return (covered / counts.length) * 100;
}

let coverageData;
try {
  coverageData = JSON.parse(readFileSync(coverage, "utf8"));
} catch (err) {
  console.error(`delta-coverage: cannot read coverage file ${coverage}: ${err.message}`);
  process.exit(1);
}

// Normalize coverage keys to repo-relative paths for matching against git output.
const covByRel = new Map();
for (const [absPath, fileCov] of Object.entries(coverageData)) {
  const rel = relative(repoRoot, resolve(absPath));
  covByRel.set(rel, fileCov);
}

const changed = changedFiles(base ?? "HEAD~1");
if (changed.length === 0) {
  console.log("delta-coverage: no changed production files to measure.");
  process.exit(5);
}

const failures = [];
let measured = 0;
for (const file of changed) {
  const fileCov = covByRel.get(file);
  if (!fileCov) {
    // A changed production file with NO coverage entry means it was never exercised by any
    // test — that is a hard failure under delta coverage (new code must be tested).
    failures.push({ file, pct: 0, reason: "no coverage (untested changed file)" });
    measured++;
    continue;
  }
  const pct = lineCoverageForFile(fileCov);
  if (pct === null) continue; // nothing instrumented (e.g. types only) — skip
  measured++;
  if (pct < THRESHOLD) {
    failures.push({ file, pct: pct.toFixed(1), reason: `below ${THRESHOLD}%` });
  }
}

if (measured === 0) {
  console.log("delta-coverage: changed files had nothing instrumentable — vacuous pass.");
  process.exit(5);
}

if (failures.length > 0) {
  console.error(`delta-coverage: ${failures.length} changed file(s) below ${THRESHOLD}%:`);
  for (const f of failures) console.error(`  ${f.file}  (${f.pct}% — ${f.reason})`);
  process.exit(1);
}

console.log(`delta-coverage: all ${measured} changed production file(s) ≥ ${THRESHOLD}%.`);
process.exit(0);
