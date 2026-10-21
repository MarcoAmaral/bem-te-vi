# Plan 057: A pointer to a reference file opens in every install

> **Executor instructions**: Branch `fix/reference-pointers-resolve` from `github/next`, one pull
> request into `next`. Reproduce the defect before changing anything (the red baseline below), then
> change the pointer form, then the test, then repeat the spot check on the branch. One concern per
> commit. Run `bash ~/qa-ci-all.sh <worktree>` before reporting. The installer items at the end
> wait for PR #200; skip them and say so if it has not merged within 60 minutes. Installer changes
> start with a failing conformance case and keep the three installers identical (`CLAUDE.md` item 5).

## Status

- **Priority**: P1 (a reference named by a rule is the only route to its content, and the route
  failed in a Claude Code project install)
- **Effort**: S
- **Risk**: LOW (wording of shipped pointers, one generated index line, one test; no installer or
  file-safety change in the pointer part); LOW for the installer items (two messages and one
  counter, no change to what is written)
- **Depends on**: plan 034 (the pointer convention this plan replaces), plan 043 (references
  shipped beside each non-Claude adapter), plan 047 (the editor-native skills and the index rule),
  plan 053 (#200, the installer items)
- **Category**: fix (shipped content, installers), test
- **Planned at**: commit `a97162e` (`github/next`), 2026-10-19
- **Source**: the coordinator's behavioural spot check of plan 034, 2026-10-19
- **Outcome**: done, see "Outcome (2026-10-19)"

## Why this matters

Shipped content named an on-demand reference as `qa-reference/references/<file>.md`, for example
`.claude/rules/test-evidence.md:27`: "Code examples, the skipped-test recording trap and pacing:
`qa-reference/references/evidence-capture.md`." There were 78 such pointers across rules,
commands, agents, skills and the reference files themselves (`grep -rnoE
'qa-reference/references/[A-Za-z0-9_.-]+\.md' .claude`, `qa-reference/SKILL.md` excluded).

In a Claude Code project install (`install.sh --target project --editor claude`), Claude Code with
`--model haiku`, asked a question whose answer is only in `evidence-capture.md`, read
`<project>/qa-reference/references/evidence-capture.md` (the pointer taken as a path from the
project root; the file is at `<project>/.claude/skills/qa-reference/references/evidence-capture.md`),
then globbed `qa-reference/**/*.md` (no hit), and answered "The evidence-capture.md reference file
is not present in this project". The skill itself said the path means "the references/ folder of
this skill, wherever the skill is installed", but a reader who has not loaded the skill never sees
that sentence.

## Current state (measured at `a97162e`)

- **What resolves where.** Plan 034's table still holds: a Claude Code project install has
  `.claude/skills/qa-reference/references/`; a global one `~/.claude/skills/qa-reference/references/`;
  a plugin install (`--plugin-dir <clone>` or the marketplace) has the skill under the plugin root,
  `<plugin root>/.claude/skills/qa-reference/` (`.claude-plugin/plugin.json` lists
  `"skills": ["./.claude/skills/"]`), and no rules. No form of `qa-reference/references/...` is a
  path from the project root in any of them.
- **The generators do not rewrite pointers.** Since plan 047 the sources are copied verbatim into
  `adapters/skills/` (`generate-adapters.sh`, `strip_frontmatter` and `cp` only). The one place a
  generator explains a pointer is the always-on index rule (`index_body`, "How a pointer in the
  package's text resolves"), which told Cursor, Windsurf, Copilot, Cline and Antigravity that
  `qa-reference/references/<file>.md` "is that file in the `qa-reference` skill's `references`
  folder". Claude Code has no index rule: its rules are the source files.
- **How Claude Code tells a reader where a skill is.** When a skill loads, Claude Code prefixes its
  body with "Base directory for this skill: <absolute path>" (seen in the transcripts below for a
  project skill and a plugin skill). A skill's description is in the skill listing in every
  conversation, in project, global and plugin installs.
- **`tests/test-reference-links.sh`** accepted `<skill>/references/<file>.md` as the form that
  "opens in every install", which is the form that failed.
- **Rules budget**: 21,855 bytes of 25,000 (`tests/test-rules-size.sh`).

### Red baseline (2026-10-19, before any change)

Three questions, each answered only in one reference that a rule points to, asked once each in a
project install of `a97162e`. Command, from inside `<project>` (a fresh `git init` folder with
`bash <clone>/install.sh --target project --editor claude --non-interactive`):
`claude -p "<question>" --model haiku --setting-sources project,local --strict-mcp-config
--allowedTools Read Glob Grep Skill --output-format stream-json --verbose < /dev/null`.

| Run | Reference (pointed to by) | Tool calls | Answer | Cost (USD) |
| --- | --- | --- | --- | --- |
| B1 | `evidence-capture.md` (`test-evidence` rule) | Read `<project>/qa-reference/references/evidence-capture.md` (does not exist); Glob `**/evidence-capture.md`; Read `<project>/.claude/skills/qa-reference/references/evidence-capture.md` | right (middle dot) | 0.0560 |
| B2 | `accessibility-checks.md` (`accessibility-qa` rule) | Read `<project>/qa-reference/references/accessibility-checks.md` (does not exist); Glob `**/accessibility-checks.md`; Read the right file | right (VoiceOver, NVDA, TalkBack) | 0.0546 |
| B3 | `context-sources.md` (`context-discovery` rule) | Read `<project>/qa-reference/references/context-sources.md` (does not exist); Bash `find <project> -type f -name "*.md"`; Read the right file | right (`comments.md`) | 0.0582 |

Every first read missed: the pointer was taken as a path from the project root in 3 of 3 runs. The
model recovered here only by searching the project tree, which holds the files in a project install
alone; in a global install the files are under `~/.claude/skills/`, outside the project, so the same
search would not find them (reasoning from the install layout, not a run). The coordinator's run of
the same question recovered with a narrower glob and failed outright.

`tests/test-reference-links.sh` as changed by this plan, run against the `a97162e` tree, fails:
32 files flagged, 58 pointers, for example

```text
  ✘ .claude/rules/test-evidence.md names a path with a folder before references/; write the `<skill>` skill's `references/<file>.md`:
      qa-reference/references/evidence-capture.md
Reference link check failed.
```

## Decision: name the skill, not a path

**Every pointer reads "the `qa-reference` skill's `references/<file>.md`"**, and the reader is
told once, where it reads, how to open it:

- in the `qa-reference` skill's **description**, which every Claude Code install lists in every
  conversation: "Text that names the `qa-reference` skill's `references/<file>.md` means a file in
  this skill's folder: load this skill, then read it there." (1,013 characters, under the 1,024
  `tests/test-frontmatter.sh` allows);
- in **each other skill** that names a `qa-reference` file (`qa-a11y`, `qa-api`, `qa-explore`,
  `qa-flaky`, `qa-migrate`, `qa-plan`, `qa-release`), one line: "Files named ... are in the
  `qa-reference` skill's folder, not this skill's: load the `qa-reference` skill and read them
  there." A loaded skill's base directory is its own folder, and run P1b below shows a reader then
  looks for the file there;
- in the **dispatching commands** (`/qa-agentic`, `/qa-review`): the agents have no Skill tool
  (`tools:` in their frontmatter), so the command loads `qa-reference` and passes its folder;
- in the **index rule** the generators write for the five other editors, which now explains the
  same form;
- in `qa.md`'s "How the package names its files", the `qa-reference` skill's own closing paragraph,
  the README and CONTRIBUTING.

Why: a loaded skill is the one thing every install can locate. Claude Code reports a skill's folder
when it loads, in project, global and plugin installs alike; the other editors install each skill
as a folder in their skills folder and list it. A path, in any spelling, is a guess at one layout.
The form costs 14 bytes more per pointer than plan 034's; the 11 rule pointers bring the rules from
21,855 to 22,009 bytes (cap 25,000).

### Rejected

- **(a) as briefed, a verb in every pointer** ("load the `qa-reference` skill, then read
  `references/evidence-capture.md` in its folder"). It reads badly in most of the 78 places (a
  pointer is usually the object of "in", "see" or "follows"), needs a hand rewrite of each, and
  adds about 45 bytes per pointer (about 500 to the rules). The noun form plus one instruction where the
  reader is (the description, each skill, each dispatcher) gave the same tool calls in the runs.
- **(b) concrete paths written per install by the installers and generators.** It changes the
  installed bytes per target, so every adopted-file hash in `.qa-skills-known-hashes` and the
  "identical to the package's file" test in all three installers would need a per-target variant;
  the plugin is never installed by an installer, so it would still get the source text. Kept for
  the record: only if the noun form had failed.
- **(c) list the concrete locations in each pointer** ("`.claude/skills/qa-reference/references/…`
  in a project install, `~/.claude/skills/…` in a global one"). Three to six paths per pointer, a
  `.claude/` path that `tests/test-reference-links.sh` refuses for a reason (plan 034), and still
  no answer for the plugin cache, whose path Claude Code chooses.
- **Keep the old form and add only the description sentence.** The old form looks like a path,
  and the red runs show it is read as one first; the noun form does not.
- **A resolution line in a rule every session loads.** The plugin has no rules, so it would not
  reach the install that most needs it; the description reaches every Claude Code install.

## Steps (done)

1. Rewrite the 78 pointers to the noun form (one script, then the three sentences that read badly
   by hand: `qa.md`'s convention paragraph, `qa-automate.md`'s table header and "an XSS payload
   spec follows"); rewrite the `qa-reference` description and closing paragraph.
2. `/qa-agentic` and `/qa-review`: load `qa-reference` and pass its folder to the agents.
3. Both generators: the index rule's pointer bullet names the new form (byte-identical output,
   `tests/verify-adapters.*`).
4. `tests/test-reference-links.sh`: accept only the named form (or a bare `references/<file>.md`
   in the skill's own `SKILL.md`), read text with whitespace collapsed so a wrapped pointer counts,
   refuse any folder before `references/`, and require a `SKILL.md` that names another skill's file
   to say whose folder it is in. Self-tests for each; red on `a97162e` as above.
5. The line in the seven other skills (after run P1b).
6. README and CONTRIBUTING describe the form; plan 034 carries a dated note.

## Evidence after the change

Same command and questions, on the branch. A1-A3 ran on `6b40b2c` (rules, commands and the
description changed; the seven-skill line not yet added, which does not touch rules). The plugin
runs ran from an empty folder with `--plugin-dir <clone>` added, on questions only a command or a
skill points to, since a plugin has no rules.

| Run | Install, commit | Reference (pointed to by) | Tool calls | Answer | Cost (USD) |
| --- | --- | --- | --- | --- | --- |
| A1 | project, `6b40b2c` | `evidence-capture.md` (`test-evidence` rule) | Skill `qa-reference`; Read `<project>/.claude/skills/qa-reference/references/evidence-capture.md` | right | 0.0557 |
| A2 | project, `6b40b2c` | `accessibility-checks.md` (`accessibility-qa` rule) | Skill `qa-reference`; Read the right file | right | 0.0544 |
| A3 | project, `6b40b2c` | `context-sources.md` (`context-discovery` rule) | ToolSearch; Skill `qa-reference`; Read the right file | right | 0.0528 |
| P1 | plugin, `6b40b2c` | `automation-ci.md` (`qa-flaky` skill) | Bash `find .` (nothing); Bash `find ~` (refused, needs approval); never loaded `qa-flaky` | not answered | 0.0351 |
| P1b | plugin, `6b40b2c` | same, question says "Use the qa-flaky skill" | Skill `bem-te-vi:qa-flaky`; Read `<clone>/.claude/skills/qa-flaky/references/automation-ci.md` (does not exist); Glob `<clone>/.claude/skills/**/*.md`; Read the right file | right (100) | 0.0426 |
| P1c | plugin, `2339970` | same question as P1b | Skill `bem-te-vi:qa-flaky`; Skill `bem-te-vi:qa-reference`; Read `<clone>/.claude/skills/qa-reference/references/automation-ci.md` | right (100) | 0.0379 |
| P2 | plugin, `6b40b2c` | `defect-system-info.md` (`/qa-defect` command) | Skill `bem-te-vi:qa-defect`; Skill `bem-te-vi:qa-reference`; Read `<clone>/.claude/skills/qa-reference/references/defect-system-info.md` | right (`npx next --version`) | 0.0501 |

Ten runs, all `claude-haiku-4-5-20251001`, US$0.4975 in total. A1-A3: no missed read, the skill
loaded and its base directory used ("Base directory for this skill:
<project>/.claude/skills/qa-reference" in the transcript). P1 failed before any pointer was read:
the model never loaded the skill the question names, so it says nothing about the pointer form.
P1b found the second defect, the skill-relative misreading, fixed by step 5 and confirmed by P1c.

**Nothing was installed into any Claude Code configuration.** From the maintainer's working folder (the same
working directory both times), `claude plugin list` and `sha256sum ~/.claude/settings.json` were
saved before the first run and after the last; apart from the timestamp the two outputs are
identical (settings `05fcc75c10eb1b84400a52260850afa66c167108f309a61f93be73543c1fd6ca`, the same
seven user and project plugins, no `bem-te-vi`).

## Done criteria

- [x] No `<folder>/references/` path under `.claude/{commands,skills,agents,rules}`;
  `tests/test-reference-links.sh` refuses one and passes on the branch.
- [x] Red baseline and after runs recorded, with the configuration unchanged.
- [x] Rules total under the 25,000-byte cap (22,009).
- [x] Adapters byte-identical from both generators; `bash ~/qa-ci-all.sh` green.

## STOP conditions

- A pointer form that needs a `.claude/` path back: stop (plan 034's STOP condition stands).
- The rules would exceed 25,000 bytes.
- The after runs show the reference still not opened in a project install.

## Not verified

- Claude Code **global** install (`~/.claude/skills/`): not run, to keep every run out of the
  user configuration. The mechanism (load the skill, use its base directory) is the one A1-A3 and
  the plugin runs use; only the folder differs.
- The five other editors: not run in this environment. Their index rule explains the form, and
  each lists its skills with their folders.
- The agents: `/qa-agentic` and `/qa-review` now pass the folder; no run dispatched an agent.

## Outcome (2026-10-19)

Pointer form changed, test extended, spot check green in a project install and through the plugin
(table above). Plan 056 (#202) reached `next` while this branch was open and added 15 pointers
in the old form, with `tests/test-skill-bodies.sh` checking for that form; the merge commit
rewrites the 15 and makes that check look for "the `qa-reference` skill's `references/<file>.md`"
with whitespace collapsed (case-insensitive, for a pointer that opens a bullet). Installer items: see "Installer items from plan 053" below.

## Installer items from plan 053

Plan 053's outcome, "Found and not changed", left three installer findings. They were done here
after PR #200 (plan 053) merged into `next` (merge seen at 18:00 UTC, 2026-10-19).

1. **`install.ps1` defined `Copy-QAFile` and never called it.** `grep -rn Copy-QAFile` found only
   the definition and plan 053's note. Removed; no other function became unused (each function name
   in `install.ps1` occurs more than once after the removal).
2. **Every destination skipped, yet "Installation successful!" (`install.sh`, `install.ps1`) or
   "Done!" (the CLI) and the next steps.** All three now print, in the same words, "Nothing was
   installed: every destination was skipped (see above)." and neither the success line nor the
   next steps, when the run wrote no file (`FILES_WRITTEN_COUNT`, `$script:FilesWritten`, and a new
   `filesWritten` counter in the CLI, each incremented where the file is copied). The exit status
   stays 0, as case 062 requires. Red first, conformance case 067 (case 062's layout, both editors):

   ```text
   install.sh  FAIL
     ✘ output lacks 'Nothing was installed: every destination was skipped (see above).'
     ✘ output contains 'Installation successful!'
     ✘ output contains 'Next steps'
   cli         FAIL
     ✘ output lacks 'Nothing was installed: every destination was skipped (see above).'
     ✘ output contains 'Done!'
   ```

   Case 067 needs symbolic links, so on this Windows machine (no symlink privilege) it is NOT RUN for
   `install.ps1`, as case 062 is. Lifecycle Test 51 in `tests/test-lifecycle.ps1` builds the same
   layout with junctions; it now also requires the sentence once per run and no success line. Its
   setup, run by hand in Windows PowerShell 5.1 against the old and the new `install.ps1`:
   old "nothing-installed lines: 0; success line present: True; next steps present: True", new
   "nothing-installed lines: 2; success line present: False; next steps present: False".
3. **Update counted a skipped destination as kept in `install.sh` even when the manifest had not
   recorded it.** `install.ps1` and the CLI count a folder or an unreadable file only when recorded;
   `install.sh` now does the same (the linked-folder branch already did). Red first, conformance case
   068 (a folder where `.cursor/rules/bem-te-vi.mdc` goes, install, then update):

   ```text
   install.sh  FAIL
     ✘ output contains 'kept as-is'
       Update complete — 1 file(s) kept as-is (see above).
   cli         pass
   ```

   After the change both pass, and on Windows `install.ps1` and the CLI pass (they were already
   right).
