#!/usr/bin/env node
"use strict";

// generate-corpus.js — index this repository as citable chunks, one JSON object per line
// (plan 038 step 6). Two corpora:
//
//   package  what the package teaches: every shipped .claude/**/*.md, chunked by heading under
//            the file's permanent frontmatter id, with the CTFL sections each chunk cites.
//   record   how it was built: plans (by ## and ### section, with status, PRs and dates),
//            the plans/README.md status rows, decisions/, CHANGELOG.md releases, the merge
//            commits, and the PR descriptions when a snapshot of them is committed.
//
// Everything is read through git at one ref (`git show`, `git ls-tree`, `git log`), never from
// the working tree, so the index of any commit or tag can be rebuilt from git alone, and the same
// ref always gives byte-identical output. Not published: it is not in package.json "files".
//
// Usage: node generate-corpus.js [--ref <git ref>] [--only package|record] [--out <file>]
//
// Exit 1 when a shipped file has no id or two files share one (so a release cannot ship a file
// that cannot be cited). A build-record field that cannot be parsed is reported on stderr and
// left null; it never fails the run.

const { execFileSync } = require("child_process");
const fs = require("fs");
const path = require("path");

const ROOT = __dirname;
const SECTIONS_FILE = "tests/fixtures/ctfl-v4.0.1-sections.txt";
// The PR descriptions, snapshotted before the private repository is archived (plan 038 open
// question 1, a step of plan 020 part B): the output of
// `gh pr list --state all --limit 1000 --json number,title,body,mergedAt,mergeCommit`.
const PR_SNAPSHOT = "plans/pull-requests.json";

// ─── Arguments ───────────────────────────────────────────────────────────────

function parseArgs(argv) {
  const opts = { ref: "HEAD", only: null, out: null };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    const value = () => {
      if (i + 1 >= argv.length) usage(`${a} needs a value`);
      return argv[++i];
    };
    if (a === "--ref") opts.ref = value();
    else if (a === "--only") opts.only = value();
    else if (a === "--out") opts.out = value();
    else if (a === "-h" || a === "--help") usage(null);
    else usage(`unknown argument '${a}'`);
  }
  if (opts.only !== null && opts.only !== "package" && opts.only !== "record") {
    usage("--only takes package or record");
  }
  return opts;
}

function usage(error) {
  const text =
    "Usage: node generate-corpus.js [--ref <git ref>] [--only package|record] [--out <file>]";
  if (error) {
    process.stderr.write(`Error: ${error}\n${text}\n`);
    process.exit(2);
  }
  process.stdout.write(`${text}\n`);
  process.exit(0);
}

// ─── Git ─────────────────────────────────────────────────────────────────────

function git(args) {
  return execFileSync("git", args, {
    cwd: ROOT,
    encoding: "utf8",
    maxBuffer: 512 * 1024 * 1024,
    stdio: ["ignore", "pipe", "pipe"],
  });
}

function gitShow(commit, file) {
  try {
    return git(["show", `${commit}:${file}`]);
  } catch {
    return null;
  }
}

// The repository's address without credentials or a .git suffix, as an https URL when it is a
// GitHub-style host. `origin` first; otherwise the first remote; null when there is none.
function repoUrl() {
  let remotes;
  try {
    remotes = git(["remote"]).split("\n").filter(Boolean);
  } catch {
    return null;
  }
  if (remotes.length === 0) return null;
  const name = remotes.includes("origin") ? "origin" : remotes.sort()[0];
  let url = git(["remote", "get-url", name]).trim();
  const scp = url.match(/^[^@/]+@([^:/]+):(.+)$/);
  if (scp) url = `https://${scp[1]}/${scp[2]}`;
  url = url.replace(/^(ssh|git|https?):\/\/(?:[^@/]*@)?/, "https://");
  return url.replace(/\.git$/, "").replace(/\/$/, "");
}

// ─── Markdown ────────────────────────────────────────────────────────────────

