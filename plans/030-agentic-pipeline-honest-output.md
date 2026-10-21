# Plan 030: `/qa-agentic` produces test cases that pass the format hook honestly, wherever it is installed

> **Executor instructions**: Follow the items in order; one PR per item. Run every verification
> command. If anything in "STOP conditions" occurs, stop and report. When done, update this plan's
> row in `plans/README.md`.
>
> **Drift check (run first)**: `git diff --stat 5b45cfa..HEAD -- .claude/commands/qa-agentic.md .claude/agents .claude/commands/qa-trace.md tests/test-qa-trace.sh tests/fixtures/qa-trace .claude-plugin`
> On a mismatch with the excerpts below, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: M
- **Risk**: MED (changes three agent contracts and the traceability command's inputs)
- **Depends on**: plan 029 step 3 (the tag taxonomy the designer emits must be settled first)
- **Category**: bug
- **Planned at**: commit `5b45cfa`, 2026-10-13 (audit after 4.0.0)

## Why this matters

`/qa-agentic` runs three subagents in sequence: `qa-groomer` turns a ticket into `requirements.md`,
`qa-designer` turns that into `checklist.md`, and `qa-writer` expands the checklist into
`testcases.md` in the TC template. Each stage reads only the previous stage's file, by design. But
the files passed between stages do not carry what the final template requires: whether a
requirement came from an acceptance criterion (the `Source` row, mandatory since 4.0.0), the feature
code, the tracker issue, the risk level and the automation status. So the writer must invent them,
which the package's own context-discovery rule calls a fabrication. The committed example
`examples/serverest/qa-agentic/README.md` already records the output failing the package's format
hook and "fields the pipeline cannot fill honestly". Separately, the command dispatches the agents by
bare name (`qa-groomer`). In a plugin install they are registered as `bem-te-vi:qa-groomer` (checked
in a plugin-only headless session), and on a machine with an older user-level install the bare name
silently runs the old agent. Finally, `/qa-trace` never reads the `Source` row, so the links the new
row records count as merely "inferred".

## Current state

- `.claude/commands/qa-agentic.md:18,22,26`: "Dispatch to the `qa-groomer` subagent (via the Task
  tool, `subagent_type: qa-groomer`)" — and the same for `qa-designer` and `qa-writer`. No step runs
  the format hook on `testcases.md`. No fallback for editors without subagents.
- `.claude/agents/qa-groomer.md:42-56`, output contract:

  ```markdown
  # Requirements: [Ticket/Feature Title]

  Source: [ticket ID / spec file path / user-provided description]

  Context notes: [...]

  1. [Atomic requirement — one testable statement]
  ```

  "Do not include test techniques, priorities, tags, or test cases in this file."
- `.claude/agents/qa-designer.md:38-52`, per requirement: `Technique`, `Checks`, `Priority`,
  `Suite`, `Level`. No origin, no status tag, no feature.
- `.claude/agents/qa-writer.md:23` reads only `checklist.md`; `:67-71` requires nine frontmatter keys
  (`feature`, `feature_code`, `tc_count`, `tracker_issues`, `risk_level`, `cdt`,
  `implementation_pack`, `spec`, `last_updated`) and eleven rows, and says: "**Source** … Take it from
  the requirement in `checklist.md`: a requirement that came from the ticket cites its AC, one the
  groomer or designer inferred is `Added by QA`." The checklist has no such information. `:71`:
  "When a value is unknown or does not apply, write `N/A — <why>` and keep the row (except
  **Source** …)". `:75-77`: the writer puts `Traces to REQ-n` in the **Note** row.
- Agent frontmatter (`.claude/agents/*.md:1-5`) has only `name`, `description` and `model`
  (`qa-writer`: `haiku`, others `sonnet`) and no `tools:` list, so each agent inherits every tool,
  including edit and shell. `qa-engineer` is a read-only reviewer told to run "proactively".
- `.claude/commands/qa-trace.md:40-47`: a link is **traced** when "the **Note** row says
  `Traces to REQ-n`…; the **Issue** row names the requirement's own tracker item; or the requirement
  ID appears in an automated test's title or tag". The `Source` row is not mentioned
  (`grep -c Source .claude/commands/qa-trace.md` → 0). `:55` result words: passed, failed, blocked,
  skipped, not run.
- `tests/test-qa-trace.sh` derives every fact of `tests/fixtures/qa-trace/password-reset/expected-trace.md`
  from the fixture inputs; its traced/inferred rule is `tc_traces()` at `:68-69`, Note only.
