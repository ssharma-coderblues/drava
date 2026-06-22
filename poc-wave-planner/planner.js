#!/usr/bin/env node
/**
 * Drava Wave-Planner — core algorithm
 *
 * Input:  stories.json
 * Output: ordered wave plan (stdout JSON + human-readable summary)
 *
 * Algorithm:
 *  1. Build dependency graph (adjacency list)
 *  2. Topological sort via Kahn's algorithm
 *  3. Assign each story to a wave (= longest path from root)
 *  4. Within each wave, detect file-touch collisions
 *  5. Split colliding stories into sequential sub-groups
 *
 * Integration point with Pravartak:
 *  For each wave group, emit a runtime-neutral handoff plan.
 *  Pravartak is a project library/playbook, not a daemon CLI, so the planner
 *  does not invent spawn commands. It emits ordered prompts that a Pravartak
 *  autonomous runtime can execute after scaffold + architect review.
 */

import { readFileSync } from "fs";
import { resolve, dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));

function buildDependencyGraph(stories) {
  const byId = new Map(stories.map((s) => [s.id, s]));
  const inDegree = new Map(stories.map((s) => [s.id, 0]));
  const dependents = new Map(stories.map((s) => [s.id, []]));

  for (const story of stories) {
    for (const dep of story.depends_on) {
      if (!byId.has(dep)) {
        throw new Error(`Story ${story.id} depends on unknown story ${dep}`);
      }
      inDegree.set(story.id, inDegree.get(story.id) + 1);
      dependents.get(dep).push(story.id);
    }
  }

  return { byId, inDegree, dependents };
}

function topoSort(stories, graph) {
  const { inDegree, dependents } = graph;
  const inDegreeCopy = new Map(inDegree);
  const queue = [];
  const order = [];

  for (const [id, deg] of inDegreeCopy) {
    if (deg === 0) queue.push(id);
  }

  while (queue.length > 0) {
    const id = queue.shift();
    order.push(id);
    for (const dependent of dependents.get(id)) {
      const newDeg = inDegreeCopy.get(dependent) - 1;
      inDegreeCopy.set(dependent, newDeg);
      if (newDeg === 0) queue.push(dependent);
    }
  }

  if (order.length !== stories.length) {
    const unresolved = stories
      .map((s) => s.id)
      .filter((id) => !order.includes(id));
    throw new Error(`Cycle detected in dependency graph involving: ${unresolved.join(", ")}`);
  }

  return order;
}

function assignWaves(topoOrder, graph) {
  const { byId } = graph;
  const waveOf = new Map();

  for (const id of topoOrder) {
    const story = byId.get(id);
    const maxDepWave = story.depends_on.reduce(
      (max, dep) => Math.max(max, waveOf.get(dep) ?? 0),
      0
    );
    waveOf.set(id, maxDepWave + 1);
  }

  return waveOf;
}

function detectCollisions(wavesMap, byId) {
  const waveGroups = new Map();
  for (const [id, wave] of wavesMap) {
    if (!waveGroups.has(wave)) waveGroups.set(wave, []);
    waveGroups.get(wave).push(id);
  }

  const result = [];

  for (const [waveNum, storyIds] of [...waveGroups.entries()].sort(
    ([a], [b]) => a - b
  )) {
    const fileTouched = new Map();
    const collisions = [];

    for (const id of storyIds) {
      const story = byId.get(id);
      for (const file of story.touches) {
        if (fileTouched.has(file)) {
          collisions.push({
            file,
            stories: [fileTouched.get(file), id],
          });
        } else {
          fileTouched.set(file, id);
        }
      }
    }

    if (collisions.length === 0) {
      result.push({
        wave: waveNum,
        parallel: storyIds,
        sequential_groups: null,
        collisions: [],
      });
    } else {
      const collidingIds = new Set(collisions.flatMap((c) => c.stories));
      const safe = storyIds.filter((id) => !collidingIds.has(id));
      const sequential = [...collidingIds];

      result.push({
        wave: waveNum,
        parallel: safe,
        sequential_groups: sequential,
        collisions: collisions.map((c) => ({
          file: c.file,
          between: c.stories,
        })),
      });
    }
  }

  return result;
}

