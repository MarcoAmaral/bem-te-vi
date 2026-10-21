# Plan 003: True multi-agent QA pipeline (groomer → designer → writer)

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat 39ac591..HEAD -- .claude/agents .claude/commands generate-adapters.sh`
> If any in-scope file changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: L
- **Risk**: MED
- **Depends on**: none (independent of plans 001/002, but plan 001 touches the same file, `.claude/commands/qa.md` — land 001 first to avoid a merge conflict on that file's routing table)
- **Category**: direction (feature) / architecture
- **Planned at**: commit `39ac591`, 2026-07-29

## Why this matters

`docs/specs/qa-skill-overhaul.md` §1 proposes an agentic QA pipeline to fix
the "hallucination in monolithic prompts" problem: today, commands like
`/qa-cases` ask one model to read a ticket and produce final test cases in a
single pass, with no intermediate checkpoint where a human (or another agent)
can catch a wrong assumption before it propagates into 20 test cases. The
repo owner has confirmed the direction explicitly: **true multi-agent**, not
a single command that just chains prompts internally — separate,
independently-invocable Claude Code subagents under `.claude/agents/`, each
reading only the previous stage's output file, so a bad assumption is
traceable to the exact stage that introduced it.

Today `.claude/agents/` contains exactly one agent (`qa-engineer.md`, a code
reviewer). There is no requirements-breakdown agent, no test-design agent,
and no dedicated writer agent — the entire "multi-agent QA pipeline" that
the spec and the package's own ambition ("best in the world") center on does
not exist yet. This plan builds it for Claude Code natively (subagents +
Task-tool orchestration), which is the environment this repo's primary
distribution channel (`.claude/`) targets and the one place true
independent subagents are structurally possible today.

## Current state

- `.claude/agents/qa-engineer.md` — the only existing agent. Frontmatter
  convention to match exactly:

  ```markdown
  ---
  name: qa-engineer
  description: Senior QA analyst for static code review — testability, functional correctness, security hygiene, and error-handling resilience. Use proactively after writing or modifying code, especially before committing or opening a PR.
  model: haiku
  ---
  ```

  Body starts with `# Agent: QA Engineer & Static Reviewer`, an italic
  one-line role summary, then `---`, then `## 🎯 Agent Identity & Persona`,
  then numbered `##`-level sections. New agents must follow this same shape
  (H1 title, role blockquote, `---`, Identity section, numbered capability
  sections) — see the full file for the exact pattern to copy.
- `.claude/commands/qa.md` — the `/qa` dispatcher (see plan 001 for the
  stale-reference fix to this same file — land that first). Its "Smart
  Routing" table (around line 39–49) and "Declarative Rules & Auto-loaded
  Skills" list (around line 23–31) are where new pipeline entries belong,
  following the existing row shape, e.g.:

  ```markdown
  | "code review", "testability", "static analysis"           | Invoke **Static Reviewer Agent** (`agents/qa-engineer.md`)          |
  ```

- `.claude/commands/*.md` — every other command (`qa-cases.md`, `qa-defect.md`,
  `qa-bdd.md`, `qa-automate.md`, `qa-refinement.md`, `qa-tdd.md`) is a
  single-persona instruction file with the header shape:

  ```markdown
  # QA — <Title>

  > **<Role>** | ISTQB CTFL v4.0 | <Specialty>
  > Respond in the language of the user's prompt (default: PT-BR)

  You are a Senior QA Analyst specializing in <specialty>.
  ```

  followed by `---`-separated sections. `qa-agentic.md` (new, this plan) must
  match this same header convention for consistency, but its body describes
  an *orchestration* rather than a persona — see Step 4.
- `.claude/commands/qa.md` "TC Format Quick Reference" (lines 53–79) defines
  the canonical test case frontmatter/table shape all generated test cases
  must follow:

  ```markdown
  ---
  feature: [Feature Name]
  feature_code: [CODE]
  tc_count: N
  ado_user_stories: [list]
  risk_level: HIGH|MEDIUM|LOW
  last_updated: YYYY-MM-DD
  ---

  ## TC-[CODE]-NNN: [Title]

  | Field                  | Value                                        |
  | ---------------------- | -------------------------------------------- |
  | **Tags**               | `@smoke @p0 @e2e @feature @candidate`        |
  | **ADO Story**          | [#XXXXXX](link)                              |
  | **Automation Score**   | HIGH (52/57.5)                               |
  | **ISTQB Technique**    | EP / BVA / State Transition / Error Guessing |
  | **Precondition**       | [State before test]                          |
  | **Steps**              | 1. [Action] <br> 2. [Action]                 |
  | **Expected**           | [Observable outcome]                         |
  | **data-testid needed** | `selector-name`                              |
  ```

