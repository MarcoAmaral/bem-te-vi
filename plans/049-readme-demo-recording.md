# Plan 049: A short, re-recordable demo of Bem-te-vi for the README

> **Executor instructions**: Marco asked on 2026-10-18 for all remaining work to be done now. This
> plan lands as its own pull request into `next` (branch `docs/plan-049-demo`); the implementation
> follows on a branch stacked on it (`docs/readme-demo-recording`). One concern per commit. Run every
> verification command and read its output. If anything in "STOP conditions" occurs, stop and
> report. When done, update this plan's row in `plans/README.md`.
>
> **Drift check (run first)**: `git diff --stat 8487bd6..HEAD -- README.md examples/demo-script.md
> examples/README.md .claude/commands/qa-cases.md .claude/hooks/validate-tc-format.sh bin/cli.js
> package.json`. A change to the `/qa-cases` template or to the hook since planning means the trial
> run below no longer proves the demo will pass the hook: run the trial again before recording.
>
> **Note, 2026-10-19.** Plan 051 moved the CLI from `bin/cli.js` to `cli/bem-te-vi.js`. In the
> drift check above, name both paths, so a later change to the CLI is still seen.

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: LOW (documentation and a few committed media files; nothing shipped changes)
- **Depends on**: plan 019 phase 7 (the storyboard), plan 030 (`/qa-cases` output passes the hook)
- **Category**: docs
- **Planned at**: commit `8487bd6` (`github/next`), 2026-10-18
- **Source**: plan 019 phase 7 step 1, which asked for a demo and wrote a storyboard for recording
  it by hand

## Why this matters

A visitor decides in seconds whether a package is worth reading. The README's "See It Work" section
shows real output, but as text inside two collapsed `<details>` blocks: nothing moves, and nothing
shows the package being installed and used. Plan 019 phase 7 asked for a demo GIF and, because an
interactive AI session cannot be scripted, wrote a storyboard for Marco to record by hand. It was
never recorded. A demo recorded by hand also goes stale at the first release that changes the
output, and nobody re-records it.

The goal here is a demo a visitor can watch in under a minute, made from a committed script, so it
can be rendered again for every release with one command, and whose AI output is real model output,
said so in the README.

## Current state

- **The storyboard is `examples/demo-script.md`**, committed, not `docs/demo-script.md`. In
  MarcoWork's main checkout, `docs/` holds only `launch/`, `plans/`, `specs/` and a token file
  (listed 2026-10-18); there is no `docs/demo-script.md`. The storyboard records an interactive
  Claude Code session with asciinema, converts it with agg, and runs `npx @marcoamaral/bem-te-vi
  init`, then `/qa-static` and `/qa-cases` in the interactive session.
- **The package is not on npm.** `npm view @marcoamaral/bem-te-vi version` returns 404 on
  2026-10-18. The storyboard's `npx` line cannot be recorded; a demo must install from the tree
  (`npm pack`).
- **README** (`README.md:38-84` at `8487bd6`): "See It Work" has the two `<details>` blocks
  (`/qa-static`, `/qa-automate`). No image, no placeholder (plan 019 phase 7 removed it).
- **`examples/README.md:22-24`** points to `demo-script.md` as "the storyboard for recording the
  README's demo GIF by hand".
- **npm `files`** (`package.json`) is an allow-list: `.claude/*` folders, `bin/`, `adapters/`,
  `README.md`, `CHANGELOG.md` and the two hash/map files. A new top-level `demo/` folder is not
  shipped without any change.

## Decision 1: the recording tool

| | VHS (charmbracelet) | asciinema + agg |
| --- | --- | --- |
| Current release | v0.12.1, 2026-09-24 | asciinema 3.2.1, agg 1.9.0 (Homebrew, 2026-10-18) |
| License | MIT | GPL-3.0 (both) |
| Source file | a `.tape` script: typed commands, waits, hidden setup | a `.cast` capture of what one person typed |
| Re-make for a release | `vhs demo.tape`, unattended | perform it again by hand, then convert |
| Outputs | GIF, MP4 and WebM in one run | GIF (agg); video needs a third tool |
| Linux needs | `ttyd` and `ffmpeg` on `PATH`, plus a Chrome or Chromium (go-rod drives it headless; it uses one on `PATH`, else downloads one) | none beyond the two binaries |

