#!/usr/bin/env node
// benchmark/analysis/extract.js: turns one `claude plugin eval` collection into committed results.
//
//   node benchmark/analysis/extract.js --out <results dir> [--regrade] <aggregate-result.json>...
//
// Give one aggregate per `claude plugin eval` invocation (the runbook runs one per task); they are
// merged in the order given.
// --regrade: score the regex graders again on each final reply with the graders now under
// benchmark/graders (the same verdict rules, in Node's regex engine), keeping the tool's verdicts in
// "toolGraders" and its judge (jdg-) verdicts as they were. Used only for a grader corrected after a
// pilot (METHODOLOGY.md, "Pilot disclosure"); every difference from the tool's verdict is printed.
//
// Reads the tool's aggregate JSON and each run's trace (the run must have used --keep-temp, so the
// traces still exist), and writes into <results dir>:
//   aggregate/<nn>.json              each aggregate JSON given, redacted
//   runs.jsonl                       one line per generation: condition, task, run, model, cost,
//                                    tokens, grader verdicts, files read, skills called
//   outputs/<condition>/<task>/run-<n>.md   the final reply of each generation, redacted
// Redaction (plan 037): local paths become <repository>, <temp> or <home>; any e-mail address
// outside the reserved example domains becomes <account email, redacted>. The script fails if
// anything that looks like a local path or a real address survives. Node standard library only.
"use strict";

const fs = require("fs");
const path = require("path");

function die(message) {
  console.error(`extract.js: ${message}`);
  process.exit(1);
}