- `.claude/hooks/validate-tc-format.sh` — CI/local hook that scans any
  `*.md` file containing a `## TC-[A-Z0-9]+-[0-9]+:` heading and requires
  YAML frontmatter with exactly these keys: `feature`, `feature_code`,
  `tc_count`, `risk_level`, `last_updated` (see lines 52–56 of that file).
  **Any file the new pipeline writes that contains a `## TC-` heading must
  carry all five keys or this hook fails.**
- `.claude/rules/testing-guidelines.md` — defines the ISTQB test design
  technique table (Equivalence Partitioning, BVA, Decision Table, State
  Transition, Error Guessing, Exploratory) and the tag taxonomy
  (`@smoke`/`@sanity`/`@regression`, `@unit`/`@integration`/`@e2e`/`@api`/`@manual`,
  `@p0`–`@p3`, `@automated`/`@candidate`/`@manual-only`) — the designer and
  writer agents must reuse this table rather than inventing a new one.
- `generate-adapters.sh` lines 67–79: the compiler already walks
  `.claude/agents/*.md` and appends **every** file it finds into the single
  merged blob used for non-Claude editors (Cursor/Windsurf/Copilot/Cline/
  Antigravity/universal). **No changes to `generate-adapters.sh` are needed
  for this plan** — new agent files are picked up automatically. Verify this
  is still true by reading lines 67–79 before starting; if the loop shape
  has changed, treat it as a STOP condition per the drift check above.
- Independent subagent *invocation* (one agent's output feeding the next as
  an isolated context, via the Task tool) is a Claude Code-native capability.
  The merged single-file adapters for other editors will contain the
  three new agents' text, but those editors do not have an equivalent
  "dispatch to an isolated subagent" mechanism — true multi-agent
  orchestration via `/qa-agentic` is Claude-Code-only. This is a known,
  accepted limitation, not a defect to fix in this plan (see Maintenance
  notes).

## Commands you will need

