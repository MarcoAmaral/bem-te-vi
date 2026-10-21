#!/usr/bin/env node
// benchmark/analysis/analyze.js: the pre-specified analysis of the efficacy benchmark (plan 048,
// benchmark/METHODOLOGY.md "Outcomes and analysis"). Node standard library only, deterministic.
//
//   node benchmark/analysis/analyze.js <runs.jsonl | results dir> [...]   print the Markdown table
//   node benchmark/analysis/analyze.js --self-test                        check it on synthetic results
//
// Input: runs.jsonl lines written by extract.js, one per generation, each with at least
//   { "condition": "A"|"B"|"C"|"D", "task": "<id>", "graders": { "<name>": true|false, ... } }
// plus "costUsd" when known. A grader name starts with its family: con- (content), fmt- (the
// package's contract) or jdg- (LLM judge).
"use strict";

const fs = require("fs");
const path = require("path");

const CONDITIONS = ["A", "B", "C", "D"];
const CONTRASTS = [
  ["D", "C"],
  ["D", "B"],
  ["D", "A"],
];
const ALPHA = 0.05;
const BONFERRONI = ALPHA / CONTRASTS.length; // two-sided level per contrast: 98.33% intervals
const REPLICATES = 10000;
const SEED = 20261018;
const MIN_CELL = 8; // fewer generations than this in any task x condition cell: no conclusion

// ─── Exact binomial (Clopper-Pearson) ─────────────────────────────────────────

function logGamma(x) {
  // Lanczos approximation, g = 7, n = 9.
  const c = [
    0.99999999999980993, 676.5203681218851, -1259.1392167224028,
    771.32342877765313, -176.61502916214059, 12.507343278686905,
    -0.13857109526572012, 9.9843695780195716e-6, 1.5056327351493116e-7,
  ];
  if (x < 0.5)
    return Math.log(Math.PI / Math.sin(Math.PI * x)) - logGamma(1 - x);
  x -= 1;
  let a = c[0];
  const t = x + 7.5;
  for (let i = 1; i < 9; i++) a += c[i] / (x + i);
  return (
    0.5 * Math.log(2 * Math.PI) + (x + 0.5) * Math.log(t) - t + Math.log(a)
  );
}

function betaContinuedFraction(x, a, b) {
  // Lentz's method for the continued fraction of the incomplete beta function.
  const TINY = 1e-300;
  let c = 1;
  let d = 1 - ((a + b) * x) / (a + 1);
  if (Math.abs(d) < TINY) d = TINY;
  d = 1 / d;
  let h = d;
  for (let m = 1; m <= 300; m++) {
    const m2 = 2 * m;
    let aa = (m * (b - m) * x) / ((a + m2 - 1) * (a + m2));
    d = 1 + aa * d;
    if (Math.abs(d) < TINY) d = TINY;
    c = 1 + aa / c;
    if (Math.abs(c) < TINY) c = TINY;
    d = 1 / d;
    h *= d * c;
    aa = (-(a + m) * (a + b + m) * x) / ((a + m2) * (a + m2 + 1));
    d = 1 + aa * d;
    if (Math.abs(d) < TINY) d = TINY;
    c = 1 + aa / c;
    if (Math.abs(c) < TINY) c = TINY;
    d = 1 / d;
    const delta = d * c;
    h *= delta;
    if (Math.abs(delta - 1) < 1e-15) break;
  }
  return h;
}

// Regularized incomplete beta I_x(a, b).
function betaInc(x, a, b) {
  if (x <= 0) return 0;
  if (x >= 1) return 1;
  const front = Math.exp(
    logGamma(a + b) -
      logGamma(a) -
      logGamma(b) +
      a * Math.log(x) +
      b * Math.log(1 - x),
  );
  if (x < (a + 1) / (a + b + 2))
    return (front * betaContinuedFraction(x, a, b)) / a;
  return 1 - (front * betaContinuedFraction(1 - x, b, a)) / b;
}

function betaQuantile(p, a, b) {
  let lo = 0;
  let hi = 1;
  for (let i = 0; i < 100; i++) {
    const mid = (lo + hi) / 2;
    if (betaInc(mid, a, b) < p) lo = mid;
    else hi = mid;
  }
  return (lo + hi) / 2;
}