**Choice: VHS.** Its source is a script that can be committed and re-rendered unattended, which is
the property the goal asks for; a `.cast` is a recording, not a recipe. VHS's release ships a Linux
x86_64 tarball with a `checksums.txt`; ttyd 1.7.7 (MIT) ships a static `ttyd.x86_64` with
`SHA256SUMS`. Both install into `~/.local/bin` without sudo.

## Decision 2: what the demo shows

One clip, about 40 seconds, in one terminal, from an empty folder:

1. `bem-te-vi init --editor claude`: the install summary (commands, skills, agents, rules).
2. `cat story.md`: the ServeRest cart story the examples already use ("As a customer, I can't add
   the same product to my cart twice"), cut to three acceptance criteria so the output is checkable
   at a glance. Committed as `demo/story.md`.
3. `claude -p --model haiku "/qa-cases story.md. Save the test cases as TC-CART.md."`: the model's
   real reply, printed by Claude Code's print mode.
4. `grep '^## TC-' TC-CART.md`: the test cases it wrote.
5. `.claude/hooks/validate-tc-format.sh TC-CART.md`: the package's own format hook passes on it.

The optional second clip (`bem-te-vi init` in an empty folder) is folded into step 1: the install
summary is 16 lines and fits on the same screen, so a second file would repeat it.

**Print mode, not the interactive session.** The interactive Claude Code screen has a welcome box
that shows the signed-in account, a spinner, permission prompts and a layout that changes between
versions; print mode (`-p`) prints only the model's final answer. The answer on screen is the real
reply of that run, not edited.

**The model's wait is cut.** The `/qa-cases` run takes about 30 seconds of a blank screen. The tape
shows the command being typed and run, hides the frames while it waits for the prompt to return
(VHS `Hide`/`Wait`/`Show`), and shows the result. The README caption says so.

**Isolation from the recording machine's Claude Code.** In the tape's hidden setup, a shell
function `claude` adds `--setting-sources project --strict-mcp-config --no-session-persistence
--permission-mode acceptEdits --max-budget-usd 0.50` and saves the run's JSON (cost, model, turns)
outside the screen. So the run loads only the project's `.claude/` (the package just installed), no
user settings, no MCP servers, keeps no session on disk, may write `TC-CART.md` without a prompt,
and cannot spend more than US$0.50. The function is in the tape, in plain sight, and `demo/README.md`
explains it. The visible command keeps `--model haiku` so the viewer sees which model answered.

## Decision 3: where it is recorded

**In the SWARE distro.** It is the only one with an authenticated Claude Code until 21 October
(MarcoWork's personal account is out of usage). Recording the whole clip in one pass there, rather
than recording the deterministic parts in MarcoWork and splicing in a transcript, keeps the clip a
single real run: no replay, nothing to disclose beyond the cut wait.

- VHS and ttyd go into SWARE's `~/.local/bin` from their release binaries, checksums verified; no
  sudo. `ffmpeg` 8.0.1 and `google-chrome` are already installed there.
- Nothing is installed into SWARE's Claude Code configuration: the package is installed into the
  throwaway project only, from `npm pack` of the tree, with the CLI in a temporary npm prefix (as plan
  038's load check installed into a temp folder).
- The project folder is `/tmp/demo` and the prompt is a bare `$`; no home path, user name or e-mail is on
  screen. Frames are extracted with ffmpeg and inspected before committing.
- Git, npm and the checks for the pull requests still run in MarcoWork, as the brief requires; only
  the recording runs in SWARE.

**Trial run, 2026-10-18** (outside VHS, same flags, same story): `claude-haiku-4-5`, 3 turns,
28.7 s, **US$0.0753**; it wrote `TC-CART.md` with 4 cases (TC-CART-001 to 004, three mapped to
AC-1..AC-3 and one "Added by QA"), and `validate-tc-format.sh TC-CART.md` printed `[OK] TC-CART.md
matches the TC-CODE-NNN template.` The live run's budget for the whole plan is US$1.00.

## What gets committed

| Path | What |
| --- | --- |
| `demo/bem-te-vi.tape` | the VHS script |
| `demo/record.sh` | packs the tree, installs it into a temp prefix, prepares `/tmp/demo`, runs VHS |
| `demo/story.md` | the three-criteria story |
| `demo/README.md` | how to re-record, what the hidden setup does, the last run's model and cost |
| `demo/bem-te-vi.gif` | shown in the README |
| `demo/bem-te-vi.mp4` | the same clip as video, if small enough (see Step 4) |
| `README.md` | one new section, "See It in Action", right after "What is Bem-te-vi?" |

`demo/` is outside `package.json` `files`, so it is not in the npm package; `npm pack --dry-run`
must list no `demo/` path.

## Git workflow

- PR A (this file and its `plans/README.md` row): branch `docs/plan-049-demo`, into `next`.
- PR B (the implementation): branch `docs/readme-demo-recording`, stacked on PR A, into `next`;
  its description says to merge PR A first.
- Commits in PR B, one concern each: `docs: add a scripted demo recording`, `docs: add the rendered
  demo`, `docs: show the demo in the README`, `docs: point the old storyboard to the scripted
  demo`, `ci: lint the demo recording script`, `docs: record plan 049 outcome`.

## Steps

### Step 1: tools

Install VHS v0.12.1 and ttyd 1.7.7 into SWARE's `~/.local/bin` from their GitHub releases, checking
`checksums.txt` and `SHA256SUMS`. Smoke-test with a two-line tape.

### Step 2: the script

Write `demo/story.md`, `demo/bem-te-vi.tape` and `demo/record.sh`. `record.sh` refuses to run if
`/tmp/demo` (or `$DEMO_WORK`) already exists rather than deleting it, checks that `vhs`, `ttyd`,
`ffmpeg`, `npm`, `node` and `claude` are on `PATH`, packs the tree with `npm pack --ignore-scripts`,
installs the tarball into a temporary prefix, and runs VHS from the repository root. It must pass
`shellcheck`.

### Step 3: record and watch

Run `demo/record.sh` once. Read the run's JSON for model, turns and cost. Run the hook again on
`/tmp/demo/TC-CART.md` outside the recording. Extract frames with ffmpeg (one every few seconds and
the last one) and look at each: text legible, no private data, the hook's `[OK]` line visible at the
end.

### Step 4: sizes

GIF at most about 3 MB and 30-60 seconds. MP4 kept in the repository if it is under about 1 MB;
otherwise keep only the GIF in the repository and say in `demo/README.md` that the MP4 belongs in a
GitHub release asset (a release is the coordinator's and Marco's step, not this plan's). WebM is
rendered by the tape but not committed when the MP4 is.

### Step 5: README

Add one block under its own heading, "See It in Action", directly after "What is Bem-te-vi?", with
the GIF and a one-line caption saying exactly what it shows, that the output is real, which model
produced it and that the model's wait is cut. Change nothing else in the README: plans 048 and 050
edit other parts of it in parallel.

### Step 6: the old storyboard

Do not delete `examples/demo-script.md` (CONTRIBUTING.md section 5). Add a dated note at its top
saying the demo is now scripted in `demo/`, and point `examples/README.md`'s "Recording the demo"
section to `demo/README.md`.

### Step 7: checks and record

Add `demo/record.sh` to the CI shellcheck list. Run `bash ~/qa-ci-all.sh <worktree> linux`
(markdownlint, reference links and the rest) and `npm pack --dry-run`. Record the outcome here.

## Done criteria

- `vhs demo/bem-te-vi.tape` (through `demo/record.sh`) renders the GIF from the committed files
  alone.
- The GIF is at most about 3 MB and 30-60 seconds; its frames were inspected and are legible, with
  no private data.
- The model output in the GIF is one real run; the README names the model and says the wait is cut.
- The hook passes on the file the recorded run wrote.
- `npm pack --dry-run` lists no `demo/` path.
- Local Linux CI green.

## STOP conditions

- The recorded run's `TC-CART.md` fails the hook twice in a row: stop and report. Do not edit the
  output, retry with a larger model, or change the story to make it pass without recording why.
- The live runs together would cost more than US$1.00.
- Any frame shows an e-mail address, a home path, an account name or a token.
- VHS cannot render on Linux without sudo and without a system package that is not already present.

## Rejected approaches

- **asciinema + agg** (the storyboard's tools): the `.cast` is a capture of a person typing, so the
  demo could not be re-made unattended for each release; GPL-3.0 tools, and no video output.
- **Recording the interactive Claude Code session**: shows the signed-in account in the welcome box,
  needs permission prompts answered by hand, and its layout changes between Claude Code versions.
- **Recording in MarcoWork and splicing in a transcript**: possible, but the clip would then be a
  replay of a different run, which the README would have to disclose; SWARE can record the whole
  clip live.
- **`npx @marcoamaral/bem-te-vi init` on screen**: the package is not on npm yet (404). The clip
  shows `bem-te-vi init`, the command the README's Quick Start documents, from `npm pack` of the
  tree.
- **A second clip for `bem-te-vi init` alone**: the first clip already shows it in full.

## Outcome (2026-10-18)

Implemented on `docs/readme-demo-recording`, stacked on this plan's branch `docs/plan-049-demo`
(PR #184), from `github/next` at `a32343c`. Marco asked on 2026-10-18 for all remaining work to be
done; every decision above was taken with evidence in this plan, so no documented default was
needed.

### Drift check

Run on the plan branch right after planning: no change to the listed paths beyond plan 049's own
files.

### What was done, by commit

1. `docs: add a scripted demo recording`: `demo/bem-te-vi.tape`, `demo/record.sh`, `demo/shell.sh`,
   `demo/story.md`; `.gitignore` ignores the WebM the tape also renders.
2. `docs: add the rendered demo with its record of the run`: `demo/bem-te-vi.gif`,
   `demo/bem-te-vi.mp4`, the run's `demo/TC-CART.md` as written, `demo/README.md`; the output file
   is in `.markdownlintignore` (its tables fail MD060, and it is committed unedited, like the
   release fixtures).
3. `docs: show the demo in the README`: one "See It in Action" section after "What is Bem-te-vi?";
   nothing else in the README changed.
4. `docs: point the old storyboard to the scripted demo`: a dated "Superseded" note at the top of
   `examples/demo-script.md` (kept, not deleted) and the "Recording the demo" paragraph of
   `examples/README.md`.
5. `ci: lint the demo recording scripts`: `demo/record.sh` and `demo/shell.sh` added to the CI
   shellcheck list.
6. `docs: record plan 049 outcome`: this section and the `plans/README.md` row.

> **Correction, 2026-10-18.** Decision 2 says the `claude` wrapper is defined "in the tape's hidden
> setup". It lives in `demo/shell.sh`, which the hidden setup sources: a function typed into the
> tape would need VHS string escaping for every quote, and a sourced file can be shellchecked. The
> tape names the file, so the wrapper is still in plain sight.

### The recording

- Tools: VHS v0.12.1 and ttyd 1.7.7 installed into SWARE's `~/.local/bin` from their GitHub
  releases, `vhs_0.12.1_Linux_x86_64.tar.gz: OK` and `ttyd.x86_64: OK` against the published
  checksums; system `ffmpeg` 8.0.1 and `google-chrome` used as found. No sudo, no system package.
- A dry run with a stub `claude` (it replayed the trial run's file and JSON) checked the tape's
  layout and its `Wait` pattern at no cost; that render was overwritten.
- The live recording: `claude-haiku-4-5-20251001` only, 3 turns, 37.5 s, US$0.0717. With the
  planning trial (US$0.0753) the plan spent US$0.147 of its US$1.00 budget. The run wrote six
  cases, TC-CART-001 to TC-CART-006 (AC-1, AC-2, AC-3 and three "Added by QA" with reasons), and
  `record.sh` ran the hook again outside the recording: `[OK] /tmp/demo/TC-CART.md matches the
  TC-CODE-NNN template.`
- Sizes: GIF 508,401 bytes, 44.2 s, 1200 x 760, 24 fps; MP4 777,210 bytes (under the 1 MB line, so
  committed beside the GIF; no release asset needed); WebM 944,074 bytes, not committed.
- Watched: frames extracted every 4 s from the GIF, every second around the cut (17-24 s) and the
  last frame. Text legible at full size; the prompt is a bare `$`, the folder never appears, no
  e-mail, home path, account name or token on any frame. The cut shows the command, then a blank
  line, then the reply.
- Limits of the recorded output are listed in `demo/README.md` ("Honest limits of the recorded
  run"): the model's summary miscounts its own scores, TC-CART-005 expects "400 or 201", and no case
  was run against ServeRest.
- Nothing was written to SWARE's Claude Code configuration: `--no-session-persistence` left no
  session, and `~/.claude.json` has no `/tmp/demo` entry after the runs.
- On npmjs.com the README's relative GIF path resolves only through the `repository` URL
  (`MarcoAmaral/bem-te-vi`), that is, after plan 020 part B's public repository exists; `demo/` is
  not in the npm package.

### Verification

Recorded in the pull request: local Linux CI, `shellcheck demo/record.sh demo/shell.sh`, and
`npm pack --dry-run` listing no `demo/` path.

### Done criteria

- Renders from the committed files through `demo/record.sh`: yes (the recording above).
- GIF at most about 3 MB and 30-60 s, frames inspected: yes (0.5 MB, 44 s).
- Model output is one real run; the README names the model and says the wait is cut: yes.
- The hook passes on the file the recorded run wrote: yes.
- `npm pack --dry-run` lists no `demo/` path, local Linux CI green: see the pull request.

## Re-recorded with Claude Sonnet (2026-10-20)

Marco decided on 2026-10-20 that the demo for 4.1.0 shows Claude Sonnet instead of Claude Haiku.
The tape's visible command now reads `--model sonnet`; nothing else in the tape, `shell.sh` or the
story changed (`record.sh` changed in one comment line, which named "a cheap model").

- Recorded in the SWARE distro, as before, with the VHS v0.12.1 and ttyd 1.7.7 already in
  `~/.local/bin`, from a fresh clone of `next` at `15bd4c2` through `demo/record.sh`. Claude Code
  2.1.291.
- The live run: `claude-sonnet-5-5` only, 8 turns, 42.1 s, **US$0.2530** (under the US$0.50 cap in
  `shell.sh`). It wrote nine cases, TC-CART-001 to TC-CART-009 (three from AC-1 to AC-3, six "Added
  by QA"), and `record.sh` ran the hook again outside the recording: `[OK] /tmp/demo/TC-CART.md
  matches the TC-CODE-NNN template.` One run, first try.
- Sizes: GIF 1,776,318 bytes, 38.9 s, 1200 x 760 (within the 3 MB and 30-60 s of Step 4); MP4
  983,059 bytes, under the 1 MB line, so it stays committed beside the GIF; WebM 1,279,422 bytes,
  not committed.
- Watched: frames every 4 s and the last frame. Text legible; the prompt is a bare `$`; no e-mail,
  home path, account name or token. The reply names `/tmp/demo/TC-CART.md`, the throwaway project
  folder, which the earlier recording never showed; recorded in `demo/README.md`'s limits.
- The reply is longer than Haiku's and fills the screen: its first lines are on screen for the 9 s
  after the cut, then scroll off as `grep` and the hook print.
- Updated: `demo/bem-te-vi.gif`, `demo/bem-te-vi.mp4`, `demo/TC-CART.md` (the run's file, unedited),
  `demo/README.md` ("The last recording" and its limits) and the README's caption and image text.
- Nothing written to SWARE's Claude Code configuration: `claude plugin list` and
  `~/.claude/settings.json` unchanged (see plan 037, 2026-10-20), and `~/.claude.json` has no
  `/tmp/demo` entry.