const HEADING = /^(#{1,6})[ \t]+(.+?)[ \t]*#*[ \t]*$/;
const FENCE = /^ {0,3}(`{3,}|~{3,})/;

// Split off a leading `---` frontmatter block. Returns { fm: body or null, bodyStart: line index }.
function splitFrontmatter(lines) {
  if (lines[0] !== "---") return { fm: null, bodyStart: 0 };
  const end = lines.indexOf("---", 1);
  if (end === -1) return { fm: null, bodyStart: 0 };
  return { fm: lines.slice(1, end), bodyStart: end + 1 };
}

// The id from a frontmatter body: a top-level `id:`, or `id:` indented under `metadata:`.
function frontmatterId(fm) {
  if (!fm) return null;
  let inMeta = false;
  for (const line of fm) {
    if (/^\S/.test(line)) inMeta = /^metadata:\s*$/.test(line);
    const top = line.match(/^id:\s*(.*?)\s*$/);
    if (top) return unquote(top[1]);
    const nested = inMeta && line.match(/^\s+id:\s*(.*?)\s*$/);
    if (nested) return unquote(nested[1]);
  }
  return null;
}

function unquote(v) {
  const m = v.match(/^"(.*)"$/) || v.match(/^'(.*)'$/);
  return m ? m[1] : v;
}

// The headings outside fenced code blocks: [{ line, level, text }].
function headings(lines, from) {
  const out = [];
  let fence = null;
  for (let i = from; i < lines.length; i++) {
    const f = lines[i].match(FENCE);
    if (f) {
      if (fence === null) fence = f[1];
      else if (f[1][0] === fence[0] && f[1].length >= fence.length)
        fence = null;
      continue;
    }
    if (fence !== null) continue;
    const h = lines[i].match(HEADING);
    if (h) out.push({ line: i, level: h[1].length, text: h[2] });
  }
  return out;
}

// Cut the body into chunks at headings of level <= maxLevel. A chunk keeps its heading line, its
// ancestors' headings (heading_path) and its first line number (1-based, in the whole file).
// Blank text before the first heading is not a chunk.
function chunk(lines, bodyStart, maxLevel) {
  const hs = headings(lines, bodyStart).filter((h) => h.level <= maxLevel);
  const chunks = [];
  const stack = [];
  const starts = [{ line: bodyStart, heading: null }].concat(
    hs.map((h) => ({ line: h.line, heading: h })),
  );
  for (let k = 0; k < starts.length; k++) {
    const s = starts[k];
    const end = k + 1 < starts.length ? starts[k + 1].line : lines.length;
    if (s.heading) {
      while (stack.length && stack[stack.length - 1].level >= s.heading.level)
        stack.pop();
      stack.push(s.heading);
    }
    const text = lines.slice(s.line, end).join("\n").trim();
    if (!s.heading && text === "") continue;
    chunks.push({
      heading: s.heading ? s.heading.text : null,
      heading_path: stack.map((h) => h.text),
      line: s.line + 1,
      text,
    });
  }
  return chunks;
}

// GitHub's heading anchor: lowercase, punctuation and symbols dropped, spaces to hyphens; a
// repeated heading gets -1, -2 ... in order.
function slugger() {
  const seen = new Map();
  return (text) => {
    const base = text
      .replace(/`/g, "")
      .toLowerCase()
      .replace(/[^\p{L}\p{N}\p{M}\s_-]/gu, "")
      .replace(/\s/g, "-");
    const n = seen.get(base) || 0;
    seen.set(base, n + 1);
    return n === 0 ? base : `${base}-${n}`;
  };
}

function firstH1(lines, from) {
  const h = headings(lines, from).find((x) => x.level === 1);
  return h ? h.text : null;
}

// ─── CTFL sections ───────────────────────────────────────────────────────────

function loadSections(commit) {
  const map = new Map();
  const raw = gitShow(commit, SECTIONS_FILE);
  if (raw === null) return map;
  for (const line of raw.split("\n")) {
    if (line === "" || line.startsWith("#")) continue;
    const [num, title] = line.split("\t");
    map.set(num, title);
  }
  return map;
}

function compareSections(a, b) {
  const x = a.split(".").map(Number);
  const y = b.split(".").map(Number);
  for (let i = 0; i < Math.max(x.length, y.length); i++) {
    const d =
      (x[i] === undefined ? -1 : x[i]) - (y[i] === undefined ? -1 : y[i]);
    if (d !== 0) return d;
  }
  return 0;
}

// The sections cited in `text`, sorted, each with its syllabus title (null if not in the list).
// With ctflLinesOnly, only `§` on a line that also says CTFL or syllabus counts: in the build
// record `§` also names sections of other documents.
function citedSections(text, sections, ctflLinesOnly) {
  const found = new Set();
  for (const line of text.split("\n")) {
    if (ctflLinesOnly && !/CTFL|syllabus/i.test(line)) continue;
    for (const m of line.matchAll(/§(\d+(?:\.\d+)*)/g)) found.add(m[1]);
  }
  return [...found]
    .sort(compareSections)
    .map((s) => ({ section: s, title: sections.get(s) ?? null }));
}