function clopperPearson(k, n, alpha = ALPHA) {
  if (n === 0) return [NaN, NaN];
  const lower = k === 0 ? 0 : betaQuantile(alpha / 2, k, n - k + 1);
  const upper = k === n ? 1 : betaQuantile(1 - alpha / 2, k + 1, n - k);
  return [lower, upper];
}

// ─── Seeded bootstrap, stratified by task ────────────────────────────────────

function mulberry32(seed) {
  let a = seed >>> 0;
  return function next() {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function quantile(sorted, q) {
  // Type 7 (linear interpolation), as R's default.
  const pos = (sorted.length - 1) * q;
  const lo = Math.floor(pos);
  const hi = Math.ceil(pos);
  return sorted[lo] + (sorted[hi] - sorted[lo]) * (pos - lo);
}

// cells: Map task -> { a: [0/1...], b: [0/1...] }. Estimate: mean over tasks of (rate a - rate b).
function contrast(cells, level, seed = SEED, replicates = REPLICATES) {
  const tasks = [...cells.keys()]
    .filter((t) => cells.get(t).a.length && cells.get(t).b.length)
    .sort();
  if (tasks.length === 0) return null;
  const rate = (xs) => xs.reduce((s, x) => s + x, 0) / xs.length;
  const estimate =
    tasks.reduce((s, t) => s + rate(cells.get(t).a) - rate(cells.get(t).b), 0) /
    tasks.length;
  const rand = mulberry32(seed);
  const draws = [];
  const resampled = (xs) => {
    let s = 0;
    for (let i = 0; i < xs.length; i++) s += xs[Math.floor(rand() * xs.length)];
    return s / xs.length;
  };
  for (let r = 0; r < replicates; r++) {
    let total = 0;
    for (const t of tasks)
      total += resampled(cells.get(t).a) - resampled(cells.get(t).b);
    draws.push(total / tasks.length);
  }
  draws.sort((x, y) => x - y);
  const tail = (1 - level) / 2;
  const minCell = Math.min(
    ...tasks.flatMap((t) => [cells.get(t).a.length, cells.get(t).b.length]),
  );
  return {
    estimate,
    lower: quantile(draws, tail),
    upper: quantile(draws, 1 - tail),
    tasks: tasks.length,
    minCell,
  };
}

function decide(c) {
  if (!c) return "no data";
  if (c.minCell < MIN_CELL) return "underpowered, no conclusion";
  if (c.lower > 0) return "supports the claim";
  return "does not support the claim";
}

// ─── Outcomes per generation ─────────────────────────────────────────────────

function family(graders, prefix) {
  return Object.entries(graders || {}).filter(([name]) =>
    name.startsWith(prefix),
  );
}

function outcomes(run) {
  const con = family(run.graders, "con-");
  const fmt = family(run.graders, "fmt-");
  const jdg = family(run.graders, "jdg-");
  return {
    content: con.length > 0 && con.every(([, v]) => v === true) ? 1 : 0,
    contentScore: con.length
      ? con.filter(([, v]) => v === true).length / con.length
      : NaN,
    contract: fmt.length > 0 && fmt.every(([, v]) => v === true) ? 1 : 0,
    judge: jdg.length ? (jdg.every(([, v]) => v === true) ? 1 : 0) : null,
  };
}

// ─── Report ──────────────────────────────────────────────────────────────────

const pct = (x) => (Number.isFinite(x) ? `${(x * 100).toFixed(1)}%` : "n/a");
const ci = ([l, u]) => (Number.isFinite(l) ? `${pct(l)} to ${pct(u)}` : "n/a");
const pts = (x) => `${x >= 0 ? "+" : ""}${(x * 100).toFixed(1)}`;

function analyse(runs, options = {}) {
  const seed = options.seed ?? SEED;
  const replicates = options.replicates ?? REPLICATES;
  const rows = runs.map((r) => ({ ...r, o: outcomes(r) }));
  const tasks = [...new Set(rows.map((r) => r.task))].sort();
  const by = (cond) => rows.filter((r) => r.condition === cond);
  const lines = [];
  const label = options.label ? ` (${options.label})` : "";
  lines.push(`### Per condition${label}`, "");
  lines.push(
    "| Condition | n | Content pass | 95% CI (exact) | Contract pass | 95% CI (exact) | Content score | Judge pass | Mean cost per generation, judge included (US$) |",
    "| --- | --- | --- | --- | --- | --- | --- | --- | --- |",
  );
  const summary = {};
  for (const cond of CONDITIONS) {
    const rs = by(cond);
    const n = rs.length;
    const k = rs.reduce((s, r) => s + r.o.content, 0);
    const f = rs.reduce((s, r) => s + r.o.contract, 0);
    const scores = rs.map((r) => r.o.contentScore).filter(Number.isFinite);
    const judged = rs.filter((r) => r.o.judge !== null);
    const costs = rs.map((r) => r.costUsd).filter((x) => typeof x === "number");
    summary[cond] = { n, k, f };
    lines.push(
      `| ${cond} | ${n} | ${n ? `${k}/${n} (${pct(k / n)})` : "n/a"} | ${ci(clopperPearson(k, n))} | ` +
        `${n ? `${f}/${n} (${pct(f / n)})` : "n/a"} | ${ci(clopperPearson(f, n))} | ` +
        `${scores.length ? pct(scores.reduce((a, b) => a + b, 0) / scores.length) : "n/a"} | ` +
        `${judged.length ? `${judged.filter((r) => r.o.judge === 1).length}/${judged.length}` : "n/a"} | ` +
        `${costs.length ? (costs.reduce((a, b) => a + b, 0) / costs.length).toFixed(4) : "n/a"} |`,
    );
  }
  lines.push("", `### Content pass by task${label}`, "");
  lines.push(
    `| Task | ${CONDITIONS.join(" | ")} |`,
    `| --- | ${CONDITIONS.map(() => "---").join(" | ")} |`,
  );
  for (const t of tasks) {
    const cells = CONDITIONS.map((cond) => {
      const rs = rows.filter((r) => r.task === t && r.condition === cond);
      return rs.length
        ? `${rs.reduce((s, r) => s + r.o.content, 0)}/${rs.length}`
        : "-";
    });
    lines.push(`| ${t} | ${cells.join(" | ")} |`);
  }
  const level = 1 - BONFERRONI;
  lines.push("", `### Contrasts on content pass${label}`, "");
  lines.push(
    `| Contrast | Difference (points) | ${(level * 100).toFixed(2)}% bootstrap interval | Tasks | Smallest cell | Reading |`,
    "| --- | --- | --- | --- | --- | --- |",
  );
  const results = {};
  for (const [a, b] of CONTRASTS) {
    const cells = new Map();
    for (const t of tasks) {
      cells.set(t, {
        a: rows
          .filter((r) => r.task === t && r.condition === a)
          .map((r) => r.o.content),
        b: rows
          .filter((r) => r.task === t && r.condition === b)
          .map((r) => r.o.content),
      });
    }
    const c = contrast(cells, level, seed, replicates);
    results[`${a}-${b}`] = { ...c, reading: decide(c) };
    lines.push(
      c
        ? `| ${a} vs ${b} | ${pts(c.estimate)} | ${pts(c.lower)} to ${pts(c.upper)} | ${c.tasks} | ${c.minCell} | ${decide(c)} |`
        : `| ${a} vs ${b} | n/a | n/a | 0 | 0 | no data |`,
    );
  }
  lines.push(
    "",
    `Content pass: every \`con-\` grader of the task passed. Intervals per condition are exact ` +
      `(Clopper-Pearson); contrasts average the per-task difference with equal task weight, ` +
      `bootstrap ${replicates} replicates resampling runs within each task and condition, seed ${seed}, ` +
      `Bonferroni over ${CONTRASTS.length} contrasts. A contrast is read only when every cell holds at ` +
      `least ${MIN_CELL} generations.`,
  );
  return { markdown: `${lines.join("\n")}\n`, summary, contrasts: results };
}

// ─── Input ───────────────────────────────────────────────────────────────────

function readRuns(paths) {
  const runs = [];
  for (const p of paths) {
    const file = fs.statSync(p).isDirectory() ? path.join(p, "runs.jsonl") : p;
    for (const line of fs.readFileSync(file, "utf8").split("\n")) {
      if (line.trim()) runs.push(JSON.parse(line));
    }
  }
  return runs;
}

// ─── Self-test ───────────────────────────────────────────────────────────────

function selfTest() {
  let checks = 0;
  const fail = (msg) => {
    console.error(`self-test: ✘ ${msg}`);
    process.exit(1);
  };
  const near = (x, y, tol, msg) => {
    checks++;
    if (!(Math.abs(x - y) <= tol)) fail(`${msg}: got ${x}, want ${y}`);
  };
  const eq = (x, y, msg) => {
    checks++;
    if (x !== y)
      fail(`${msg}: got ${JSON.stringify(x)}, want ${JSON.stringify(y)}`);
  };

  // Clopper-Pearson against reference values computed with scipy.stats.beta.ppf (SciPy 1.17.1).
  const ref = [
    [0, 10, 0, 0.3084971],
    [10, 10, 0.6915029, 1],
    [5, 10, 0.187086, 0.812914],
    [3, 10, 0.0667395, 0.6524529],
    [1, 9, 0.0028091, 0.4824965],
    [45, 90, 0.392698, 0.607302],
  ];
  for (const [k, n, lo, hi] of ref) {
    const [l, u] = clopperPearson(k, n);
    near(l, lo, 5e-6, `Clopper-Pearson lower ${k}/${n}`);
    near(u, hi, 5e-6, `Clopper-Pearson upper ${k}/${n}`);
  }

  // Synthetic collection: 9 tasks x 4 conditions x 10 runs, pass counts fixed per condition.
  const passes = { A: 2, B: 4, C: 3, D: 9 };
  const synth = [];
  for (let t = 1; t <= 9; t++) {
    for (const cond of CONDITIONS) {
      for (let r = 0; r < 10; r++) {
        const pass = r < passes[cond];
        synth.push({
          condition: cond,
          task: `task-${t}`,
          run: r + 1,
          costUsd: 0.01,
          graders: {
            "con-a": pass,
            "con-b": pass || r === 9,
            "fmt-x": cond === "D",
            "jdg-y": pass,
          },
        });
      }
    }
  }
  const one = analyse(synth, { replicates: 2000 });
  const two = analyse(synth, { replicates: 2000 });
  eq(
    one.markdown,
    two.markdown,
    "the same input and seed give the same report",
  );
  eq(one.summary.D.k, 81, "D content passes");
  eq(one.summary.A.k, 18, "A content passes");
  eq(one.summary.D.f, 90, "D contract passes");
  eq(one.summary.C.f, 0, "C contract passes");
  near(one.contrasts["D-C"].estimate, 0.6, 1e-12, "D vs C difference");
  eq(
    one.contrasts["D-C"].reading,
    "supports the claim",
    "a large, powered difference supports the claim",
  );
  checks++;
  if (!(one.contrasts["D-C"].lower > 0.4 && one.contrasts["D-C"].upper < 0.8))
    fail("D vs C interval out of range");

  // No difference: the claim is not supported.
  const flat = synth.map((r) => ({ ...r, graders: { "con-a": r.run <= 5 } }));
  eq(
    analyse(flat, { replicates: 2000 }).contrasts["D-B"].reading,
    "does not support the claim",
    "equal rates",
  );

  // A pilot (one run per cell) is never read, whatever its point estimate.
  const pilot = synth.filter((r) => r.run === 1);
  eq(
    analyse(pilot, { replicates: 500 }).contrasts["D-A"].reading,
    "underpowered, no conclusion",
    "pilot",
  );

  // A cell under the minimum makes the contrast unreadable even when the others are full.
  const thin = synth.filter(
    (r) =>
      !(r.task === "task-3" && r.condition === "C" && r.run > MIN_CELL - 1),
  );
  eq(
    analyse(thin, { replicates: 500 }).contrasts["D-C"].reading,
    "underpowered, no conclusion",
    "one thin cell",
  );

  // Generations without con- graders never count as a content pass.
  eq(outcomes({ graders: { "fmt-a": true } }).content, 0, "no con- graders");

  console.log(`self-test: ${checks} checks passed`);
}

function main() {
  const args = process.argv.slice(2);
  if (args[0] === "--self-test") return selfTest();
  if (args.length === 0 || args[0].startsWith("-")) {
    console.error(
      "usage: analyze.js <runs.jsonl | results dir> [...] | --self-test",
    );
    process.exit(2);
  }
  const label = args.find((a) => a.startsWith("--label="));
  const files = args.filter((a) => !a.startsWith("--"));
  process.stdout.write(
    analyse(readRuns(files), { label: label ? label.slice(8) : "" }).markdown,
  );
}

module.exports = { analyse, clopperPearson, outcomes };

if (require.main === module) main();