- The format hook: `.claude/hooks/validate-tc-format.sh <file>` → exit 0 when valid.

## Commands you will need

| Purpose | Command | Expected |
| --- | --- | --- |
| Agent/command frontmatter | `./tests/test-frontmatter.sh` | exit 0 |
| Plugin manifest | `./tests/plugin/verify-plugin.sh` | exit 0 |
| TC contracts (runs the writer's template through the hook) | `./tests/test-tc-contracts.sh` | exit 0 |
| Traceability fixture | `./tests/test-qa-trace.sh` | `All /qa-trace fixture checks passed` |
| Adapters | `./generate-adapters.sh --clean && ./tests/verify-adapters.sh` | exit 0 |
| Plugin agent names | from an empty temp dir: `claude --plugin-dir <repo> -p "List every subagent type name available to you, one per line." --max-turns 1` | lists `bem-te-vi:qa-groomer`, `bem-te-vi:qa-designer`, `bem-te-vi:qa-writer` |

## Scope

**In scope**: `.claude/commands/qa-agentic.md`, `.claude/agents/qa-groomer.md`,
`.claude/agents/qa-designer.md`, `.claude/agents/qa-writer.md`, `.claude/agents/qa-engineer.md`
(frontmatter only), `.claude/commands/qa-trace.md`, `tests/test-qa-trace.sh`,
`tests/fixtures/qa-trace/`, `tests/test-tc-contracts.sh` (only if the writer template changes),
`plans/README.md`.

**Out of scope**: the TC template's fields and the hook (plans 027, 029); `examples/` (committed
unedited on purpose); the tag taxonomy itself (plan 029).

## Git workflow

Branches `fix/agentic-stage-contract`, `fix/agentic-dispatch-names`, `fix/qa-trace-source-row`,
`fix/agent-tool-lists`. Conventional Commits, atomic. Never add AI attribution lines.

## Items

### Item 1: the stage files carry what the template needs

1. **Groomer** (`qa-groomer.md` output contract): add a header block under `Source:`:

   ```markdown
   Feature: [name] · Code: [FEATURE_CODE, 2-5 capitals] · Tracker: [issue ID or "N/A — none given"]
   Risk: [HIGH | MEDIUM | LOW | "N/A — not assessed"]
   ```

   and end every requirement line with its origin:
   `1. [Atomic requirement] — Origin: AC-2` or `— Origin: Added by QA (<reason>)`. Say how to choose:
   an origin is `AC-n` only when the ticket labels or numbers its acceptance criteria and this
   requirement restates one; otherwise `Added by QA (<why QA added it>)`. Keep "no techniques,
   priorities, tags or test cases".
2. **Designer** (`qa-designer.md`): copy the header block to the top of `checklist.md` unchanged; per
   requirement, copy `Origin:` unchanged and add `Status: [@candidate | @manual-only | @deferred]`
   and `Feature tag: @[feature-code-lowercase]`. For `Technique: Exploratory`, emit a charter stub
   (mission, target, time-box) instead of checks.
3. **Writer** (`qa-writer.md`): fill `feature`, `feature_code`, `tracker_issues`, `risk_level` from
   the header; `Source` from `Origin`; the tags from Suite, Level, Priority, Status and Feature tag.
   `Automation Score` is `N/A — not scored in the pipeline; score with /qa-cases`. An `Exploratory`
   entry becomes one case whose Steps say "Run charter ET-… (see Note)" and whose Note holds the
   charter stub. Remove the sentence telling it to infer the origin.
4. **Director** (`qa-agentic.md`): add "Step 4 — Check": run
   `.claude/hooks/validate-tc-format.sh <folder>/testcases.md` when the file exists in the project;
   on failure, send the hook's output and `checklist.md` (nothing else) back to `qa-writer` once,
   then report any remaining failures to the user rather than editing the file yourself. If the
   hook is not installed, say the format was not checked.

**Verify**: `./tests/test-tc-contracts.sh` and `./tests/test-frontmatter.sh` pass. Then run the
pipeline once on this ticket text and check the result:

```text
SAMPLE-2 Password reset. Acceptance criteria: AC-1 A registered email receives a reset link.
AC-2 The link expires after 30 minutes. AC-3 Unknown emails get the same confirmation message.
```

`.claude/hooks/validate-tc-format.sh <folder>/testcases.md` → exit 0, every `Source` row is `AC-1`,
`AC-2`, `AC-3` or `Added by QA (…)`, and `grep -c '57.5\|52/'` on the file → 0 (no copied
placeholders). Quote the hook output in the PR.