// ─── Package corpus ──────────────────────────────────────────────────────────

function packageKind(file) {
  const p = file.split("/");
  if (p[1] === "skills") return p[3] === "references" ? "reference" : "skill";
  return (
    { rules: "rule", commands: "command", agents: "agent" }[p[1]] || "other"
  );
}

function packageRecords(ctx) {
  const files = ctx.files.filter(
    (f) => f.startsWith(".claude/") && f.endsWith(".md"),
  );
  const owner = new Map();
  const errors = [];
  const records = [];
  for (const file of files) {
    const lines = gitShow(ctx.commit, file).split("\n");
    const { fm, bodyStart } = splitFrontmatter(lines);
    const id = frontmatterId(fm);
    if (!id) {
      errors.push(`${file}: no id in its frontmatter`);
      continue;
    }
    if (owner.has(id)) {
      errors.push(`${file}: id '${id}' is already used by ${owner.get(id)}`);
      continue;
    }
    owner.set(id, file);
    const title = firstH1(lines, bodyStart);
    const slug = slugger();
    for (const c of chunk(lines, bodyStart, 6)) {
      records.push({
        corpus: "package",
        id,
        kind: packageKind(file),
        path: file,
        line: c.line,
        title,
        heading: c.heading,
        heading_path: c.heading_path,
        anchor: c.heading === null ? id : `${id}#${slug(c.heading)}`,
        istqb: citedSections(c.text, ctx.sections, false),
        version: ctx.version,
        repo: ctx.repo,
        ref: ctx.ref,
        commit: ctx.commit,
        text: c.text,
      });
    }
  }
  if (errors.length) {
    for (const e of errors) process.stderr.write(`Error: ${e}\n`);
    process.exit(1);
  }
  return records;
}

// ─── Build-record corpus ─────────────────────────────────────────────────────

function warn(ctx, message) {
  ctx.warnings.push(message);
}

function base(ctx, kind, file, line) {
  return {
    corpus: "record",
    kind,
    path: file,
    line,
    repo: ctx.repo,
    ref: ctx.ref,
    commit: ctx.commit,
  };
}

function uniqueNumbers(text, re) {
  const set = new Set();
  for (const m of text.matchAll(re)) set.add(Number(m[1]));
  return [...set].sort((a, b) => a - b);
}

const prRefs = (text) => uniqueNumbers(text, /(?<![\w&/])#(\d+)\b/g);
const datesIn = (text, re) =>
  [...new Set([...text.matchAll(re)].map((m) => m[1]))].sort();

// Split a Markdown table row on unescaped pipes.
function cells(row) {
  const inner = row.trim().replace(/^\|/, "").replace(/\|$/, "");
  return inner.split(/(?<!\\)\|/).map((c) => c.trim());
}

// The plans/README.md status table: Map plan number -> row fields, plus the rows as records.
function readmeRows(ctx) {
  const file = "plans/README.md";
  const raw = gitShow(ctx.commit, file);
  const rows = new Map();
  const records = [];
  if (raw === null) {
    warn(ctx, `${file}: not at this ref; plans carry no status`);
    return { rows, records };
  }
  const lines = raw.split("\n");
  let cols = null;
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (!line.startsWith("|")) {
      cols = null;
      continue;
    }
    const c = cells(line);
    if (cols === null) {
      const lower = c.map((x) => x.toLowerCase());
      if (lower.includes("plan") && lower.includes("status")) cols = lower;
      continue;
    }
    if (/^:?-+:?$/.test(c[0])) continue;
    const get = (name) => {
      const k = cols.indexOf(name);
      return k === -1 || c[k] === undefined ? null : c[k];
    };
    const plan = get("plan");
    if (!/^\d{3}$/.test(plan || "")) continue;
    const status = get("status");
    const row = {
      plan,
      title: get("title"),
      priority: get("priority"),
      effort: get("effort"),
      depends_on: get("depends on"),
      status,
      prs: prRefs(status || ""),
    };
    rows.set(plan, row);
    records.push(
      Object.assign(base(ctx, "plan-status", file, i + 1), row, { text: line }),
    );
  }
  return { rows, records };
}

