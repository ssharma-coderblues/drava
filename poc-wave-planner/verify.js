#!/usr/bin/env node
/**
 * Verify planner.js output against expected-output.json
 * Exit 0 = match, Exit 1 = mismatch
 */

import { readFileSync } from "fs";
import { resolve, dirname } from "path";
import { fileURLToPath } from "url";
import { execSync } from "child_process";

const __dirname = dirname(fileURLToPath(import.meta.url));

const expected = JSON.parse(
  readFileSync(resolve(__dirname, "expected-output.json"), "utf8")
);

const actualRaw = execSync("node " + resolve(__dirname, "planner.js"), {
  encoding: "utf8",
  stdio: ["pipe", "pipe", "pipe"],
});

const actual = JSON.parse(actualRaw);

let passed = 0;
let failed = 0;

function check(label, actual, expected) {
  const a = JSON.stringify(actual);
  const e = JSON.stringify(expected);
  if (a === e) {
    console.log(`  PASS  ${label}`);
    passed++;
  } else {
    console.error(`  FAIL  ${label}`);
    console.error(`         expected: ${e}`);
    console.error(`         actual:   ${a}`);
    failed++;
  }
}

console.log("\n=== Wave-Planner Verification ===\n");

check("wave_count", actual.wave_count, expected.wave_count);
check("topological_order", actual.topological_order, expected.topological_order);

for (const expWave of expected.waves) {
  const actWave = actual.waves.find((w) => w.wave === expWave.wave);
  check(
    `wave ${expWave.wave} stories`,
    actWave?.stories.map((s) => ({ id: s.id, linearId: s.linearId, execution: s.execution })),
    expWave.stories
  );
  check(
    `wave ${expWave.wave} collisions`,
    actWave?.collisions,
    expWave.collisions
  );
}

for (const expGroup of expected.pravartak_execution_plan) {
  const actGroup = actual.pravartak_execution_plan.find(
    (g) => g.wave === expGroup.wave && g.type === expGroup.type
  );
  check(
    `execution plan wave ${expGroup.wave} type`,
    actGroup?.type,
    expGroup.type
  );
  check(
    `execution plan wave ${expGroup.wave} handoffs`,
    actGroup?.items.map((s) => s.handoff),
    expGroup.items.map((s) => s.handoff)
  );
}

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed > 0 ? 1 : 0);