### Item 2: dispatch works in every install

Replace the three dispatch sentences with one rule above the steps:

> Dispatch each stage to its agent. In a plugin install the agents are named
> `bem-te-vi:qa-groomer`, `bem-te-vi:qa-designer` and `bem-te-vi:qa-writer`; in a copied install
> they are `qa-groomer`, `qa-designer` and `qa-writer`. Use the namespaced name when it is in your
> list of agents, otherwise the plain one. If your environment has no subagents, run the three
> stages yourself one after another, and before each stage set aside everything except the file
> that stage reads.

Remove "via the Task tool" (the tool's name differs between versions and editors).

**Verify**: the plugin agent-names command in the table lists the three namespaced agents, and the
command text contains both names: `grep -c 'bem-te-vi:qa-groomer' .claude/commands/qa-agentic.md` → 1.

### Item 3: `/qa-trace` reads the `Source` row

1. In `qa-trace.md`'s link-basis table, add to **traced**: "the **Source** row names an acceptance
   criterion (`AC-n`) that the requirement source labels the same way, or the requirement's own
   ID". Add: "`Added by QA (…)` is not a link to a requirement; such a case counts as a case with no
   requirement unless its Note traces it."
2. Align the result words with `/qa-cases` and `qa-plan`: read
   `.claude/commands/qa-cases.md` (search "not run") and `.claude/skills/qa-plan/SKILL.md:166`, pick
   their shared list, and use it in `qa-trace.md:55`.
3. Extend `tests/test-qa-trace.sh` `tc_traces()` to also treat a Source `AC-n` as traced when the
   fixture's `requirements.md` gives that requirement `Origin: AC-n`; add one such requirement to the
   fixture and update `expected-trace.md` by running the test's own derivations, not by hand.

**Verify**: `./tests/test-qa-trace.sh` → passes, and fails if you revert the `tc_traces()` change
(red-green; quote both).

### Item 4: each agent gets only the tools it needs

Add a `tools:` line to each agent's frontmatter:
`qa-engineer`: `Read, Grep, Glob` (it reviews; it never edits);
`qa-groomer`: `Read, Grep, Glob, Write`; `qa-designer` and `qa-writer`: `Read, Write`.
**Decision for Marco (default: change)**: set `qa-writer`'s `model:` from `haiku` to `sonnet`; it
fills an eleven-row, hook-validated template and was the stage that copied placeholders.

**Verify**: `./tests/test-frontmatter.sh`, `./tests/plugin/verify-plugin.sh` pass; the plugin
agent-names command still lists all four agents.

## Done criteria

- [ ] Item 1's pipeline run produces a `testcases.md` that passes the hook, with real `Source` values.
- [ ] `grep -n 'Task tool' .claude/commands/qa-agentic.md` → no match.
- [ ] `./tests/test-qa-trace.sh`, `./tests/test-tc-contracts.sh`, `./tests/test-frontmatter.sh`,
      `./tests/plugin/verify-plugin.sh`, adapters: all pass.
- [ ] `plans/README.md` row for 030 updated.

## STOP conditions

- The pipeline run in item 1 fails the hook twice for a reason the contracts above do not cover.
- A `tools:` list stops an agent from writing its file (report which tool was missing).
- `tests/test-frontmatter.sh` rejects the `tools:` key; report rather than weakening the test.
- Plan 029 step 3 has not landed (the designer's tag fields depend on it).

## Maintenance notes

- The stage files are now a contract between three agents and `/qa-trace`. Any new template field
  must be traced from groomer to writer, and `tests/test-tc-contracts.sh` should grow a check that
  the writer's template and the designer's output contract name the same fields.
- When Claude Code changes how plugin agents are named, item 2's sentence must follow.

## Outcome (2026-10-14)

Merged as #128, released in 4.0.1. Item 4's model decision went differently from the default above.
Marco decided that each agent's model follows its work: `qa-groomer`, `qa-designer` and
`qa-engineer` reason (requirements, test design, code review), so they run on `opus`; `qa-writer`
only assembles values the checklist already names, so it stays on `haiku`.

*Rejected*: the default, moving `qa-writer` to `sonnet` (`bb394d8`, reverted in `7dd53d7`). The
placeholder copying it targeted is fixed by Item 1's checklist-sourced fields (step 3) and the
format-hook run (step 4), not by a larger model.