| Purpose | Command | Expected on success |
| --- | --- | --- |
| Regenerate adapters | `./generate-adapters.sh --clean` | exits 0, "All adapters generated (7 files)" |
| Confirm new agents compiled into adapters | `grep -l "qa-groomer" adapters/**/*` (or per-file grep, see Step 6) | matches in all 7 adapter outputs |
| TC format hook, single file | `./.claude/hooks/validate-tc-format.sh <path-to-generated-testcases.md>` | prints "Prisinte formatting!" (note: this is the hook's actual existing typo — do not "fix" it as part of this plan, out of scope), exit 0 |
| Markdown lint (matches CI) | `npx markdownlint-cli ".claude/agents/*.md" ".claude/commands/qa-agentic.md" ".claude/commands/qa.md"` | exit 0 |
| Integration test suite | `./tests/test-lifecycle.sh` | exits 0 |

## Scope

**In scope** (the only files you should create or modify):

- `.claude/agents/qa-groomer.md` (new)
- `.claude/agents/qa-designer.md` (new)
- `.claude/agents/qa-writer.md` (new)
- `.claude/commands/qa-agentic.md` (new — the director/orchestrator)
- `.claude/commands/qa.md` (modify — add pipeline entries to the routing/skills tables; if plan 001 already landed, work on top of its version of this file)
- `adapters/**` (regenerated output only, via `./generate-adapters.sh --clean` — never hand-edited)

**Out of scope** (do NOT touch, even though they look related):

- `.claude/agents/qa-engineer.md` — existing agent, do not modify its content or frontmatter.
- `generate-adapters.sh` — no change needed (see "Current state"); do not add
  special-casing for the new agents.
- Antigravity-native `.agents/agents/` true multi-agent director (spec §1's
  third bullet) — the current compiler architecture merges all agents into
  one file per non-Claude editor, so a *separately dispatchable* Antigravity
  agent pipeline requires a distribution-format change that is a bigger,
  separate architectural decision. Do not attempt it here; note it as
  explicitly deferred in `plans/README.md`.
- `.claude/rules/*.md` — reuse the existing ISTQB technique/tag tables by
  reference from the new agents; do not duplicate or edit the rule files.
- Any of `.claude/skills/qa-plan/` or `.claude/skills/qa-explore/` — unrelated skills, do not touch.

## Git workflow

- Branch: `feat/multi-agent-qa-pipeline` (matches repo convention).
- Commit per logical unit (this plan is large enough to warrant several
  atomic commits per `CLAUDE.md` §"Atomic Commits" and
  `.claude/rules/code-style-qa.md`'s "AND rule" — do not combine unrelated
  concerns):
  1. `feat: add qa-groomer subagent for ticket-to-requirements breakdown`
  2. `feat: add qa-designer subagent for ISTQB technique mapping`
  3. `feat: add qa-writer subagent for final test case generation`
  4. `feat: add qa-agentic director command orchestrating the pipeline`
  5. `docs: route qa-agentic and pipeline agents in qa dispatcher`
  6. `chore: regenerate adapters for multi-agent pipeline`
- Do NOT push or open a PR unless the operator instructed it.

## Steps

### Step 1: Create `qa-groomer` agent

Create `.claude/agents/qa-groomer.md`. Frontmatter, matching the
`qa-engineer.md` convention exactly (three keys, in this order):

```markdown
---
name: qa-groomer
description: First stage of the QA agentic pipeline — reads a ticket, spec, or feature description and breaks it into a numbered list of atomic, testable requirements. Use at the start of the /qa-agentic pipeline, never standalone for final test cases.
model: sonnet
---
```

Model rationale (record this reasoning in the commit, don't silently pick a
different model): breaking an ambiguous or under-specified ticket into
correctly-scoped atomic requirements is a judgment task — it requires
resolving ambiguity, not mechanical transformation — so it uses `sonnet`,
not `haiku` (`qa-engineer.md`'s `haiku` choice fits its narrower, more
mechanical static-analysis checklist; this stage is closer to open-ended
requirements analysis).

Body content, following the `qa-engineer.md` shape (H1 title, italic role
line, `---`, identity section, numbered capability sections):

- H1: `# Agent: QA Groomer — Requirements Breakdown`
- State its **single output contract**: it must write (or return, for the
  caller to save) a file named `requirements.md` containing ONLY a numbered
  list of atomic requirements, each requirement independently testable, in
  this exact shape:

  ```markdown
  # Requirements: [Ticket/Feature Title]

  Source: [ticket ID / spec file path / user-provided description]

  1. [Atomic requirement — one testable statement]
  2. [Atomic requirement — one testable statement]
  ...
  ```

- Instruct it to number requirements sequentially starting at 1, and that
  each requirement must be a single, independently-verifiable statement — if
  a requirement contains "and", it must be split (mirror the existing "AND
  Rule" already used for commit atomicity in
  `.claude/rules/code-style-qa.md` §"Atomic Commits" — cite that section by
  name as the precedent for this convention, since the repo already applies
  "no compound statements" thinking to commits).
- Include the spec's "Dynamic Context Discovery" instruction (from
  `docs/specs/qa-skill-overhaul.md` §1): before writing requirements, the
  agent must search the caller's project for local knowledge bases —
  `plan.md`, `architecture.md`, `docs/`, `README.md`, `CONTRIBUTING.md` — and
  read any that exist, so requirements are grounded in actual project
  context rather than the ticket text alone. State explicitly: if no such
  files exist, proceed from the ticket/description alone without asking the
  user to create them.
- State explicitly: this agent does **not** select test techniques, does
  **not** write test cases, and does **not** read any file the pipeline
  produced downstream of it (there is nothing downstream yet at this stage).

**Verify**: `head -5 .claude/agents/qa-groomer.md` shows the three-key
frontmatter above. `grep -c "^## " .claude/agents/qa-groomer.md` ≥ 2 (has at
least an identity section and the output-contract section).

### Step 2: Create `qa-designer` agent

Create `.claude/agents/qa-designer.md`:

```markdown
---
name: qa-designer
description: Second stage of the QA agentic pipeline — reads requirements.md produced by qa-groomer and maps each requirement to ISTQB test design techniques, producing a checklist. Use only as the second step of /qa-agentic, after qa-groomer has run.
model: sonnet
---
```

Model rationale: selecting the right ISTQB technique (EP/BVA/Decision
Table/State Transition/Error Guessing/Exploratory) per requirement and
identifying edge cases is judgment work requiring domain expertise, matching
`sonnet` — not mechanical enough for `haiku`.

Body:

- H1: `# Agent: QA Designer — Test Technique Mapping`
- **Strict input contract**: this agent reads **only** `requirements.md`
  (the file `qa-groomer` produced) — explicitly instruct it not to re-read
  the original ticket, spec, or any other project file. This is the
  traceability property the spec calls out: each stage reads only the
  previous file, so a wrong assumption is attributable to exactly one stage.
