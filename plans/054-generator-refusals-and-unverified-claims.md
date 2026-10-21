# Plan 054: The generators refuse a broken source tree, and three unverified claims get checked

> **Executor instructions**: Branch `fix/generator-and-checks` from `github/next`, one pull request
> into `next`, one commit per item. Item 1 starts with a failing test, on both generators; their
> normal output must stay byte-identical. Items 2 to 4 check a claim against its source and record
> what the source says, quoted, with the date it was read; change shipped text only where the check
> shows it is wrong. Never install anything into a real project or into a Claude Code
> configuration: items 3 and 4 run in throwaway folders. Run `bash ~/qa-ci-all.sh <worktree>` on
> all three platforms before reporting.

## Status

- **Priority**: P1 (Marco, 2026-10-19: everything is developed and fixed before the 4.1.0 export
  unless it can only be done after)
- **Effort**: S
- **Risk**: LOW (item 1 adds a check before the generators write anything; items 2 to 4 are
  records)
- **Depends on**: plan 047 (the generators and their review findings R4 and R5), plan 034 (its
  spot check), plan 022 (the skills-only install)
- **Category**: fix, verification
- **Planned at**: commit `436faa9` (`github/next`), 2026-10-19
- **Plan number**: 054, as assigned; no 052 or later existed on `github/next`, on any `github/`
  branch or in an open pull request when this branch was cut.
- **Outcome**: see "Outcome" below

## Why this matters

Four items from the pre-export review list, each a claim or a defect nothing checked:

1. **I12.** Plan 047's review, finding R4: `generate-adapters.sh` writes `adapters/skills//SKILL.md`
   for a command or agent with no `id` in its frontmatter (the PowerShell generator throws instead),
   and an id equal to a skill folder's name lets one silently overwrite the other. Only the file
   count in `tests/verify-adapters.sh` would notice the first, and nothing notices the second.
2. **I17.** Plan 047, finding R5: Copilot code review may read only the first 4,000 characters of
   an instructions file, which would leave most of `.github/copilot-instructions.md` unseen. Not
   confirmed on GitHub's pages.
3. **I19.** `README.md` says `npx skills add` finds "the eight skills ... and nothing else". Not
   re-run since #109, and `tests/fixtures/release-v4.0.1/.claude/skills` holds four more
   `SKILL.md` files under the same names.