function makeRedactor(repoRoot) {
  const roots = [
    repoRoot,
    fs.existsSync(repoRoot) ? fs.realpathSync(repoRoot) : repoRoot,
  ]
    .filter(Boolean)
    .sort((a, b) => b.length - a.length);
  return function redact(text) {
    if (typeof text !== "string") return text;
    let s = text;
    for (const r of roots) s = s.split(r).join("<repository>");
    s = s.replace(/\/tmp\/[^\s"'`)\]]*/g, "<temp>");
    s = s.replace(/\/mnt\/[^\s"'`)\]]*/g, "<local path>");
    s = s.replace(/\/(?:home|Users)\/[^/\s"'`]+/g, "<home>");
    s = s.replace(/[A-Za-z]:\\Users\\[^\\\s"'`]+/g, "<home>");
    s = s.replace(/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g, (email) =>
      /@(?:[A-Za-z0-9-]+\.)*(?:example|invalid|test|localhost)$|@example\.(?:com|org|net)$/i.test(
        email,
      )
        ? email
        : "<account email, redacted>",
    );
    return s;
  };
}

function deepRedact(value, redact) {
  if (typeof value === "string") return redact(value);
  if (Array.isArray(value)) return value.map((v) => deepRedact(v, redact));
  if (value && typeof value === "object") {
    const out = {};
    for (const [k, v] of Object.entries(value)) out[k] = deepRedact(v, redact);
    return out;
  }
  return value;
}

function readTrace(file) {
  const info = {
    model: null,
    models: new Set(),
    finalText: null,
    filesRead: [],
    skills: [],
    usage: null,
    traceCost: null,
  };
  if (!file || !fs.existsSync(file)) return null;
  let lastText = null;
  for (const line of fs.readFileSync(file, "utf8").split("\n")) {
    if (!line.trim()) continue;
    let o;
    try {
      o = JSON.parse(line);
    } catch {
      continue;
    }
    if (o.type === "system" && o.subtype === "init")
      info.model = o.model || null;
    if (o.type === "assistant" && o.message) {
      if (o.message.model) info.models.add(o.message.model);
      const texts = [];
      for (const part of o.message.content || []) {
        if (part.type === "text" && part.text) texts.push(part.text);
        if (part.type === "tool_use" && part.name === "Read" && part.input)
          info.filesRead.push(part.input.file_path);
        if (part.type === "tool_use" && part.name === "Skill" && part.input)
          info.skills.push(part.input.skill);
      }
      if (texts.length) lastText = texts.join("\n");
    }
    if (o.type === "result") {
      if (typeof o.result === "string") info.finalText = o.result;
      info.usage = o.usage || null;
      info.traceCost =
        typeof o.total_cost_usd === "number" ? o.total_cost_usd : null;
      if (o.modelUsage)
        for (const m of Object.keys(o.modelUsage)) info.models.add(m);
    }
  }
  if (info.finalText === null) info.finalText = lastText;
  return info;
}

function main() {
  const args = process.argv.slice(2);
  const regrade = args.includes("--regrade");
  const o = args.indexOf("--out");
  const outDir = o >= 0 ? args[o + 1] : null;
  const aggPaths = args.filter(
    (a, i) => a !== "--regrade" && i !== o && i !== o + 1,
  );
  if (!outDir || aggPaths.length === 0)
    die(
      "usage: extract.js --out <results dir> [--regrade] <aggregate-result.json>...",
    );
  const build = regrade
    ? require(path.join(__dirname, "..", "build.js"))
    : null;
  const differences = [];
  fs.mkdirSync(path.join(outDir, "aggregate"), { recursive: true });
  const lines = [];
  const roots = [];
  let missing = 0;
  aggPaths.forEach((aggPath, n) => {
    const agg = JSON.parse(fs.readFileSync(aggPath, "utf8"));
    const repoRoot = agg.suite && agg.suite.root;
    if (!repoRoot) die(`${aggPath}: no suite.root`);
    roots.push(repoRoot);
    const redact = makeRedactor(repoRoot);
    for (const c of agg.cases || []) {
      const m = /^([ABCD])-(.+)$/.exec(c.name);
      if (!m) die(`case ${c.name} is not named <condition>-<task>`);
      const [, condition, task] = m;
      const runs = (c.arms && c.arms.with) || [];
      runs.forEach((run, i) => {
        const trace = readTrace(run.tracePath);
        if (!trace) missing++;
        const rel = path.join("outputs", condition, task, `run-${i + 1}.md`);
        const text = trace && trace.finalText !== null ? trace.finalText : "";
        fs.mkdirSync(path.join(outDir, path.dirname(rel)), { recursive: true });
        fs.writeFileSync(
          path.join(outDir, rel),
          `${redact(text).replace(/\s+$/, "")}\n`,
        );
        const toolGraders = {};
        for (const g of run.graders || [])
          toolGraders[g.name] = g.passed === true;
        let graders = toolGraders;
        if (regrade) {
          graders = {};
          for (const g of build
            .graderFiles({ id: task })
            .map(build.readGrader)) {
            graders[g.name] =
              g.type === "regex"
                ? build.verdict(g, text)
                : toolGraders[g.name] === true;
            if (!(g.name in toolGraders))
              differences.push(
                `${c.name}/${g.name}: new grader, ${graders[g.name]}`,
              );
            else if (graders[g.name] !== toolGraders[g.name]) {
              differences.push(
                `${c.name}/${g.name}: tool ${toolGraders[g.name]}, now ${graders[g.name]}`,
              );
            }
          }
          for (const name of Object.keys(toolGraders)) {
            if (!(name in graders))
              differences.push(
                `${c.name}/${name}: grader removed (tool ${toolGraders[name]})`,
              );
          }
        }
        const u = (trace && trace.usage) || {};
        lines.push({
          condition,
          task,
          run: i + 1,
          model: trace ? trace.model : null,
          models: trace ? [...trace.models].sort() : [],
          claudeVersion: agg.claudeVersion || null,
          startedAt: run.startedAt || null,
          costUsd: run.costUsd ?? null,
          judgeCostUsd: run.judgeCostUsd ?? null,
          durationSeconds: run.durationSeconds ?? null,
          turns: run.turns ?? null,
          error: run.error ? redact(String(run.error)) : null,
          skippedPaidGraders: run.skippedPaidGraders === true,
          tokens: {
            input: u.input_tokens ?? null,
            output: u.output_tokens ?? null,
            cacheRead: u.cache_read_input_tokens ?? null,
            cacheCreation: u.cache_creation_input_tokens ?? null,
          },
          graders,
          ...(regrade
            ? { toolGraders, graded: "regraded by extract.js --regrade" }
            : { graded: "claude plugin eval" }),
          filesRead: trace ? trace.filesRead.map(redact) : [],
          skills: trace ? trace.skills : [],
          output: rel.split(path.sep).join("/"),
          traceFound: Boolean(trace),
        });
      });
    }
    const name = `${String(n + 1).padStart(2, "0")}.json`;
    fs.writeFileSync(
      path.join(outDir, "aggregate", name),
      `${JSON.stringify(deepRedact(agg, redact), null, 2)}\n`,
    );
  });
  fs.writeFileSync(
    path.join(outDir, "runs.jsonl"),
    `${lines.map((l) => JSON.stringify(l)).join("\n")}\n`,
  );

  // Nothing local may survive.
  const leaks = [];
  const walk = (dir) => {
    for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
      const p = path.join(dir, e.name);
      if (e.isDirectory()) walk(p);
      else {
        const s = fs.readFileSync(p, "utf8");
        if (/\/tmp\/|\/home\/|\/Users\/|\/mnt\/|[A-Za-z]:\\Users\\/.test(s))
          leaks.push(`${p}: local path`);
        if (roots.some((r) => s.includes(r)))
          leaks.push(`${p}: repository path`);
      }
    }
  };
  walk(outDir);
  if (leaks.length) die(`redaction left local data:\n  ${leaks.join("\n  ")}`);
  if (regrade) {
    console.log(
      differences.length
        ? `regrade differs from the tool on:\n  ${differences.join("\n  ")}`
        : "regrade: every verdict equals the tool's",
    );
  }
  console.log(
    `${lines.length} generations extracted to ${outDir}${missing ? ` (${missing} without a trace)` : ""}`,
  );
}

main();
