#!/usr/bin/env node
// benchmark/analysis/blind.js: draws the blind human-review sample (METHODOLOGY.md, "Blind human
// review") from a collection's results.
//
//   node benchmark/analysis/blind.js <results dir> <review dir> <key dir> [--per-cell 2] [--seed N]
//
// <review dir> receives <task>/<code>.md (the output, renamed) and review-sheet.csv, which the judge
// fills in. <key dir> receives key.csv (code -> condition, task, run) and the salt; it must be
// outside the repository and is committed only after every review is recorded. The sample is drawn
// with a fixed seed, so anyone can check which generations were chosen; the codes are a salted
// SHA-256, so the judge cannot recompute them. Node standard library only.
"use strict";

const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

function die(message) {
  console.error(`blind.js: ${message}`);
  process.exit(1);
}

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

function main() {
  const args = process.argv.slice(2);
  const opt = (name, fallback) => {
    const i = args.indexOf(name);
    if (i < 0) return fallback;
    const v = args.splice(i, 2)[1];
    return Number(v);
  };
  const perCell = opt("--per-cell", 2);
  const seed = opt("--seed", 20261018);
  const [resultsDir, reviewDir, keyDir] = args;
  if (!resultsDir || !reviewDir || !keyDir)
    die(
      "usage: blind.js <results dir> <review dir> <key dir> [--per-cell N] [--seed N]",
    );
  const repo = path.resolve(__dirname, "..", "..");
  if (path.resolve(keyDir).startsWith(repo + path.sep))
    die("the key directory must be outside the repository");

  const runs = fs
    .readFileSync(path.join(resultsDir, "runs.jsonl"), "utf8")
    .split("\n")
    .filter((l) => l.trim())
    .map((l) => JSON.parse(l));
  const cells = new Map();
  for (const r of runs) {
    const k = `${r.task}\t${r.condition}`;
    if (!cells.has(k)) cells.set(k, []);
    cells.get(k).push(r);
  }
  const rand = mulberry32(seed);
  const sample = [];
  for (const k of [...cells.keys()].sort()) {
    const rs = cells
      .get(k)
      .slice()
      .sort((a, b) => a.run - b.run);
    for (let i = rs.length - 1; i > 0; i--) {
      const j = Math.floor(rand() * (i + 1));
      [rs[i], rs[j]] = [rs[j], rs[i]];
    }
    sample.push(...rs.slice(0, perCell));
  }

  fs.mkdirSync(keyDir, { recursive: true });
  const saltFile = path.join(keyDir, "salt.txt");
  if (!fs.existsSync(saltFile))
    fs.writeFileSync(saltFile, `${crypto.randomBytes(32).toString("hex")}\n`);
  const salt = fs.readFileSync(saltFile, "utf8").trim();
  const code = (r) =>
    crypto
      .createHash("sha256")
      .update(`${salt}\0${r.condition}\0${r.task}\0${r.run}`)
      .digest("hex")
      .slice(0, 10);

  // Present the sample sorted by code, so the order says nothing about the condition.
  const rows = sample
    .map((r) => ({ r, c: code(r) }))
    .sort((a, b) => (a.c < b.c ? -1 : 1));
  const key = ["code,condition,task,run"];
  const sheet = [
    "code,task,q1_use_as_delivered,q2_correct,q3_complete,condition_guess,notes",
  ];
  for (const { r, c } of rows) {
    const out = path.join(reviewDir, r.task, `${c}.md`);
    fs.mkdirSync(path.dirname(out), { recursive: true });
    fs.copyFileSync(path.join(resultsDir, r.output), out);
    key.push(`${c},${r.condition},${r.task},${r.run}`);
    sheet.push(`${c},${r.task},,,,,`);
  }
  fs.writeFileSync(path.join(keyDir, "key.csv"), `${key.join("\n")}\n`);
  fs.writeFileSync(
    path.join(reviewDir, "review-sheet.csv"),
    `${sheet.join("\n")}\n`,
  );
  console.log(
    `${rows.length} outputs in ${reviewDir}; key in ${keyDir} (keep it out of the repository until the reviews are in)`,
  );
}

main();