// The `- **Key**: value` items of a plan's `## Status` section; an item's indented continuation
// lines are part of its value.
function statusBlock(lines) {
  const start = lines.findIndex((l) => /^## Status\s*$/.test(l));
  if (start === -1) return null;
  const out = {};
  let key = null;
  for (let i = start + 1; i < lines.length && !/^## /.test(lines[i]); i++) {
    const m = lines[i].match(/^- \*\*([^*]+)\*\*:\s*(.*)$/);
    if (m) {
      key = m[1].trim().toLowerCase();
      out[key] = m[2].trim();
    } else if (key !== null && /^\s+\S/.test(lines[i])) {
      out[key] += ` ${lines[i].trim()}`;
    } else {
      key = null;
    }
  }
  return out;
}

function addedIn(ctx, file) {
  const out = git([
    "log",
    "--diff-filter=A",
    "--format=%h %as",
    ctx.commit,
    "--",
    file,
  ]).trim();
  if (!out) return null;
  const [commit, date] = out.split("\n").pop().split(" ");
  return { commit, date };
}

function planRecords(ctx, readme) {
  const records = [];
  const plans = ctx.files.filter((f) => /^plans\/\d{3}-[^/]+\.md$/.test(f));
  for (const file of plans) {
    const number = file.slice(6, 9);
    const lines = gitShow(ctx.commit, file).split("\n");
    const title = firstH1(lines, 0);
    const status = statusBlock(lines);
    if (status === null)
      warn(
        ctx,
        `${file}: no "## Status" block; priority, effort and planned_at are null`,
      );
    const s = status || {};
    let plannedAt = null;
    if (s["planned at"]) {
      const sha = s["planned at"].match(/`([0-9a-f]{7,40})`/);
      const date = s["planned at"].match(/\d{4}-\d{2}-\d{2}/);
      plannedAt = { commit: sha ? sha[1] : null, date: date ? date[0] : null };
    } else if (status !== null) {
      warn(ctx, `${file}: no "Planned at" line; planned_at is null`);
    }
    const row = readme.get(number) || null;
    if (row === null)
      warn(ctx, `${file}: no row in plans/README.md; status and prs are null`);
    const added = addedIn(ctx, file);
    for (const c of chunk(lines, 0, 3)) {
      const step =
        c.heading &&
        c.heading.match(/^(Step|Phase)\s+([0-9]+[a-z]?|[A-Z]\d*)\b/);
      records.push(
        Object.assign(base(ctx, "plan", file, c.line), {
          plan: path.basename(file),
          title,
          heading: c.heading,
          heading_path: c.heading_path,
          step: step ? `${step[1]} ${step[2]}` : null,
          status: row ? row.status : null,
          prs: row ? row.prs : null,
          priority: s.priority || null,
          effort: s.effort || null,
          depends_on: s["depends on"] || null,
          planned_at: plannedAt,
          added,
          prs_in_text: prRefs(c.text),
          corrections: datesIn(c.text, /Correction,\s+(\d{4}-\d{2}-\d{2})/g),
          istqb: citedSections(c.text, ctx.sections, true),
          text: c.text,
        }),
      );
    }
  }
  return records;
}

function decisionRecords(ctx) {
  const records = [];
  for (const file of ctx.files.filter((f) =>
    /^decisions\/[^/]+\.md$/.test(f),
  )) {
    const lines = gitShow(ctx.commit, file).split("\n");
    const quote = lines.find((l) => l.startsWith(">")) || "";
    const st = quote.match(/Status:\s*([A-Za-z ]+?)[,:.*]/);
    const decided = quote.match(/\d{4}-\d{2}-\d{2}/);
    if (!st)
      warn(
        ctx,
        `${file}: no "Status:" in its first blockquote; status is null`,
      );
    const title = firstH1(lines, 0);
    for (const c of chunk(lines, 0, 3)) {
      records.push(
        Object.assign(base(ctx, "decision", file, c.line), {
          title,
          heading: c.heading,
          heading_path: c.heading_path,
          status: st ? st[1].trim().toLowerCase() : null,
          decided: decided ? decided[0] : null,
          text: c.text,
        }),
      );
    }
  }
  return records;
}

function releaseRecords(ctx) {
  const file = "CHANGELOG.md";
  const raw = gitShow(ctx.commit, file);
  if (raw === null) return [];
  const records = [];
  for (const c of chunk(raw.split("\n"), 0, 2)) {
    const v = c.heading && c.heading.match(/^\[?(\d+\.\d+\.\d+[^\]\s]*)\]?/);
    if (!v) continue;
    const date = c.heading.match(/\d{4}-\d{2}-\d{2}/);
    records.push(
      Object.assign(base(ctx, "release", file, c.line), {
        version: v[1],
        date: date ? date[0] : null,
        prs: [
          ...new Set(
            prRefs(c.text).concat(uniqueNumbers(c.text, /\/pull\/(\d+)/g)),
          ),
        ].sort((a, b) => a - b),
        commits: [
          ...new Set(
            [...c.text.matchAll(/\/commit\/([0-9a-f]{7,40})/g)].map(
              (m) => m[1],
            ),
          ),
        ].sort(),
        text: c.text,
      }),
    );
  }
  return records;
}