- **Output contract**: writes `checklist.md`, one entry per requirement
  number from `requirements.md`, in this shape:

  ```markdown
  # Test Design Checklist

  Source: requirements.md

  ## Requirement 1: [restated requirement]
  - Technique: [EP | BVA | Decision Table | State Transition | Error Guessing | Exploratory]
  - Checks:
    - [ ] [specific check derived from the technique]
    - [ ] [specific check derived from the technique]
  - Priority: [P0 | P1 | P2 | P3]
  - Suite: [@smoke | @sanity | @regression]
  - Level: [@unit | @integration | @e2e | @api | @manual]
  ```

- Instruct it to pull the technique definitions and tag taxonomy directly
  from `.claude/rules/testing-guidelines.md` (name the file explicitly) —
  do not restate ISTQB technique definitions inline in this new agent file;
  reference the rule file as the source of truth so the two never drift
  apart.
- State explicitly: this agent does **not** write final test case files, and
  every requirement from `requirements.md` must produce at least one
  checklist entry (no silent drops) — if a requirement is untestable as
  written, it must still appear with a checklist note saying why, not be
  omitted.

**Verify**: same structural checks as Step 1, plus
`grep -n "requirements.md" .claude/agents/qa-designer.md` shows the input
contract is stated, and `grep -n "testing-guidelines.md" .claude/agents/qa-designer.md`
confirms it references the rule file rather than duplicating it.

### Step 3: Create `qa-writer` agent

Create `.claude/agents/qa-writer.md`:

```markdown
---
name: qa-writer
description: Final stage of the QA agentic pipeline — reads checklist.md produced by qa-designer and expands it into final TC-CODE-NNN formatted test cases. Use only as the third step of /qa-agentic, after qa-designer has run.
model: haiku
---
```

Model rationale: this stage is templating — expanding an already-designed
checklist into the fixed TC-CODE-NNN frontmatter/table format — mechanical
and fully specified, matching the CLAUDE.md guidance to use `haiku` for
"mechanical, fully-specified tasks" where "the plan already has the code to
write."

Body:

- H1: `# Agent: QA Writer — Test Case Formatting`
- **Strict input contract**: reads **only** `checklist.md` — not
  `requirements.md`, not the original ticket. Same traceability rule as
  Step 2.
- **Output contract**: writes `testcases.md` (or appends to an existing test
  case file if the caller specifies one) using **exactly** the TC format
  defined in `.claude/commands/qa.md` under "TC Format Quick Reference" —
  quote that section's frontmatter keys verbatim in this new file so the
  writer agent doesn't have to cross-reference at runtime:

  ```markdown
  ---
  feature: [Feature Name]
  feature_code: [CODE]
  tc_count: N
  ado_user_stories: [list]
  risk_level: HIGH|MEDIUM|LOW
  last_updated: YYYY-MM-DD
  ---
  ```

  followed by one `## TC-[CODE]-NNN: [Title]` block per checklist check,
  using the table shape from `qa.md` (Tags / ADO Story / Automation Score /
  ISTQB Technique / Precondition / Steps / Expected / data-testid needed).
- **Hard requirement, called out explicitly in the agent file**: the
  frontmatter MUST include all five keys required by
  `.claude/hooks/validate-tc-format.sh` (`feature`, `feature_code`,
  `tc_count`, `risk_level`, `last_updated`) or the pre-commit/CI hook will
  reject the output. State this as a non-negotiable constraint, not a
  suggestion.
- Each `TC-[CODE]-NNN` number must map traceably back to its checklist
  entry — instruct the agent to carry the requirement number from
  `checklist.md` into an HTML comment or the ADO Story field placeholder so
  a human can trace TC → checklist entry → requirement → ticket.

**Verify**: `grep -n "feature_code\|tc_count\|risk_level\|last_updated" .claude/agents/qa-writer.md`
shows all four keys mentioned (plus `feature`, checked separately since it's
a substring of `feature_code`).

### Step 4: Create the `qa-agentic` director command

Create `.claude/commands/qa-agentic.md`, matching the existing command
header convention (see `qa-cases.md` for the exact shape to copy):

```markdown
# QA — Agentic Pipeline (Multi-Agent)

> **Pipeline Director** | ISTQB CTFL v4.0 | Groomer → Designer → Writer
> Respond in the language of the user's prompt (default: PT-BR)

You are the director of a strict, sequential multi-agent QA pipeline. You do not perform requirements analysis, technique selection, or test writing yourself — you dispatch each stage to its dedicated subagent and pass only file paths between them.
```

