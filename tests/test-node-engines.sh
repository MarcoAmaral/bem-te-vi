#!/usr/bin/env bash
# package.json's engines.node must not be looser than the engines.node of any package in the
# runtime dependency tree (`npm ls --omit=dev --all`): every Node version npm lets the package
# install on must be one that each runtime dependency supports. It once said ">=18" while
# @inquirer/prompts, loaded for the interactive init menu, needs ^20.17.0, ^22.13.0 or >=23.5.0.
# package-lock.json must record the same range as package.json, and every `node-version` in
# .github/workflows/ must be inside it, so CI runs on a Node version the package claims.
# Needs `npm ci` first; the range checks use the semver package already in node_modules.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

node - <<'EOF'
const { execFileSync } = require("child_process");
const fs = require("fs");
const path = require("path");

const fail = (msg) => {
  console.error(`✘ ${msg}`);
  process.exit(1);
};

let semver;
try {
  semver = require("semver");
} catch (_) {
  fail("the semver package is not in node_modules; run npm ci first.");
}

const own = (JSON.parse(fs.readFileSync("package.json", "utf8")).engines || {}).node;
if (!own || !semver.validRange(own)) fail(`package.json engines.node is not a valid range: '${own}'`);

const lockRoot = JSON.parse(fs.readFileSync("package-lock.json", "utf8")).packages[""];
const locked = (lockRoot.engines || {}).node;
if (locked !== own)
  fail(`package-lock.json records engines.node '${locked}', package.json '${own}'; run npm install --package-lock-only`);

const root = fs.realpathSync(".");
const dirs = execFileSync("npm", ["ls", "--omit=dev", "--all", "--parseable"], { encoding: "utf8" })
  .split("\n")
  .filter((d) => d && d !== root);
if (dirs.length === 0) fail("npm ls lists no runtime dependencies; run npm ci first.");

const workflows = path.join(".github", "workflows");
const pinned = [];
for (const file of fs.readdirSync(workflows).filter((f) => /\.ya?ml$/.test(f))) {
  const lines = fs.readFileSync(path.join(workflows, file), "utf8").split("\n");
  lines.forEach((line, i) => {
    const m = line.match(/^\s*node-version:\s*(.+?)\s*(#.*)?$/);
    if (!m) return;
    for (const v of m[1].replace(/^\[|\]$/g, "").split(","))
      pinned.push({ where: `${workflows}/${file}:${i + 1}`, version: v.trim().replace(/^["']|["']$/g, "") });
  });
}
if (pinned.length === 0) fail(`no node-version found in ${workflows}/`);
const outside = pinned.filter(({ version }) => !semver.validRange(version) || !semver.subset(version, own));
if (outside.length > 0)
  fail(`a workflow runs a Node version outside package.json engines.node '${own}':\n  ${outside.map((p) => `${p.where}: node-version ${p.version}`).join("\n  ")}`);

const looser = [];
let ranged = 0;
for (const dir of dirs) {
  const dep = JSON.parse(fs.readFileSync(path.join(dir, "package.json"), "utf8"));
  const range = (dep.engines || {}).node;
  if (!range) continue;
  ranged++;
  if (!semver.validRange(range) || !semver.subset(own, range))
    looser.push(`${dep.name}@${dep.version} needs node '${range}'`);
}
if (looser.length > 0)
  fail(`package.json engines.node '${own}' allows Node versions a runtime dependency does not support:\n  ${looser.join("\n  ")}`);

console.log(`✔ engines.node '${own}' is within the range of all ${ranged} runtime dependencies that declare one (${dirs.length} in the tree), and holds all ${pinned.length} workflow node-version values.`);
EOF