4. **I21.** Plan 034 has no Outcome, and its behavioural spot check (a project install and a plugin
   install each opening a reference on demand) was never done ("not done yet" in #138's body).

## Steps

1. **I12.** Both generators check every skill name before they write or remove anything: a command
   or agent with no id, and a name two sources share (command, agent, skill folder or the generated
   `qa-rules`), are reported in a fixed order with the same words, and the run exits 1.
   `tests/fixtures/generator-errors.txt` holds the planted trees and the expected lines;
   `tests/test-generator-errors.sh` and `tests/test-generator-errors.ps1` read it, and
   `tests/verify-adapters.sh` and `tests/verify-adapters.ps1` run them, so the Linux, macOS and
   Windows jobs all do.
2. **I17.** Read GitHub's current pages on Copilot code review and custom instructions; quote them.
   If a limit is documented and applies, do not change the layout: it is a decision for Marco.
3. **I19.** Run `npx --yes skills@1.7.2 add <clone of github/next> --list` in a throwaway folder;
   check whether the fixture copies are listed or installed; make the README true.
4. **I21.** In throwaway folders, a project install (`./install.sh --target project --editor claude
   --non-interactive`) and a plugin load (`claude -p --plugin-dir <clone>`), each asked a question
   only one reference answers; at most 4 runs on `--model haiku`; stop if Claude Code refuses.

## Done criteria

- [x] Both generators exit non-zero, with the same lines, on every planted tree; a valid tree still
  generates; the repository's own adapters are byte-identical before and after.
- [x] What GitHub's pages say about the 4,000 characters is quoted, with URL and date, here and in
  plan 047.
- [x] The `npx skills` listing is recorded, and the README says what it shows.
- [ ] Plan 034's spot check is recorded for a project install and a plugin install (stopped, see
  item 4: the weekly usage limit).
  **2026-10-19, coordinator:** done by plan 057 (#203), see the note under item 4 below.
- [x] `plans/README.md` row for 054.

## STOP conditions

- A documented Copilot limit applies to `.github/copilot-instructions.md`: report it as a decision
  for Marco, change nothing.
- Claude Code in MarcoWork is not logged in or refuses to run: stop item 4 and report it. Never use
  another Claude Code installation, never install into a Claude Code configuration.

## Outcome

### Item 1 (I12): the generators refuse a broken source tree (2026-10-19)

**Reproduced first**, with `generate-adapters.sh` at `436faa9` on a planted tree (a command
`qa-noid.md` with no id, an agent with `id: qa-plan` beside the skill folder `qa-plan/`): exit 0,
`adapters/skills/SKILL.md` written with `name:` and `id:` empty, and `adapters/skills/qa-plan/SKILL.md`
held the skill folder's text; the agent's text was gone with no message.

**Red.** `tests/test-generator-errors.sh` against the unchanged bash generator failed all five
refusal cases, for example:

```text
  ✘ missing-id: expected a non-zero exit, got 0
  ✘ missing-id: error lines differ from tests/fixtures/generator-errors.txt
  ✘ missing-id: adapters/ was written although the generator refused the tree
  ✘ id-is-a-skill-folder: expected a non-zero exit, got 0
```

`tests/test-generator-errors.ps1` against the unchanged `generate-adapters.ps1` (Windows PowerShell
5.1) failed the same five: on a missing id it exited non-zero, as R4 says, but printed no `[ERR]`
line and had already written `adapters/`; on every shared name it exited 0.

**Fix.** Both generators now check the skill names after reading their helpers and before
`--clean` or any write: commands, then agents (each in byte order), then skill folders, then
`qa-rules`. A source with no id, or with an empty one, and a name already claimed are each one
`[ERR]` line; after all of them, `[ERR]   Nothing was written to adapters/.` and exit 1. The names
are compared exactly (case-sensitive) in both; a name differing only in case is still caught by
`tests/verify-adapters.*`, which requires lowercase skill names. The `--clean` block and the two
`Source:`/`Output:` lines moved below the check, so a refused run leaves an existing `adapters/`
as it was.

**Test.** `tests/fixtures/generator-errors.txt` holds the planted trees and the exact lines; the
two test scripts read it, so a wording change in one generator fails the other's test. Cases:
valid tree, missing id, id equal to a skill folder, an agent sharing a command's id, an id equal
to `qa-rules`, and two problems in one tree (both reported). `tests/verify-adapters.sh` and
`tests/verify-adapters.ps1` run them, so the Linux, macOS and Windows jobs do without a change to
their steps; the Linux job's adapters step also shellchecks the new script.

**Green and unchanged output.** Both tests pass (bash 5 and bash 3.2.57; Windows PowerShell 5.1).
On this repository, `generate-adapters.sh --clean --no-color` before and after: `diff -r` of the
two `adapters/` trees and of the console output, both empty. `generate-adapters.ps1 -Clean -NoColor`
after the change: `diff -r` against the bash tree from before, empty (91 files, 24 skills).

### Item 2 (I17): Copilot code review's 4,000 characters (2026-10-19)

**Finding: the limit existed and GitHub removed it on 2026-06-12.** No change to the layout.

- GitHub Changelog, "Copilot code review: New configurations and controls", dated June 12, 2026
  (<https://github.blog/changelog/2026-06-12-copilot-code-review-new-configurations-and-controls/>),
  read 2026-10-19, section "Custom instructions character limits have been removed": "Previously,
  Copilot code review would stop reading `copilot-instructions.md` and `*.instructions.md` files
  located under the `.github` directory once the file reached 4000 characters in size. That limit
  has now been removed, allowing additional customization and flexibility in your custom
  instructions."
- "Using custom instructions to unlock the power of Copilot code review"
  (<https://docs.github.com/en/copilot/tutorials/customize-code-review>), read 2026-10-19: "Shorter
  instruction files are more likely to be fully processed by Copilot." "Best practice: Limit any
  single instruction file to a maximum of about 1,000 lines. Beyond this, the quality of responses
  may deteriorate." Under troubleshooting, "Instructions are ignored", a possible cause: "Instruction
  file is too long (over 1,000 lines)." No character limit.
- No "4,000", "4000" or "character limit" on these pages, read the same day as raw HTML and
  searched: "Using GitHub Copilot code review on GitHub"
  (<https://docs.github.com/en/copilot/how-tos/copilot-on-github/use-copilot-agents/copilot-code-review>),
  "Using GitHub Copilot code review"
  (<https://docs.github.com/en/copilot/how-tos/use-copilot-agents/use-code-review>), "Support for
  different types of custom instructions"
  (<https://docs.github.com/en/copilot/reference/custom-instructions-support>), the code review
  concept page and "Adding repository custom instructions"
  (<https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/add-custom-instructions/add-repository-instructions>),
  and the Spanish copy of the first.
- A web search's summary still quotes "Copilot code review only reads the first 4,000 characters
  of any custom instruction file. Any instructions beyond this limit will not affect the reviews
  generated by Copilot code review." attributed to the first page above; the live page no longer
  has it. That is the earlier wording plan 047 R5 met.

**Measured**, `adapters/copilot/rules/copilot-instructions.md` generated at `436faa9`: 393 lines,
23,227 bytes, 23,142 characters. Under the documented "about 1,000 lines" and inside the 850-line
budget `tests/verify-adapters.*` holds it to. Nothing for Marco to decide: the STOP condition did
not fire.

### Item 3 (I19): what `npx skills add` finds in a clone (2026-10-19)

**Finding: the README is right; nothing changed.** In a throwaway folder in MarcoWork, with a
fresh clone of `github/next` at `436faa9` (no `adapters/`, which is not committed), skills 1.7.2
(the npm `latest` tag that day), telemetry off (`DO_NOT_TRACK=1`, `DISABLE_TELEMETRY=1`):

- `npx --yes skills@1.7.2 add <clone> --list` printed "Found 8 skills": `qa-a11y`, `qa-api`,
  `qa-explore`, `qa-flaky`, `qa-migrate`, `qa-plan`, `qa-reference`, `qa-release`, each with the
  description from `.claude/skills/<name>/SKILL.md`. The same eight with `--full-depth`.
- To see which copy the four duplicated names resolve to, `add <clone> --skill '*' --agent
  claude-code --copy --yes` into a second throwaway folder, with `HOME` pointed at a throwaway
  folder too: it wrote the eight folders under `.claude/skills/` and nothing else. Each of
  `qa-explore`, `qa-migrate`, `qa-plan` and `qa-reference` is byte-identical to
  `.claude/skills/<name>/SKILL.md` and differs from the fixture copy in
  `tests/fixtures/release-v4.0.1/`; the installed `qa-reference` folder is identical to the
  source, references included.

**Why the fixtures are never picked up**, from the tool's code (`dist/cli.mjs`, `discoverSkills`):
it looks first in the source root, `skills/` and the agents' project folders such as
`.claude/skills` (three levels deep), and walks the whole tree only when that finds nothing or
with `--full-depth`; that walk stops at depth 5, and the fixtures' `SKILL.md` folders are at
depth 6 (`tests/fixtures/release-v4.0.1/.claude/skills/<name>`). Within one listing a name already
seen is skipped, so even a found duplicate would lose to the real skill. `skills update` walks with
duplicates allowed, but under the same depth limit. The tool has no ignore file (no
`.skillsignore` or similar in 1.7.2), so there is no exclusion to add; moving the fixtures was not
needed. For a GitHub source owned by `MarcoAmaral` the tool clones the repository and runs the
same discovery (its blob API is used only for a few listed owners).

Left as is: if a fixture ever sits one level higher, or the tool raises its depth, the fixture
copies would be found; the real ones would still win within `add`.

### Item 4 (I21): plan 034's spot check (2026-10-19)

**Stopped, as the STOP condition says.** MarcoWork's Claude Code (2.1.224) is logged in (`claude
auth status`: `"loggedIn": true`, a Pro subscription), but the first run was refused before the
model answered: `"api_error_status":429`, "You've hit your weekly limit · resets Oct 21, 2pm
(America/Sao_Paulo)", cost 0. One run of the four allowed was used; the plugin run was not
attempted. The set-up, the one piece of evidence the refused run still gives (the project install's
skills and commands are registered) and how to finish are in plan 034's new "Outcome" section.
`claude plugin list` before and after: identical; `~/.claude/settings.json`: same SHA-256.

> **Note, 2026-10-19, coordinator.** The spot check this item stopped on was done later the same
> day by plan 057 (#203), on its branch after the pointer form changed: a project install of the
> package (runs A1-A3, each a question only one reference answers, all three answered from that
> reference) and a plugin load with `--plugin-dir` (runs P1c and P2, both answered from the
> reference). The table is in plan 057, "Evidence after the change". Plan 034's criterion is met by
> those runs, not by the run recorded above.