Body must specify, precisely:

1. **Step 1 — Groom**: Dispatch to the `qa-groomer` subagent (via the Task
   tool, `subagent_type: qa-groomer`) with the user's ticket/feature
   description as input. Wait for it to produce `requirements.md`. Do not
   proceed until this file exists and is non-empty.
2. **Step 2 — Design**: Dispatch to the `qa-designer` subagent with
   instructions to read **only** `requirements.md` (do not pass the original
   ticket text into this stage's prompt). Wait for `checklist.md`.
3. **Step 3 — Write**: Dispatch to the `qa-writer` subagent with instructions
   to read **only** `checklist.md`. Wait for `testcases.md`.
4. **Traceability rule, stated explicitly and prominently**: "Each stage
   reads only the file produced by the previous stage. If a stage's output
   looks wrong, the defect is traceable to that stage alone — never re-feed
   the original ticket into stage 2 or 3 to 'fix' a bad stage-1 output;
   re-run stage 1 instead."
5. **Where files live**: instruct the director to write the three
   intermediate files (`requirements.md`, `checklist.md`, `testcases.md`)
   into the current working directory unless the user specifies a target
   path — and to tell the user where each file landed after each stage
   completes, not just at the end.
6. Add this command to the "Specialized Active Commands" table in
   `.claude/commands/qa.md` (Step 5 below), so it's discoverable the same
   way `/qa-cases` etc. are.

**Verify**: `grep -n "qa-groomer\|qa-designer\|qa-writer" .claude/commands/qa-agentic.md`
shows all three subagent names referenced in dispatch order.

### Step 5: Wire `qa-agentic` into the `/qa` dispatcher

In `.claude/commands/qa.md`:

- Add a row to the "Specialized Active Commands" table (same table plan 001
  edits — if plan 001 has landed, this table no longer has the `/qa-ado`
  row; add the new row after `/qa-automate`):

  ```markdown
  | `/qa-agentic`  | Rodar pipeline multi-agente completo (groomer → designer → writer) | ~10KB       |
  ```

- Add a row to the "Smart Routing" table:

  ```markdown
  | "full pipeline", "agentic", "groomer to writer", "multi-agent"   | Apply `/qa-agentic` active command (dispatches qa-groomer → qa-designer → qa-writer) |
  ```

- Add a bullet to the "Declarative Rules & Auto-loaded Skills" list
  documenting the three new agents, mirroring the existing
  `agents/qa-engineer.md` bullet:

  ```markdown
  - **Agentic Pipeline Agents** (`agents/qa-groomer.md`, `agents/qa-designer.md`, `agents/qa-writer.md`): Dispatched in strict sequence by `/qa-agentic` — never invoke standalone for final test case output.
  ```

**Verify**: `grep -n "qa-agentic" .claude/commands/qa.md` shows at least 3
matches (one per table/list addition above).

### Step 6: Regenerate adapters

Run `./generate-adapters.sh --clean`.

**Verify**: exits 0, prints "All adapters generated (7 files)". Then confirm
the new agents and command are present in every compiled output:
`for f in adapters/cursor/qa.mdc adapters/windsurf/qa.md adapters/copilot/copilot-instructions.md adapters/cline/.clinerules adapters/antigravity/qa/SKILL.md adapters/universal/AGENTS.md adapters/universal/CLAUDE.md; do grep -q "qa-groomer" "$f" && grep -q "qa-agentic" "$f" || echo "MISSING in $f"; done`
→ no "MISSING" lines printed.

## Test plan

- No existing automated test validates command/agent *content* (only
  install/link lifecycle and adapter-diff-cleanliness in CI). This plan does
  not add a new automated test for pipeline correctness — that would require
  actually running the three subagents against a sample ticket, which is
  outside what `./tests/test-lifecycle.sh` (a filesystem lifecycle test, not
  an LLM-behavior test) can check. Document this gap in the commit for step
  4/5 rather than silently skipping it.
- Manual verification after all steps: from a scratch directory with these
  skills installed (`qa-skills init` per README, or by symlinking `.claude/`
  directly), run `/qa-agentic` against a simple made-up feature description
  and confirm `requirements.md` → `checklist.md` → `testcases.md` are
  produced in order, and that `testcases.md` passes
  `./.claude/hooks/validate-tc-format.sh testcases.md`. This is a manual,
  not machine-checkable, step — perform it and report the outcome in the
  plan status update rather than treating it as a blocking Done criterion
  (executors without live Task-tool dispatch access, e.g. a plain code-edit
  executor, may not be able to run this step — note that limitation instead
  of failing the plan over it).

## Done criteria

Machine-checkable. ALL must hold:

- [ ] `.claude/agents/qa-groomer.md`, `.claude/agents/qa-designer.md`, `.claude/agents/qa-writer.md` exist, each with valid 3-key frontmatter (`name`, `description`, `model`)
- [ ] `.claude/commands/qa-agentic.md` exists and references all three subagent names in dispatch order
- [ ] `grep -n "qa-agentic" .claude/commands/qa.md` returns ≥3 matches
- [ ] `./generate-adapters.sh --clean` exits 0
- [ ] `grep -q "qa-groomer" adapters/**/*` and `grep -q "qa-agentic" adapters/**/*` both true across all 7 adapter files (see Step 6 verify command)
- [ ] `npx markdownlint-cli ".claude/agents/qa-groomer.md" ".claude/agents/qa-designer.md" ".claude/agents/qa-writer.md" ".claude/commands/qa-agentic.md" ".claude/commands/qa.md"` exits 0
- [ ] `./tests/test-lifecycle.sh` exits 0
- [ ] `git status --porcelain` shows only the in-scope files listed above as changed
- [ ] `plans/README.md` status row for 003 updated (DONE, or BLOCKED with the manual-verification limitation noted if Task-tool dispatch wasn't available to the executor)

## STOP conditions

Stop and report back (do not improvise) if:

- `generate-adapters.sh`'s agent-appending loop (lines 67–79 as read during
  recon) has changed shape since this plan was written — re-read it before
  assuming the new agent files will be picked up automatically.
- You cannot determine how to invoke a Claude Code subagent by
  `name`/`subagent_type` from within a command file in this environment —
  this is a platform capability question, not something to work around by
  inlining the three agents' logic into one big prompt (that would defeat
  the entire point of this plan and reproduce the "monolithic prompt"
  problem the spec is trying to solve).