function buildPravartakExecutionPlan(wavePlan, byId) {
  const groups = [];

  for (const wave of wavePlan) {
    if (wave.parallel.length > 0) {
      groups.push({
        wave: wave.wave,
        type: "parallel",
        reason: "No dependency or file-touch conflicts",
        items: wave.parallel.map((id) => ({
          storyId: id,
          linearId: byId.get(id).linearId,
          handoff: `Execute reviewed story ${byId.get(id).linearId} via the Pravartak autonomous-loop protocol.`,
        })),
      });
    }

    if (wave.sequential_groups && wave.sequential_groups.length > 0) {
      groups.push({
        wave: wave.wave,
        type: "sequential",
        reason: `File-touch collision on: ${wave.collisions.map((c) => c.file).join(", ")}`,
        items: wave.sequential_groups.map((id) => ({
          storyId: id,
          linearId: byId.get(id).linearId,
          handoff: `Execute reviewed story ${byId.get(id).linearId} via the Pravartak autonomous-loop protocol.`,
          note: "Wait for previous story to complete and merge to the integration branch before starting this one",
        })),
      });
    }
  }

  return groups;
}

function main() {
  const manifestPath = resolve(__dirname, "stories.json");
  const manifest = JSON.parse(readFileSync(manifestPath, "utf8"));
  const { stories } = manifest;

  console.error(`\nDrava Wave-Planner — processing ${stories.length} stories\n`);

  const graph = buildDependencyGraph(stories);
  const topoOrder = topoSort(stories, graph);
  const wavesMap = assignWaves(topoOrder, graph);
  const wavePlan = detectCollisions(wavesMap, graph.byId);
  const executionPlan = buildPravartakExecutionPlan(wavePlan, graph.byId);

  const output = {
    project: manifest.project,
    analyzed_at: new Date().toISOString(),
    story_count: stories.length,
    wave_count: wavePlan.length,
    topological_order: topoOrder,
    waves: wavePlan.map((w) => ({
      wave: w.wave,
      stories: [
        ...w.parallel.map((id) => ({
          id,
          linearId: graph.byId.get(id).linearId,
          execution: "parallel",
        })),
        ...(w.sequential_groups ?? []).map((id) => ({
          id,
          linearId: graph.byId.get(id).linearId,
          execution: "sequential",
        })),
      ],
      collisions: w.collisions,
    })),
    pravartak_execution_plan: executionPlan,
  };

  console.log(JSON.stringify(output, null, 2));

  console.error("\n=== WAVE EXECUTION PLAN ===");
  for (const wave of wavePlan) {
    const waveLabel = `Wave ${wave.wave}`;
    if (wave.collisions.length > 0) {
      console.error(
        `\n${waveLabel} — COLLISION DETECTED on: ${wave.collisions.map((c) => c.file).join(", ")}`
      );
      if (wave.parallel.length > 0) {
        console.error(
          `  PARALLEL (safe):   ${wave.parallel.map((id) => `${id}/${graph.byId.get(id).linearId}`).join(", ")}`
        );
      }
      console.error(
        `  SEQUENTIAL (forced): ${wave.sequential_groups.map((id) => `${id}/${graph.byId.get(id).linearId}`).join(" → ")}`
      );
    } else {
      console.error(
        `\n${waveLabel} — ${wave.parallel.length > 1 ? "PARALLEL" : "SINGLE"}`
      );
      console.error(
        `  Stories: ${wave.parallel.map((id) => `${id}/${graph.byId.get(id).linearId}`).join(", ")}`
      );
    }
  }

  console.error("\n=== PRAVARTAK HANDOFF PLAN (in execution order) ===");
  for (const group of executionPlan) {
    console.error(`\nWave ${group.wave} [${group.type.toUpperCase()}] — ${group.reason}`);
    for (const item of group.items) {
      console.error(`  - ${item.linearId}: ${item.handoff}${item.note ? ` (${item.note})` : ""}`);
    }
  }
}

main();