function mergeRecords(ctx) {
  const raw = git([
    "log",
    "--merges",
    "--reverse",
    "--format=%H%x00%cs%x00%s%x00%b%x1e",
    ctx.commit,
  ]);
  const records = [];
  let n = 0;
  for (const entry of raw.split("\x1e")) {
    const e = entry.replace(/^\n/, "");
    if (!e) continue;
    const [sha, date, subject, body] = e.split("\x00");
    const pr = subject.match(/^Merge pull request #(\d+)/);
    n += 1;
    records.push(
      Object.assign(base(ctx, "merge", null, n), {
        pr: pr ? Number(pr[1]) : null,
        title: pr ? (body || "").split("\n")[0].trim() || null : subject,
        sha,
        date,
        text: [subject, (body || "").trim()].filter(Boolean).join("\n\n"),
      }),
    );
  }
  return records;
}

function prRecords(ctx) {
  const raw = gitShow(ctx.commit, PR_SNAPSHOT);
  if (raw === null) {
    warn(ctx, `${PR_SNAPSHOT}: not at this ref; no PR descriptions indexed`);
    return [];
  }
  let list;
  try {
    list = JSON.parse(raw);
  } catch (e) {
    warn(
      ctx,
      `${PR_SNAPSHOT}: not valid JSON (${e.message}); no PR descriptions indexed`,
    );
    return [];
  }
  return list
    .slice()
    .sort((a, b) => a.number - b.number)
    .map((p) =>
      Object.assign(base(ctx, "pr", PR_SNAPSHOT, p.number), {
        pr: p.number,
        title: p.title ?? null,
        merged_at: p.mergedAt ?? null,
        sha: p.mergeCommit && p.mergeCommit.oid ? p.mergeCommit.oid : null,
        text: p.body ?? "",
      }),
    );
}

// ─── Main ────────────────────────────────────────────────────────────────────

function main() {
  const opts = parseArgs(process.argv.slice(2));
  let commit;
  try {
    commit = git(["rev-parse", "--verify", `${opts.ref}^{commit}`]).trim();
  } catch {
    process.stderr.write(
      `Error: '${opts.ref}' is not a commit in this repository\n`,
    );
    process.exit(2);
  }
  const pkg = gitShow(commit, "package.json");
  const ctx = {
    ref: opts.ref,
    commit,
    repo: repoUrl(),
    version: pkg ? JSON.parse(pkg).version : null,
    files: git(["ls-tree", "-r", "--name-only", commit])
      .split("\n")
      .filter(Boolean),
    sections: loadSections(commit),
    warnings: [],
  };

  let records = [];
  if (opts.only !== "record") records = records.concat(packageRecords(ctx));
  if (opts.only !== "package") {
    const readme = readmeRows(ctx);
    records = records.concat(
      planRecords(ctx, readme.rows),
      readme.records,
      decisionRecords(ctx),
      releaseRecords(ctx),
      mergeRecords(ctx),
      prRecords(ctx),
    );
  }

  // corpus, then path (records without one last, in kind order), then position.
  const key = (r) => [r.corpus, r.path === null ? "￿" + r.kind : r.path];
  records.sort((a, b) => {
    const [ca, pa] = key(a);
    const [cb, pb] = key(b);
    if (ca !== cb) return ca < cb ? -1 : 1;
    if (pa !== pb) return pa < pb ? -1 : 1;
    return a.line - b.line;
  });

  const out =
    records.map((r) => JSON.stringify(r)).join("\n") +
    (records.length ? "\n" : "");
  if (opts.out) {
    fs.mkdirSync(path.dirname(path.resolve(opts.out)), { recursive: true });
    fs.writeFileSync(opts.out, out);
  } else {
    process.stdout.write(out);
  }
  for (const w of ctx.warnings) process.stderr.write(`Note: ${w}\n`);
  const count = (c) => records.filter((r) => r.corpus === c).length;
  process.stderr.write(
    `Indexed ${opts.ref} (${commit.slice(0, 7)}): ${count("package")} package and ${count("record")} record chunks.\n`,
  );
}

main();