- `validate-tc-format.sh` rejects the sample `testcases.md` from manual
  verification for a reason not covered by the five required frontmatter
  keys — re-read the hook script before adjusting the writer agent's output
  contract.
- Any step requires modifying `qa-engineer.md`, `generate-adapters.sh`, or
  any `.claude/rules/*.md` file to make the pipeline work — that indicates
  the plan's assumptions about the existing architecture were wrong; stop
  and report which assumption broke instead of expanding scope.

## Maintenance notes

- **Antigravity-native multi-agent director** (spec §1's third bullet: a
  literal `.agents/agents/` directory with `groomer.md`/`designer.md`/
  `writer.md`/`AGENTS.md` director for true multi-agent editors like
  Antigravity) is explicitly deferred by this plan. The current compiler
  (`generate-adapters.sh`) merges all agents into one flat file per editor,
  which is structurally incompatible with "separately dispatchable
  Antigravity agents." Building that properly means either (a) teaching the
  compiler to emit a `.agents/agents/` tree instead of a merged blob for
  Antigravity specifically, or (b) accepting Antigravity gets the same
  single-file "read about the pipeline" treatment as Cursor/Windsurf/etc.
  This is a real architecture decision for the repo owner, not something to
  decide inside an execution plan — flag it back to `/improve` (or the repo
  owner directly) as a follow-up planning item once this plan lands.

  > **Decided by Marco, 2026-10-20.** Not built: the agents stay Agent Skills in every editor,
  > with no native subagents per editor (plan 047, D6).
- Once the pipeline exists, `docs/specs/qa-skill-overhaul.md` §1 should be
  marked done/superseded rather than left as an open proposal — update the
  spec file (or delete it if `docs/` is being gitignored per plan 002 and
  the repo owner doesn't want it in history) so the next reader doesn't
  think this is still unbuilt.
- If a future contributor adds a fourth pipeline stage, or lets `qa-writer`
  write directly into an existing project's test suite instead of a
  standalone `testcases.md`, the "reads only the previous file" traceability
  rule in Step 4 must be preserved — that's the entire point of the
  multi-agent split per the spec's stated motivation.
- Consider (out of scope here) a CI check that greps `qa.md` for every
  `/qa-*` reference and confirms a matching command file exists — see plan
  001's maintenance note; the same drift risk applies to `/qa-agentic` going
  forward.
