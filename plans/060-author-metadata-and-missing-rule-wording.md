# Plan 060: Every Agent Skill names its author, and a file whose rule is not loaded says so

> **Executor instructions**: Branch `feat/author-and-plugin-rules-wording` from `github/next`, one
> pull request into `next`, the two decisions below in separate commits. Both edit shipped
> `.claude/` content, so regenerate nothing by hand: `adapters/` comes from the generators, and the
> known-hash list from `generate-known-hashes.sh`. A check that should fail starts red. Keep
> `tests/test-skill-bodies.sh`, `tests/test-rules-size.sh`, `tests/test-docs-drift.sh` and `node
> benchmark/build.js --check` green; if the placebo leaves its 75% to 125% band, stop. Run
> `bash ~/qa-ci-all.sh <worktree>` on all three platforms before reporting.

## Status

- **Priority**: P2 (attribution in copies, and an honest reply in a plugin install)
- **Effort**: S
- **Risk**: LOW (frontmatter and one paragraph in shipped files; installer behaviour unchanged)
- **Depends on**: plan 018 (raised the author field), plan 022 (the plugin ships no rules), plan
  032 (known hashes), plan 038 (frontmatter ids), plan 047 (generated Agent Skills, `qa-rules`),
  plan 048 (the benchmark's condition D)
- **Category**: content, generator
- **Planned at**: commit `8761bf4` (`github/next`), 2026-10-20
- **Outcome**: done, branch `feat/author-and-plugin-rules-wording` (into `next`), see "Outcome"

## Why this matters

Two decisions Marco made on 2026-10-20.

1. **Q14, the author in every skill.** Plan 018 ("Out of scope") left open "an `author:` field
   in SKILL.md frontmatter so copies carry the name", because it touches installed files and
   their hashes. A skill copied out of the package keeps its frontmatter and loses the README.
2. **Q4, a plugin install has no rules.** Plan 022 ("Decisions for Marco", item 2) offered three
   options for a command that names a rule in a plugin install: (a) leave and document, (b)
   reword so a missing rule is explicitly non-fatal, (c) carry the rules in skills. Plan 022
   shipped (a). `ROADMAP.md` kept the gap open: "the goal is to close the gap or make each
   command say what it is missing." Marco chose (b).

## Evidence

**The Agent Skills format** (agentskills.io/specification, read 2026-10-20). The frontmatter
fields are `name`, `description`, `license`, `compatibility`, `metadata` and `allowed-tools`. Of
`metadata`: "A map from string keys to string values. Clients can use this to store additional
properties not defined by the Agent Skills spec." Its example is

```yaml
metadata:
  author: example-org
  version: "1.0"
```

**Which files have a `metadata` map.** Only a `SKILL.md`. Plan 038 put the `id` of a `SKILL.md`
under `metadata:` because "the Agent Skills specification allows no other top-level key"
(`tests/test-frontmatter.sh`), and the `id` of every other file (commands, agents, rules, skill
references) at top level: those are Claude Code commands, subagents and rules, or plain reference
files, and none of their formats has a `metadata` map. So the author goes into:

- the eight `.claude/skills/*/SKILL.md`, which every install copies as they are, the plugin and
  `npx skills add` included;
- every generated Agent Skill in `adapters/skills/`: the eleven commands and four agents become
  skills in `generate-adapters.sh` and `generate-adapters.ps1`, which wrote `metadata:` with the
  `id` only. Both now write `author: Marco Amaral` after it, and the same in the generated
  `qa-rules` skill. The eight copied skills carry it from their source.

Commands, agents and rules get no `metadata:` map: it would be a key their formats do not define,
added to files Claude Code reads directly, for no reader.

**What a plugin receives.** `.claude-plugin/plugin.json` names `./.claude/commands/`,
`./.claude/skills/` and the four agent files, nothing else. The `qa-rules` skill exists only in
`adapters/skills/qa-rules/`, written by the generators (plan 047), so it never reaches a plugin,
and neither does `npx skills add`, which installs the eight skills under `.claude/skills/`. The
`qa-reference` skill does reach a plugin, but it holds "the detail behind" the rules and says "the
rule wins" when they disagree (its `SKILL.md`, "How to use"): it is not the rules. So in a plugin
install there is no rule content to fall back to, and the wording is the second branch of the
decision: go on without the rule and say so in the reply. In a global install of Cursor, Windsurf
or Antigravity there are no rule files either, but there the `qa-rules` skill is installed (plan
047), so the one sentence covers both branches.

## Steps

1. Q14, red first: `tests/test-frontmatter.sh` requires `author: Marco Amaral` under `metadata:`
   in every shipped `SKILL.md`; `tests/verify-adapters.sh` and `tests/verify-adapters.ps1` require
   it in every generated `adapters/skills/*/SKILL.md`. Then add it to the eight sources and to
   both generators.
2. Q4: one paragraph, the same in every file that names a rule, placed after the file's banner:

   > **If a rule is not loaded.** When a rule this file names is not in your context, load the
   > `qa-rules` skill and read that rule in the skill's own `references` folder. If no `qa-rules`
   > skill is installed either (a Claude Code plugin install has neither), go on without the rule
   > and say at the end of your reply which rule you could not apply.

   Files: the commands `qa`, `qa-agentic`, `qa-automate`, `qa-bdd`, `qa-cases`, `qa-defect`,
   `qa-static`, `qa-tdd`, `qa-trace`; the agents `qa-designer`, `qa-engineer`, `qa-groomer`; the
   skills `qa-a11y`, `qa-api`, `qa-flaky`, `qa-migrate`, `qa-release`, `qa-reference` (whose
   references name rules too, and are read only through it).
3. README (the plugin paragraph and the install table), `ROADMAP.md`, the docs-drift size cells,
   and a `benchmark/DEVIATIONS.md` entry for the seven files condition D loads.

## Decisions

- **The sentence says "at the end of your reply".** Several deliverables must start with a fixed
  block (a test case file with its frontmatter, which the benchmark's `fmt-frontmatter` grader
  and `validate-tc-format.sh` check). A note at the start would break that.
- **It does not use the pointer form** "the `qa-rules` skill's `references/<rule>.md`".
  `tests/test-reference-links.sh` resolves that form against `.claude/skills/`, where `qa-rules`
  does not exist (it is generated), so the sentence names the skill and its `references` folder
  instead.
- **Files with no rule name are left alone**: `qa-refinement`, `qa-review`, `qa-writer`,
  `qa-explore` and `qa-plan`. `qa-plan` says "per code style rules" in one checklist line, a
  general phrase, not a pointer to a rule, so it was not counted as relying on one.
- **The known-hash list needs nothing.** `generate-known-hashes.sh` builds
  `.qa-skills-known-hashes` from the tagged releases and `known-hashes-before-public.txt` only;
  it never lists the working tree. A file as it ships now is adopted because it is identical to
  the package's current file (CLAUDE.md, "Installer File-Safety Contracts"), and a 4.0.1 file
  because its hash is in the list. This change adds no tag and edits no released file, so the
  list and `--check` are unchanged; the next release's tag will add the new hashes when the
  script runs then. Lifecycle Tests 20, 35, 54, 63 and 67 cover the adoption paths and pass.

## Rejected approaches

- **A top-level `author:` in commands, agents and rules.** Not what the decision asked (it is
  about the `metadata` map), and it would put a key Claude Code does not define into files it
  reads directly. The generated skills of the commands and agents carry the author instead.
- **A paragraph per file in its own words.** Eighteen variants of one fact would drift; one
  sentence, word for word, can be checked with `grep -c`.
- **Carrying the rules into the plugin** (plan 022 option (c)). Not this decision; it changes what
  every plugin user loads, and stays open in `ROADMAP.md`.

## Outcome (2026-10-20)

- Red: `tests/test-frontmatter.sh` failed on all eight `SKILL.md` ("metadata has no 'author:
  Marco Amaral'"), `tests/verify-adapters.sh` on all 24 generated skills. Green after the change.
- The sentence is in 18 files. Sizes: `qa-defect` 18,632 bytes, the largest body, under the
  20,000-byte cap. Docs-drift cells updated: `/qa-cases` and `/qa-static` ~18KB, `/qa-bdd` ~13KB,
  `/qa-trace` ~8KB, in the README and the `/qa` router.
- Benchmark: digest unchanged, placebo 106.5% of the 14,550-byte mean (108.8% of 14,236 before).
