# Plan 047: Split the non-Claude adapters into each editor's own rules and skills, and install them where the editors look today

> **Executor instructions**: This plan is the plan only. Implementation starts after the three
> installer pull requests in flight on 2026-10-18 have merged into `next` (plan 044 `install.ps1`,
> plan 045 `install.sh`, plan 046 the CLI) and after plan 043 (#176, #181). Work on one branch from
> `next`, in this order: the conformance cases red first (quote the failures), then the editor map
> and the three installers (identical behaviour), then the two generators (byte-identical output),
> then `tests/verify-adapters.*`, then the existing cases and lifecycle suites that name the old
> paths, then the migration lifecycle test, then the shipped wording, then the README, then the
> outcome here. One concern per commit. Run every command in "Commands" and read its output. If
> anything in "STOP conditions" occurs, stop and report. When done, update this plan's row in
> `plans/README.md`.
>
> **Drift check (run first)**: `git diff --stat 8487bd6..HEAD -- generate-adapters.sh generate-adapters.ps1 install.sh install.ps1 bin .qa-skills-editor-map tests/verify-adapters.sh tests/verify-adapters.ps1 tests/conformance tests/test-lifecycle.sh tests/test-lifecycle.ps1 README.md .claude/commands/qa.md .claude/skills/qa-reference/SKILL.md .claude/rules`
> Three agents were rewriting `install.sh`, `install.ps1` and `bin/cli.js` while this plan was
> written, and plan 043 changes all five touch points this plan changes again. Every line reference
> below is to `8487bd6` and is likely stale: re-read each function before relying on it.
>
> **Note, 2026-10-19.** Plan 051 moved the CLI from `bin/cli.js` to `cli/bem-te-vi.js`. In the
> drift check above, read `bin` as `bin cli`, and read `bin/cli.js` anywhere in this plan as
> `cli/bem-te-vi.js`.
>
> **Re-read the sources (run second)**: every quote in "What each editor documents" is dated
> 2026-10-18. Open each source again. If one of the facts in "STOP conditions" has changed, stop.

## Status

- **Priority**: P1 (every non-Claude install is still far over its editor's documented size after
  plan 043, and four install locations are ones the editors no longer document)
- **Effort**: L
- **Risk**: HIGH (changes the editor map, every non-Claude install path and the update and
  uninstall of every non-Claude editor in all three installers; the file-safety layer is reused,
  not changed)
- **Depends on**: plan 043 (references out of the merged adapters, `.bem-te-vi/<editor>/`), plans
  044, 045 and 046 (the installer rewrites), plan 033 (parity, linked folders), plan 021 (the
  rules budget), plan 034 (pointer convention)
- **Category**: fix (adapter size, stale locations) and feature (native rules and skills per editor)
- **Planned at**: commit `8487bd6` (`github/next`), 2026-10-18
- **Source**: plan 043 "What else could leave the merged file" and "Findings outside scope", its
  backlog entry "Split the non-Claude adapters per editor"; Marco's request of 2026-10-18 to plan
  the split and fix the four stale locations
- **Defaults**: every decision below has a default written beside it (Marco asked for all remaining
  work on 2026-10-18); "Decisions for Marco" lists them

## Why this matters

Plan 043 cut each merged adapter from 347,036 bytes to about 235,840 bytes by moving the 15
reference files out. Its outcome table (measured at `c4d43a3`) leaves every adapter over its
editor's figure:

| Adapter after plan 043 | Characters | Lines | Documented figure | Over by |
| --- | --- | --- | --- | --- |
| `windsurf/qa.md` (project `.windsurfrules`) | 232,484 | 3,700 | 12,000 characters per workspace rule file | about 19 times |
| `cursor/qa.mdc` | 232,623 | 3,705 | "Keep rules under 500 lines" | about 7 times |
| `copilot/copilot-instructions.md` | 232,483 | 3,700 | "about 1,000 lines" | about 4 times |
| `cline/.clinerules` | 232,481 | 3,700 | none stated | n/a |
| `antigravity/qa/SKILL.md` | 232,617 | 3,704 | 24,000 bytes per rule file; skill body "under 500 lines" (Agent Skills) | about 7 times the 500 lines |

What is left in the merged file is every command, skill body, rule and agent. No further cut of
one file fixes this: a merged file holds the whole package by design. The fix is to stop merging
and install the package the way each editor now loads instructions: a few small rule files that
are always on, and everything else as on-demand units the editor loads by description or by name.

Since plan 021 asked the question, all five editors have adopted the same on-demand unit: the
Agent Skills folder (`<name>/SKILL.md` with `name` and `description` frontmatter, plus optional
`references/`). Only the name and description are in context until the skill is used. The package
already ships its skills in that format for Claude Code. This plan uses it for every editor.

## What each editor documents (read 2026-10-18)

Quotes are verbatim from the page named, read on 2026-10-18 with WebFetch. Where a page did not say
something, the table says so; nothing is filled in from memory.

### Cursor (<https://cursor.com/docs/context/rules>, <https://cursor.com/docs/context/skills>)

| Topic | What the documentation says |
| --- | --- |
| Project rules | "Stored in `.cursor/rules`, version-controlled and scoped to your codebase." "Project rules must use the `.mdc` extension." "A plain `.md` file in `.cursor/rules` is ignored by the rules system". |
| Global rules | "User Rules are global preferences defined in **Customize → Rules** that apply across all projects." No file path is given. |
| Format | "Each rule is a markdown file with frontmatter metadata and content." The type dropdown "changes properties `description`, `globs`, `alwaysApply`". "If alwaysApply is true, the rule will be applied to every chat session." |
| Rule types | Always Apply ("Apply to every chat session"); Apply Intelligently ("When Agent decides it's relevant based on description"); Apply to Specific Files ("When file matches a specified pattern"); Apply Manually ("When @-mentioned in chat"). |
| Size | "Keep rules under 500 lines"; "Split large rules into multiple, composable rules". |
| `AGENTS.md` | "Cursor supports AGENTS.md in the project root and subdirectories." "Instructions from nested `AGENTS.md` files are combined with parent directories". |
| Skills | Project: `.agents/skills/` and `.cursor/skills/`. User: `~/.agents/skills/` and `~/.cursor/skills/`, "User-level (global) on the local machine." "For compatibility, Cursor also loads skills from Claude and Codex directories" (`.claude/skills/`, `~/.claude/skills/`, and the Codex ones). Frontmatter `name` ("Must match the parent folder name"), `description` ("Used by the agent to determine relevance"), optional `paths`, `disable-model-invocation`, `metadata`. "Skills can also be manually invoked by typing `/` in Agent chat". `references/`: "Additional documentation loaded on demand". No size limit stated. |
| Commands | The skills page: `/migrate-to-skills` "identifies eligible rules and commands and converts them to skills automatically", covering "Both user-level and workspace-level commands". |

### Windsurf, now documented as Devin Desktop (<https://docs.devin.ai/desktop/cascade/memories>, `/workflows`, `/skills`)

`docs.windsurf.com/windsurf/cascade/memories` answers "307 Temporary Redirect" to
`docs.devin.ai/desktop/cascade/memories`. The pages say "Devin Desktop" throughout and keep
"Windsurf" in legacy paths.

| Topic | What the documentation says |
| --- | --- |
| Workspace rules | "`.devin/rules/*.md` (preferred) or `.windsurf/rules/*.md` (fallback)". "The legacy single-file `.windsurfrules` at the workspace root is also still read." Read from the workspace, sub-directories and "parent directories up to the git root". |
| Global rules | "`~/.codeium/windsurf/memories/global_rules.md`": "Single file, applied across all workspaces. Always on. Limited to 6,000 characters." No global rules folder is listed. |
| Size | "Limited to 12,000 characters per file." What happens above it is not stated. |
| Activation | `trigger` frontmatter: `always_on` ("Full rule content is included in the system prompt on every message"), `model_decision` ("Only the `description` is shown in the system prompt"), `glob` (with `globs`), `manual` ("typing `@rule-name`"). |
| `AGENTS.md` | "Any directory in your workspace": "Processed by the same Rules engine — root-level = always-on, subdirectory = auto-glob for that directory." |
| Workflows | `.devin/workflows/` "(or the legacy `.windsurf/workflows/`)"; global `~/.codeium/windsurf/global_workflows/*.md`. "Workflow files are limited to 12000 characters each." "Cascade will never invoke a workflow automatically." |
| Skills | Workspace `.devin/skills/<skill-name>/` ("the legacy `.windsurf/skills/<skill-name>/` is still read"); global `~/.codeium/windsurf/skills/` or `~/.config/devin/skills/`; also discovers `.agents/skills/` and `~/.agents/skills/`, and `.claude/skills/` when Claude Code config reading is enabled. Only `name` and `description` are shown; the body loads "only when Cascade decides to invoke the skill", or on `@skill-name`. No size limit stated. |

### GitHub Copilot (docs.github.com and code.visualstudio.com)

| Topic | What the documentation says | Source |
| --- | --- | --- |
| Repository-wide | `.github/copilot-instructions.md`, for "all requests made in the context of a repository". | [add-repository-instructions](https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions) |
| Path-specific | "`NAME.instructions.md` files within or below the `.github/instructions` directory" with `applyTo`; on GitHub.com "path-specific custom instructions are only supported for Copilot cloud agent and Copilot code review." In VS Code, `description` enables "on-demand discovery": "The agent can also load an instructions file on demand when its `description` matches the current task." User instructions in "harness folders, such as `~/.copilot/instructions`". | same; [VS Code custom instructions](https://code.visualstudio.com/docs/copilot/customization/custom-instructions) |
| `AGENTS.md` | "one or more `AGENTS.md` files, stored anywhere within the repository"; "the nearest `AGENTS.md` file in the directory tree will take precedence." | add-repository-instructions |
| Size | No cap on the instructions page. "Limit any single instruction file to a maximum of about 1,000 lines. Beyond this, the quality of responses may deteriorate." | [customize-code-review](https://docs.github.com/en/copilot/tutorials/customize-code-review) |
| Prompt files | `.github/prompts/*.prompt.md`, invoked manually ("you invoke prompt files manually in chat"); "supported only in Local harness sessions"; "For reusable workflows in sessions that use another harness, create an agent skill." | [VS Code prompt files](https://code.visualstudio.com/docs/copilot/customization/prompt-files) |
| Skills | Project `.github/skills`, `.claude/skills` or `.agents/skills`; personal `~/.copilot/skills` or `~/.agents/skills` (VS Code also `~/.claude/skills/`). They "work with Copilot cloud agent, Copilot code review, the GitHub Copilot CLI", VS Code and JetBrains agent mode. `name` "Maximum 64 characters", `description` "Maximum 1024 characters"; three loading stages (name and description, then body, then resources); "Skills are available as slash commands in chat"; "Agent Skills is an open standard". | [about-agent-skills](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills), [VS Code agent skills](https://code.visualstudio.com/docs/copilot/customization/agent-skills) |

### Cline (<https://docs.cline.bot/customization/cline-rules.md>, `skills.md`, `cline-cli/configuration.md`)

| Topic | What the documentation says |
| --- | --- |
| Workspace rules | "Workspace rules go in `.clinerules/` or `.cline/rules/` at your project root. Both layouts are supported by VS Code, Desktop, and the CLI." "Both directories are searched when present". A single `.clinerules` file is not mentioned. |
| Global rules | "your system's Cline Rules directory" (`~/Documents/Cline/Rules`); "Cline also searches `~/.cline/rules` and `~/Cline/Rules`"; also `~/.agents/AGENTS.md`. |
| Format | "Rules without frontmatter are always active." "Currently, `paths` is the supported conditional." Invalid YAML "fails open". |
| Size | No number. "Rules consume context tokens. Avoid lengthy explanations or pasting entire style guides." |
| Other files | `.cursorrules` and `.windsurfrules` "Automatically detected"; `AGENTS.md` "for cross-tool compatibility". |
| Workflows | The CLI configuration page lists `workflows/` under `.cline/` and `~/.cline/`, and "the older `.clinerules/` layout (rules, plus its `workflows/`, `skills/` and `hooks/` folders)". The former workflows page (`/features/slash-commands/workflows`) answers 404 and no workflows page is in `llms.txt`. |
| Skills | Project `.cline/skills/` "(recommended)", `.clinerules/skills/`, `.claude/skills/` (and `.agents/skills/` per the CLI page); global `~/.cline/skills/`. Metadata "Always (at startup)", about "~100 tokens per skill"; the body loads "When skill is triggered". "Keep SKILL.md under 5k tokens." Description "max 1024 characters". Skills are slash commands ("Using Commands": "Select a skill command (for example, `/aws-deploy`)"). |

**Read in Cline's source, not its documentation** (`cline/cline` `main` at `a42df8c8d5`,
2026-10-17): `apps/vscode/src/core/context/instructions/user-instructions/rule-helpers.ts` still
reads a single `.clinerules` file ("FILE CASE"), and the SDK loader calls it "a legacy single-file
ruleset". The same file's `ensureLocalClineDirExists` converts that file into a folder the first time
a workspace rule is created from the Rules panel or `/newrule`: "logic to convert .clinerules file
into directory, and rename the rules file to {defaultRuleFilename}", which is `default-rules.md`.

### Antigravity (<https://antigravity.google/docs/rules>, `/docs/skills`, `/docs/ide/workflows`)

| Topic | What the documentation says |
| --- | --- |
| Rules | "`<dir>/.agents/rules/*.md` _(and legacy `<dir>/.agent/rules/*.md`)_". Global: "**Standalone global files** (no frontmatter needed, always active): `~/.gemini/AGENTS.md`, `~/.gemini/GEMINI.md`". |
| Activation | `trigger` values `manual`, `always_on`, `model_decision` ("best for detailed domain guides"), `glob`. |
| Size | "Antigravity truncates any single rule file that exceeds 24,000 bytes". "All active global and `always_on` rules share a 20,000-token budget". |
| `AGENTS.md` | "`AGENTS.md` and `GEMINI.md` do not use frontmatter." |
| Workflows | "Workflow files are limited to 12,000 characters each." "Current workflows will stop working on **October 19, 2026**", with `/migrate-workflows` to "migrate existing workflows to **Agent skills**". |
| Skills | Workspace `<workspace-root>/.agents/skills/<skill-folder>/` ("still maintains backward compatibility for `.agent/skills`"). Global (App and IDE) `~/.gemini/config/skills/<skill-folder>/`; for the IDE, legacy `~/.gemini/antigravity/skills/` "is also supported"; CLI `~/.gemini/antigravity-cli/skills/`. `description` required, `name` optional. "Skills follow a **progressive disclosure** pattern" (discovery, activation, execution). No size limit stated. Slash invocation of skills is not documented. |

### `AGENTS.md` and the Agent Skills format

| Source | What it says |
| --- | --- |
| <https://agents.md/> | "AGENTS.md is just standard Markdown." "The closest AGENTS.md to the edited file wins; explicit user chat prompts override everything." No size limit stated. Lists Cursor, Windsurf, VS Code, GitHub Copilot's coding agent and Codex among supporters. |
| Codex (<https://learn.chatgpt.com/docs/agent-configuration/agents-md>, redirected from developers.openai.com) | "Codex concatenates files from the root down"; it "stops adding files once the combined size reaches the limit defined by `project_doc_max_bytes`", "32 KiB by default". |
| Claude Code (<https://code.claude.com/docs/en/memory>) | For `CLAUDE.md`: "target under 200 lines per CLAUDE.md file." "Rules without `paths` frontmatter are loaded at launch with the same priority as `.claude/CLAUDE.md`." |
| Agent Skills spec (<https://agentskills.io/specification>) | `name`: "Max 64 characters. Lowercase letters, numbers, and hyphens only", "Must match the parent directory name". `description`: "Max 1024 characters." `metadata`: "a map from string keys to string values". Metadata "~100 tokens" at startup; instructions "< 5000 tokens recommended"; "Keep your main `SKILL.md` under 500 lines." File references are "relative paths from the skill root", "one level deep". |

### Where each editor supports Agent Skills

| Editor | Project skills | Global skills | Explicit invocation | Reads other tools' folders |
| --- | --- | --- | --- | --- |
| Cursor | `.cursor/skills/`, `.agents/skills/` | `~/.cursor/skills/`, `~/.agents/skills/` | `/name` | `.claude/skills/`, Codex |
| Windsurf (Devin Desktop) | `.devin/skills/`, legacy `.windsurf/skills/` | `~/.codeium/windsurf/skills/`, `~/.config/devin/skills/` | `@name` | `.agents/skills/`; `.claude/skills/` if enabled |
| GitHub Copilot | `.github/skills/` | `~/.copilot/skills/` | `/name` | `.claude/skills/`, `.agents/skills/` |
| Cline | `.cline/skills/`, `.clinerules/skills/` | `~/.cline/skills/` | `/name` | `.claude/skills/`, `.agents/skills/` |
| Antigravity | `.agents/skills/` | `~/.gemini/config/skills/` (IDE also legacy `~/.gemini/antigravity/skills/`) | not documented | none documented |

## Current state

At `8487bd6` the editor map (`.qa-skills-editor-map`) has one row per editor: key, adapter, project
path, global path, label. Each non-Claude install writes one merged adapter at that path (plus, after
plan 043, the 15 references under `.bem-te-vi/<editor>/`):

| Editor | Project path | Global path | How the editor treats it |
| --- | --- | --- | --- |
| Cursor | `.cursor/rules/qa.mdc` | `~/.cursor/rules/qa.mdc` | `alwaysApply: false` with a description: Apply Intelligently, so the whole file enters context at once when applied |
| Windsurf | `.windsurfrules` | `~/.windsurf/rules/qa.md` | legacy single file, always on |
| Copilot | `.github/copilot-instructions.md` | none | always on |
| Cline | `.clinerules` (a file) | none | always on |
| Antigravity | `.agents/skills/qa/SKILL.md` | `~/.gemini/antigravity/skills/qa/SKILL.md` | one skill named `qa` |

`generate-adapters.sh` builds one merged source from `commands/qa.md`, `commands/qa-*.md`, the
rules, each skill (with its references until plan 043) and the agents, then writes it with a
different header per editor. `tests/verify-adapters.sh` and `.ps1` check that these seven files
exist and carry the markers.

Measured on the sources at `8487bd6` (`wc -c`, `wc -m`, `wc -l` over the files):

| Source | Files | Bytes | Characters | Lines |
| --- | --- | --- | --- | --- |
| `.claude/rules/*.md` | 9 | 21,855 | 21,770 | 382 |
| `.claude/commands/*.md` | 11 | 118,171 | 115,236 | 2,049 |
| `.claude/skills/*/SKILL.md` | 8 | 85,933 | 85,733 | 1,006 |
| `.claude/skills/qa-reference/references/*.md` | 15 | 111,360 | 110,897 | 2,069 |
| `.claude/agents/*.md` | 4 | 20,598 | 20,449 | 300 |

The largest rule is `testing-guidelines.md` (7,896 bytes, 7,877 characters, 125 lines). The largest
on-demand files are `qa-plan/SKILL.md` (25,916 bytes, 320 lines) and `commands/qa-cases.md`
(21,467 bytes, 399 lines). Every command, skill and agent description is at most 996 characters, under
the 1,024 the Agent Skills format allows.

## Design: what becomes what

**Rules are the only always-on content, one rule file per source rule, plus one small index rule.**
Claude Code loads every rule at launch (none has `paths:`), so the other editors get the same set
always on, nothing more. Each rule is far under every per-file limit by itself; only their sum
(21,770 characters) was ever too big for Windsurf. The index rule (`bem-te-vi`) is new and generated:
it says the package is installed, lists the skill names, how this editor invokes a skill, and how a
pointer resolves (a command `/qa-cases` is the skill `qa-cases`; an agent `qa-groomer` is the skill
`qa-groomer`; `qa-reference/references/<file>.md` is that file under this editor's skills folder;
"the `<rule>` rule" is the file `bem-te-vi-<rule>`).

**Everything else is an Agent Skill, one folder per source unit, the same bytes for every editor:**

| Package part | Becomes | Skill folder | Loaded |
| --- | --- | --- | --- |
| 11 commands | one skill each; `name` and `metadata.id` = the command's `id`, `description` = the command's description, body = the command without frontmatter | `qa`, `qa-agentic`, ..., `qa-trace` | by description, or by name (`/qa-cases`, `@qa-cases`) |
| 8 skills | unchanged (already in the format), `qa-reference` with its 15 `references/` | `qa-a11y`, ..., `qa-release` | by description; references when a pointer names them |
| 4 agents | one skill each, built like a command; `model` and `tools` are Claude Code fields and are dropped | `qa-groomer`, `qa-designer`, `qa-writer`, `qa-engineer` | when `/qa-agentic` or `/qa-review` names the stage |
| 9 rules | also a generated skill `qa-rules` whose `references/` holds the 9 rules, so a global install (which has no rule location, see below) still reaches them | `qa-rules` | by description, in a global install |

No name collides: commands, skills and agents have distinct ids, and `qa-rules` is new. The
Antigravity skill `qa` keeps its path (`.agents/skills/qa/SKILL.md`) and becomes the `/qa` router.

**Per editor and target:**

| Editor | Project: always-on rules | Project: skills | Global: rules | Global: skills |
| --- | --- | --- | --- | --- |
| Cursor | `.cursor/rules/bem-te-vi*.mdc`, `alwaysApply: true` | `.cursor/skills/` | none (user rules live in settings, not files) | `~/.cursor/skills/` |
| Windsurf | `.windsurf/rules/bem-te-vi*.md`, `trigger: always_on` (default D1) | `.windsurf/skills/` | none (the only global rule is the user's single `global_rules.md`) | `~/.codeium/windsurf/skills/` |
| Copilot | `.github/copilot-instructions.md`: the index and the 9 rules in one file (default D3) | `.github/skills/` | not installed, as today (D4) | not installed, as today (D4) |
| Cline | `.cline/rules/bem-te-vi*.md`, no frontmatter (always active) (default D2) | `.cline/skills/` | not installed, as today (D4) | not installed, as today (D4) |
| Antigravity | `.agents/rules/bem-te-vi*.md`, `trigger: always_on` | `.agents/skills/` | none (the only global rules are the user's `~/.gemini/GEMINI.md` and `AGENTS.md`) | `~/.gemini/config/skills/` |
| Universal (copied by hand) | `AGENTS.md` and `CLAUDE.md`: the index and the 9 rules in one file | the package's `adapters/skills/`, which the header says to copy to the folder the agent reads skills from | n/a | n/a |

Why not workflows, commands or prompt files for the commands: Windsurf workflows are limited to
12,000 characters and "Cascade will never invoke a workflow automatically"; Antigravity's
"Current workflows will stop working on October 19, 2026"; Copilot prompt files are "supported only
in Local harness sessions"; Cursor's own `/migrate-to-skills` turns commands into skills; Cline's
workflows page is gone from its documentation. Skills are the one unit all five load both by
description and by name.

Why a skill folder per editor, not one shared `.agents/skills/` (which Cursor, Windsurf, Copilot,
Cline and Antigravity all read): the manifest records `<hash>  <editor>  <path>`, and uninstalling
one editor removes every file recorded for it. A shared folder would let `uninstall cursor` delete
what Antigravity still uses, and break conformance case 010. The cost is that an editor that also
reads another tool's folder (Cursor reads `.agents/skills/` and `.claude/skills/`) can list a
same-named skill twice when two editors are installed in one project (default D7).

### Size budget, measured

A prototype of this split was generated from the sources at `8487bd6` with a throwaway script (in
the planner's scratch folder, not committed) and measured with `wc`. The index text is a draft; the
generators fix the final wording, which may move these figures by a few hundred characters.

**Always-on, per editor** (every file the editor loads in every conversation):

| Editor | Files | Largest file | Total | Limit | Largest file against the limit | Budget the check enforces (85 percent) |
| --- | --- | --- | --- | --- | --- | --- |
| Windsurf | 10 | 7,873 characters | 22,833 characters, 400 lines | 12,000 characters per file | 66 percent | 10,200 characters per file |
| Cursor | 10 | 126 lines | 23,319 characters, 410 lines | "under 500 lines" per rule | 25 percent | 425 lines per file |
| Copilot | 1 | 388 lines (22,987 bytes) | same | "about 1,000 lines" per file | 39 percent | 850 lines |
| Antigravity | 10 | 7,892 bytes | 22,839 characters (about 5,700 tokens at 4 characters a token) | 24,000 bytes per file; 20,000 tokens for all always-on and global rules | 33 percent per file; about 29 percent of the token budget | 20,400 bytes per file; 68,000 characters in total |
| Cline | 10 | 7,865 bytes | 22,552 characters, 370 lines | none stated | n/a | the rules cap of `tests/test-rules-size.sh` (25,000 bytes of source rules) |
| Universal `AGENTS.md` | 1 | 22,966 bytes, 388 lines | same | Codex 32 KiB (32,768 bytes) for all `AGENTS.md` files combined | 70 percent | 27,852 bytes |

Against plan 043's figures this is the always-on load going from 232,000 characters (Windsurf,
Copilot, Cline) to about 23,000, and from one 3,705-line Cursor rule applied whole to ten rules of at
most 126 lines. The source rules can still grow to their 25,000-byte cap (plan 021) and stay inside
every budget above: at the cap the universal file is about 26,400 bytes, under 27,852.

`universal/CLAUDE.md` is 388 lines against Claude Code's "target under 200 lines". The native
Claude Code install loads the same 382 lines of rules at launch ("with the same priority as
`.claude/CLAUDE.md`"), so the hand-copied file costs what the native install costs; plan 021's cap
governs both, and this plan does not change it.

**On demand, the shared skills tree** (identical for every editor): 24 skill folders, 48 files,
358,046 bytes. In context before any skill is used: the 24 names and descriptions, 7,832 characters
(about 2,000 tokens). Every `SKILL.md` is under the format's 500 lines (largest `qa-cases`, 400).
Two are over its "< 5000 tokens recommended" for a body (also Cline's "Keep SKILL.md under 5k
tokens"): `qa-plan` (25,795 characters, about 6,400 tokens) and `qa-cases` (21,300, about 5,300).
That is a recommendation, not a limit, and the body loads only when the skill is used; splitting
those two is content work, recorded in the backlog, not done here.

**Disk per install**: about 23 KB of rules plus 358 KB of skills, against 236 KB plus 111 KB after
plan 043. The package (`adapters/`) holds one skills tree, not one per editor.

## The four stale install locations

| Old location (editor map at `8487bd6`) | What is documented today | Does the old one still work | New location (this plan) |
| --- | --- | --- | --- |
| Cursor global `~/.cursor/rules/qa.mdc` | User rules are "defined in **Customize → Rules**", no file path. User-level skills: `~/.cursor/skills/` and `~/.agents/skills/`. | Not documented. Cursor forum threads (not official, versions vary) report that `~/.cursor/rules` is found only when the opened project is inside the home folder, by the same upward search as a project's `.cursor/rules`, and that such rules do not show in the rules list. Not observed here: no Cursor in this environment. | `~/.cursor/skills/<skill>/` (24 skills); no global rule file |
| Windsurf global `~/.windsurf/rules/qa.md` | Global rules: the single file `~/.codeium/windsurf/memories/global_rules.md`, "Limited to 6,000 characters". Global skills: `~/.codeium/windsurf/skills/` or `~/.config/devin/skills/`. | Not documented as global. `.windsurf/rules` is read in the workspace and "parent directories up to the git root", so it applies only to a workspace that is the home folder or sits under it with no git root in between (inferred from that sentence, not confirmed). | `~/.codeium/windsurf/skills/<skill>/`; `global_rules.md` is never written (see "Rejected approaches") |
| Cline project `.clinerules` (a single file) | Only the folders `.clinerules/` and `.cline/rules/`. | Yes, per Cline's source at `a42df8c8d5` ("legacy single-file ruleset"), until the user creates a workspace rule from the Rules panel or `/newrule`: Cline then turns the file into the folder `.clinerules/` with our content in `.clinerules/default-rules.md`, a path our manifest never recorded. | `.cline/rules/bem-te-vi*.md` and `.cline/skills/`; `.cline/` never collides with the old file or with a user's own `.clinerules/` folder |
| Antigravity global `~/.gemini/antigravity/skills/qa/SKILL.md` | `~/.gemini/config/skills/<skill-folder>/` for the App and the IDE. | In the IDE only: the legacy `~/.gemini/antigravity/skills/` "is also supported". The App is documented with the new path only. | `~/.gemini/config/skills/<skill>/` |

Two project paths stop being written for the same reason (they are the merged file): Cursor's
`.cursor/rules/qa.mdc` and Windsurf's `.windsurfrules` (documented as legacy). Plan 043's
`.bem-te-vi/<editor>/` references move into the `qa-reference` skill folder, where the shipped
wording already says they are ("the `references/` folder of this skill, wherever the skill is
installed"). `.github/copilot-instructions.md` and `.agents/skills/qa/SKILL.md` keep their paths.

### Migration, the same in all three installers

The rule is the one conformance cases 016, 017 and 023 already pin for Claude Code: on `update`, a
file recorded under an editor that the package no longer ships for that editor and target is
removed when it is still exactly as installed and its entry dropped ("no longer shipped"); when it
was changed (or is read-only) it is kept, reported, and its entry dropped. `uninstall` removes every
recorded file of the editor that is still as installed, wherever it is, and keeps and reports the
rest. Under CLAUDE.md section 5 nothing else changes: backups, adoption by known hash, the symlink
rules (never write or delete through a linked folder below the editor's top-level folder), the
read-only rule and the exclusive temporary manifest write all come from the existing functions.

What this plan adds to that rule:

1. **What "shipped" means for a non-Claude editor.** The package-file list for an editor and target
   is exactly the generated rule files at the rules location (when the target has one) and every
   file of `adapters/skills/` at the skills location. Every other recorded path of that editor is
   no longer shipped. This replaces plan 043's mapping of `.bem-te-vi/<editor>/` entries back to
   `.claude/skills/` and the older mapping of every non-Claude entry back to the one adapter, and is
   what makes the four old locations, `.cursor/rules/qa.mdc`, `.windsurfrules` and
   `.bem-te-vi/<editor>/` go away on update.
2. **Emptied folders.** After removing a file, remove its folders while they are empty, up to and
   never including the base (project root or home), never through a linked folder: `~/.windsurf/`
   and `.bem-te-vi/` go when empty; `~/.cursor/`, `~/.gemini/antigravity/` and `.github/` are never
   empty in practice (the editor's own data, or the new files) and stay.

   > **Note, 2026-10-20, plan 061 L1.** Claude Code's uninstall kept its own rule until plan 061:
   > every empty folder under `.claude/skills/`, the five package folders and `.claude`, even when
   > it removed nothing. It now follows this rule too (case 080).
3. **A recorded path that is now a folder is never touched.** If `.clinerules` is a folder (Cline
   converted it), update and uninstall do not remove or enter it; they treat the entry as a changed
   file the package stopped shipping (kept, reported, entry dropped) and say that Cline moved the
   old rules to `.clinerules/default-rules.md`, which the user can delete. It is never deleted for
   them: it is not a path the package recorded (CLAUDE.md section 5: never guess by any other
   means).
4. **A changed file at an old location is reported with what it means**: `~/.gemini/antigravity/
   skills/qa/SKILL.md` kept means the IDE lists two `qa` skills; `.windsurfrules` kept means
   Windsurf still loads it in every conversation.

No installer writes `global_rules.md`, `~/.gemini/GEMINI.md`, `~/.gemini/AGENTS.md` or a project
`AGENTS.md`: each is a single file the user owns, and the first is smaller (6,000 characters) than
the rules.

## Decisions for Marco

Each has a default, used if no answer comes (Marco asked for all remaining work on 2026-10-18).

| Id | Question | Default | Why |
| --- | --- | --- | --- |
| D1 | Windsurf: `.windsurf/` or `.devin/` for rules and skills? | `.windsurf/rules/`, `.windsurf/skills/` | Documented as read by current Devin Desktop ("fallback", "still read") and the only one older Windsurf builds read. STOP condition if the docs say it is no longer read. |
| D2 | Cline: `.cline/rules/` or `.clinerules/`? | `.cline/rules/`, `.cline/skills/` | Both documented for VS Code, Desktop and CLI; `.cline/` cannot collide with the old `.clinerules` file during migration, nor with a user's own `.clinerules/`. `.cline/skills/` is Cline's "(recommended)". |
| D3 | Copilot: keep `.github/copilot-instructions.md` for the always-on rules, or `.github/instructions/bem-te-vi.instructions.md` with `applyTo: "**"`? | keep `.github/copilot-instructions.md` | It is the one file every Copilot surface reads; path-specific files are "only supported for Copilot cloud agent and Copilot code review" on GitHub.com. It already collides with a user's own file today (backed up); that is unchanged and recorded in the backlog. |
| D4 | Add global installs for Copilot (`~/.copilot/skills/`) and Cline (`~/.cline/skills/`, `~/.cline/rules/`), now documented? | No, not in this plan | A new capability that changes case 001; it goes to the backlog. |
| D5 | Make some rules description- or glob-activated instead of always on? | No: all 9 always on | Same as Claude Code; every file fits with margin; what is always on is plan 021's budget, not this plan's. |
| D6 | Agents: skills, or each editor's native subagents? | Skills | Native subagent formats differ per editor and `model: opus` is a Claude Code value; plan 003's deferred "native multi-agent distribution" is its own decision. |
| D7 | Accept that an editor reading several tools' skill folders can list a skill twice when two editors are installed? | Accept, and say so in the README | The alternative (one shared folder) breaks per-editor uninstall. |

> **Decided, 2026-10-20, Marco: D4 is yes, for 4.1.0. Done by plan 058.** A global install now
> writes Copilot's skills in `~/.copilot/skills/` (no rules file: no user-level instructions file is
> read by every Copilot surface) and Cline's rules and skills in `~/.cline/rules/` and
> `~/.cline/skills/`. Conformance case 001 is retired there; cases 069-074 replace it.

**Decided by Marco, 2026-10-20: D3 as the default.** A user's own `.github/copilot-instructions.md`
keeps being backed up and replaced, as any colliding file is; the user merges by hand (recorded in
the `plans/README.md` backlog).

**Decided by Marco, 2026-10-20: D6 as the default.** The four agents stay Agent Skills in every
editor; no editor gets native subagents. This also closes plan 003's deferred native multi-agent
distribution.

## Steps

### Step 1: conformance cases, red first

New cases, numbered from 050 (cases 026-030 belong to plan 043; 044 and 045 are plan 044's). Write
them, run them against the installers on `next` and quote the failures in the pull request.

| Case | Asserts |
| --- | --- |
| 050 | `install project` for each of the five editors writes its rule files and all 24 skill folders at the locations in "Per editor and target", recorded under that editor, and writes none of `.cursor/rules/qa.mdc`, `.windsurfrules`, `.clinerules`, `.bem-te-vi/`. |
| 051 | `install global` for Cursor, Windsurf and Antigravity writes only skills, at `~/.cursor/skills/`, `~/.codeium/windsurf/skills/`, `~/.gemini/config/skills/`; nothing under `~/.cursor/rules/`, `~/.windsurf/`, `~/.gemini/antigravity/`, and no `global_rules.md`. |
| 052 | Update from a 4.1.0 project install (seeded: each old path and `.bem-te-vi/<editor>/` files with manifest entries), all five editors: every old file removed and forgotten ("no longer shipped"), every new file "Added" and recorded, `.bem-te-vi/` gone. |
| 053 | Same from a 4.1.0 global install (Cursor, Windsurf, Antigravity): old files removed, `~/.windsurf/` removed when emptied, `~/.gemini/antigravity/` kept because it holds a seeded file of Antigravity's own. |
| 054 | Update keeps an old-location file the user changed (`.windsurfrules` edited) and reports it; the new files are installed anyway. |
| 055 | `.clinerules` recorded as a file but now a folder holding `default-rules.md`: update and uninstall exit 0, leave the folder and its file byte-identical, and report it. |
| 056 | Uninstall of a 4.1.0 install that was never updated removes the old-location files (it must follow the manifest, not the new editor map). |
| 057 | Uninstalling Cursor spares Antigravity's `.agents/skills/` and rules, and the reverse (replaces the cursor and cline lines of case 010). |
| 058 | A user's own `.agents/skills/qa/SKILL.md` (Antigravity) and `.cursor/skills/qa-cases/SKILL.md` are backed up, not overwritten, and survive uninstall as backups. |
| 059 | A linked `.agents/skills` folder (a common way to share skills between tools) is never written or deleted through; the install reports it and installs the rest. |

Commit: `test(conformance): pin the native rules and skills layout for every non-Claude editor`.

> **Correction, 2026-10-19, coordinator.** Cases 050-059 are free on `next` and are used as
> numbered here. Where a case says "a 4.1.0 install", read the layout the installers wrote before
> this plan (see the correction under Step 6): the cases seed those paths and their manifest
> entries directly, so they do not depend on which release wrote them.

### Step 2: the editor map and the three installers

`.qa-skills-editor-map` gets the new columns, tab-separated:
`key  project-rules  global-rules  project-skills  global-skills  label`, `-` where there is none:

```text
cursor       .cursor/rules    -  .cursor/skills    .cursor/skills             Cursor / Trae
windsurf     .windsurf/rules  -  .windsurf/skills  .codeium/windsurf/skills   Windsurf (Devin Desktop)
copilot      .github          -  .github/skills    -                          GitHub Copilot
cline        .cline/rules     -  .cline/skills     -                          Cline
antigravity  .agents/rules    -  .agents/skills    .gemini/config/skills      Antigravity
```

An editor is installable for a target when its skills column is not `-` (so Copilot and Cline stay
project-only, case 001 unchanged). The generated rule files of `adapters/<key>/rules/` go into the
rules folder (Copilot's single file lands at `.github/copilot-instructions.md`); `adapters/skills/`
goes into the skills folder. Then, in `install.sh`, `install.ps1` and the CLI, the same change and
nothing else:

- one helper listing `(package file, destination)` pairs for an editor and target, used by install,
  by the package-file list (update and adoption) and by the update prune;
- install: each pair through the existing install function;
- update prune: "no longer shipped" is "recorded for this editor and not in the pairs" (Migration,
  item 1); the folder guard of item 3; the reports of item 4;
- uninstall: every recorded file of the editor through the existing removal, then emptied folders
  (item 2), never through a link;
- the post-install hint (case 021) lists the rules and skills folders written.

If plan 043's `reference_files` / `Get-ReferenceFiles` / `referenceFilesFor` helpers exist, they are
replaced by the one helper above. Commit: `feat(installers): install each editor's rules and skills
where the editor documents them`.

### Step 3: the generators

`generate-adapters.sh` and `generate-adapters.ps1` stop building a merged source. They write:

- `adapters/skills/<name>/SKILL.md` for the 11 commands and 4 agents (frontmatter `name`,
  `description`, `metadata: id`, then the body without its frontmatter), the 8 skills copied with
  their files, and `qa-rules` (`SKILL.md` listing the rules, `references/<rule>.md` each rule
  without frontmatter);
- `adapters/<key>/rules/`: `bem-te-vi.<ext>` (the index) and `bem-te-vi-<rule>.<ext>` per rule with
  the editor's frontmatter (Cursor `description` and `alwaysApply: true`, `.mdc`; Windsurf and
  Antigravity `trigger: always_on`; Cline none); for Copilot one `copilot-instructions.md` with the
  index then each rule under a `<!-- bem-te-vi-<rule> -->` line;
- `adapters/universal/AGENTS.md` and `CLAUDE.md`: the header comment (which now also says to copy
  `adapters/skills/` to the folder the agent reads skills from), the index, the rules.

The old seven files are no longer written. Output byte-identical between the two generators (C
locale order, LF, no BOM); the Windows parity step compares them. Commit: `feat(adapters): generate
per-editor rules and one Agent Skills tree instead of a merged file`.

### Step 4: `tests/verify-adapters.sh` and `.ps1`

The same checks in both: the expected tree exists; every `SKILL.md` has `name` equal to its folder
and matching `^[a-z0-9]+(-[a-z0-9]+)*$` (at most 64), a `description` of 1 to 1,024 characters, and
at most 500 lines; `qa-reference/references/` has the 15 files and `qa-rules/references/` the 9
rules, each byte-identical to its source without frontmatter; each editor's rule files are within
the budgets of the size table (85 percent of the limit); no file anywhere contains a
merged-file section marker (`<!-- source:`). Commit: `test(adapters): check the native layout and every editor's size
budget`.

### Step 5: the existing cases and lifecycle suites that name the old paths

At `8487bd6` these name an old adapter path: conformance cases 001, 010, 012 and 022,
`tests/test-lifecycle.sh`, `tests/test-lifecycle.ps1` (and plan 043's cases 026-030 once merged;
`grep -rlE 'qa\.mdc|\.windsurfrules|\.clinerules|copilot-instructions|antigravity/skills|windsurf/rules|\.bem-te-vi'`
lists them). Change each to the new path that tests the same guarantee, never weaken the
guarantee; say in the commit which case asserts what now. Commit: `test: move the existing installer
tests to the new editor paths`.

> **Correction, 2026-10-19, coordinator.** While `tests/test-lifecycle.sh` is open, Test 60's
> comment "Conformance cases 026-027" is stale: those cases were renumbered 044-045. Fix it in its
> own commit.

### Step 6: migration from a 4.1.0 install, proven by a lifecycle test

"4.1.0 install" means the layout the installers write on `next` just before Step 2: the merged
adapter at each old project and global path and, if plan 043 has merged, the 15 references under
`.bem-te-vi/<editor>/`, with their manifest. Capture it once from those installers into
`tests/fixtures/install-4.1.0/` (`project/` and `home/` trees and their `.qa-skills-manifest`
files; a `README` naming the commit it was captured at; listed in `.markdownlintignore`). To keep
the fixture small, each file's content may be replaced by a short placeholder as long as the
manifest records that placeholder's hash: the migration depends on paths and recorded hashes, not
on adapter text. New lifecycle tests in both suites copy the fixture into a sandbox and run, for
each editor: `update` (old paths gone, new files present, `Added` and `no longer shipped` printed),
then `uninstall` (nothing left but backups), and separately `uninstall` straight from the fixture.
Commit: `test(lifecycle): prove the update and uninstall of a 4.1.0 install`.

> **Correction, 2026-10-19, coordinator.** 4.1.0 has not shipped: the last release anyone has is
> 4.0.1, and plan 043's `.bem-te-vi/<editor>/` layout never shipped in any release. The lifecycle
> tests therefore prove the migration from **4.0.1**, using `tests/fixtures/release-v4.0.1/`, which
> plan 045 added (lifecycle Test 54 installs 4.0.1 from it and updates). No
> `tests/fixtures/install-4.1.0/` is captured. `.bem-te-vi/` is still cleaned up under the manifest
> rules, because development and pre-release installs may have it; conformance cases 052 and 056
> prove that.

### Step 7: the shipped wording

`.claude/commands/qa.md` ("How the package names its files", lines 70-77 at `8487bd6`) and
`.claude/skills/qa-reference/SKILL.md` (lines 41-43): remove the merged-file sentences (or plan
043's `.bem-te-vi/<editor>/` wording) and say that outside Claude Code every command, skill and
agent is installed as an Agent Skill of the same name, and the rules as rule files named
`bem-te-vi-<rule>` and inside the `qa-rules` skill. `tests/test-reference-links.sh` must still pass
(no `.claude/skills/` path, no prefixed reference path). Released files: run
`./generate-known-hashes.sh` so the old hashes stay known, then `--check`. Commit: `fix: say how a
non-Claude install names commands, agents and rules`.

### Step 8: the README

The editor table (paths per editor and target, the Windsurf label, the skills folders), the
universal adapters (copy `AGENTS.md` and the `adapters/skills/` folder), the measured sizes from
Step 9, the duplicate-listing note (D7), and the Copilot collision note (D3). Commit: `docs: describe
the per-editor rules and skills install`.

### Step 9: verify and record

Run "Commands", then `bash ~/qa-ci-all.sh <worktree>`. Record the outcome here with each editor's
measured always-on size against its limit, and update `plans/README.md`. Add to the backlog: global
installs for Copilot and Cline (D4); `qa-plan` and `qa-cases` over the 5,000-token body
recommendation; the `.github/copilot-instructions.md` collision (D3).

## Commands

| Purpose | Command | Expected |
| --- | --- | --- |
| Adapters | `./generate-adapters.sh --clean && ./tests/verify-adapters.sh` | exit 0, every budget printed |
| Conformance | `./tests/conformance/test-runner.sh && ./tests/conformance/run.sh` | pass, 050-059 included |
| Lifecycle | `./tests/test-lifecycle.sh` | pass, migration tests included |
| Pointers, citations, frontmatter | `./tests/test-reference-links.sh`, `./tests/test-ctfl-citations.sh`, `./tests/test-frontmatter.sh` | exit 0 |
| Rules budget | `./tests/test-rules-size.sh` | exit 0, unchanged |
| Known hashes | `./generate-known-hashes.sh --check` | exit 0 |
| All three platforms | `bash ~/qa-ci-all.sh <worktree>` | "ALL LOCAL CI": linux, mac, windows PASS (Windows: symlink cases and `test-lifecycle.ps1` not run locally, say so) |

## Done criteria

- [x] Every always-on file of every editor is within its budget (85 percent of the documented
      limit), enforced by `tests/verify-adapters.*`, and the outcome lists the measured sizes.
- [x] Every command, skill and agent is reachable on demand in every editor as an Agent Skill, and
      the rules are reachable in a global install through `qa-rules`.
- [x] No installer writes any of the four stale locations, `.cursor/rules/qa.mdc`, `.windsurfrules`
      or `.bem-te-vi/`; update and uninstall clean them up under the manifest rules, identically
      in all three installers.
- [x] Cases 050-059 fail on the installers before Step 2 (quoted) and pass on all three after.
- [x] Conformance green on Linux, macOS (bash 3.2) and Windows PowerShell 5.1.
- [x] Migration from a 4.1.0 install proven by the lifecycle tests in both suites (from 4.0.1:
      see the correction under Step 6).
- [x] Both generators' output byte-identical.
- [x] README paths and sizes are the measured ones.

## STOP conditions

- A source re-read at implementation no longer says: Windsurf reads `.windsurf/rules` and
  `.windsurf/skills`; Cursor reads `.cursor/skills` and `~/.cursor/skills`; Antigravity reads
  `.agents/rules`, `.agents/skills` and `~/.gemini/config/skills`; Cline reads `.cline/rules` and
  `.cline/skills`; Copilot reads `.github/skills`. Stop and re-plan that editor.
- Any always-on file is over its budget after generation. Do not trim rule text here: plan 021
  owns that budget. Stop.
- A command, agent or skill cannot become a valid Agent Skill (name or description constraint): stop.
- The installer change needs a change to the manifest format or the known-hash format, or a third
  installer cannot do what the other two do: stop, the file-safety contract is shared.
- Migration would need to delete a folder, a file the manifest did not record, or a file not as
  recorded: stop.
- A conformance case cannot be made red against the installers before Step 2: stop.
- Plans 044, 045 or 046 have changed how an installer reads the editor map in a way that is not a
  plain textual merge: stop and report.

## Rejected approaches

- **Keep one merged file per editor.** Plan 043 measured the floor: about 232,000 characters with
  only commands, skills, rules and agents left, 19 times Windsurf's per-file limit. No further cut
  of a single file reaches any limit.
- **Drop the editors that are over their limit.** Every one of them now supports small rule files
  and Agent Skills; the content fits once split.
- **Split the merged file into numbered always-on chunks** (`qa-1.md` ... `qa-20.md`). Each file
  would be under Windsurf's limit, but all 232,000 characters would still be in every conversation;
  Antigravity's 20,000-token budget alone rules it out.
- **Workflows, commands or prompt files for the commands.** See "Why not workflows" above.
- **Make rules description-activated** (Cursor Apply Intelligently, Windsurf Model Decision,
  Antigravity `model_decision`) to cut the always-on load further. Every rule fits always on with
  margin; making one optional changes the package's behaviour away from Claude Code's. D5.
- **One shared `.agents/skills/` for every editor.** Breaks per-editor uninstall (case 010). D7.
- **Keep plan 043's `.bem-te-vi/<editor>/` for the references.** With native skill folders the
  references sit in `qa-reference/references/`, exactly where the shipped wording and the Agent
  Skills format put them; a second location would need its own pointer note in every editor.
- **One skills tree per editor in `adapters/`.** The content is identical; five copies would add
  about 1.4 MB to the package for nothing. Only the rule files differ per editor.
- **Write the global single files** (`global_rules.md`, `~/.gemini/GEMINI.md`, Cursor user rules).
  Each is one file the user owns; the installer would back up and replace the user's whole global
  configuration, and Windsurf's is limited to 6,000 characters, less than the rules.
- **Native subagents for the four agents.** D6.
- **Delete `.clinerules/default-rules.md` after Cline's conversion when its hash matches the old
  `.clinerules` entry.** It is a path the package never recorded; the contract forbids guessing.

## Findings outside scope (recorded, not fixed)

- Copilot (`~/.copilot/skills/`) and Cline (`~/.cline/skills/`, `~/.cline/rules/`) now document
  global locations; both are still project-only here (D4).
- Antigravity's CLI reads global skills from `~/.gemini/antigravity-cli/skills/`, a third location
  this plan does not install to.

  > **Decided, 2026-10-20, Marco, and done by plan 058**: both items above. Antigravity's skills
  > page confirms the CLI's folder ("`~/.gemini/antigravity-cli/skills/<skill-folder>/`", "Global
  > (all workspaces)"); a global Antigravity install writes it as well as `~/.gemini/config/skills/`.
- Windsurf's documentation now lives at docs.devin.ai as "Devin Desktop"; the editor key stays
  `windsurf`, only the label changes.
- `qa-plan` and `qa-cases` bodies are over the 5,000-token recommendation of the Agent Skills format
  and of Cline.
- Not run, and not runnable here: any of the five editors. Every loading behaviour above is the
  documented one, quoted; none is observed. A manual check per editor (rules listed as always on,
  skills listed, `/qa-cases` or `@qa-cases` loads the skill, a reference opened from it) is the
  first thing to do after implementation, by someone with the editors installed.

## Outcome (2026-10-19)

Implemented on branch `feat/editor-native-layout`, stacked on plan 051's `refactor/cli-out-of-bin`
(the CLI is `cli/bem-te-vi.js` there). Every STOP condition was checked; none fired.

**Drift check and sources.** The drift check showed plans 043-046 merged as expected; the editor
map was still read the same way by all three installers (`editor_map_field`, `Get-EditorMap`,
`loadEditorMap`, five columns), so the plain-merge STOP condition did not fire. The sources were
read again on 2026-10-19 with WebFetch, and every fact in the first STOP condition holds:

- Windsurf (docs.devin.ai): workspace rules "`.devin/rules/*.md` (preferred)" and
  "`.windsurf/rules/*.md` (fallback)"; skills "`.devin/skills/` (preferred) or `.windsurf/skills/`
  (legacy)"; global "`~/.codeium/windsurf/skills/` or `~/.config/devin/skills/`"; "Limited to
  12,000 characters per file."
- Cursor: skills "Project-level: `.agents/skills/` and `.cursor/skills/`", "User-level:
  `~/.agents/skills/` and `~/.cursor/skills/`"; rules "Stored in `.cursor/rules`", "Project rules
  must use the `.mdc` extension", "Keep rules under 500 lines".
- Antigravity: rules "`<dir>/.agents/rules/*.md`"; skills "`<workspace-root>/.agents/skills/<skill-folder>/`",
  global "`~/.gemini/config/skills/<skill-folder>/`"; "truncates any single rule file that exceeds
  24,000 bytes", a "20,000-token aggregate rules budget".
- Cline: workspace rules in "`.clinerules/`" or "`.cline/rules/`"; skills "`.cline/skills/`
  (recommended)"; "Rules without frontmatter are always active."
- Copilot: "Project skills, stored in your repository (`.github/skills`, `.claude/skills`, or
  `.agents/skills`)".

**Red first (Step 1).** Cases 050-059 were committed before any installer change and run against
the installers then on the branch (`309b470`): every one failed for `install.sh` and the CLI on
Linux, and for `install.ps1` and the CLI on Windows PowerShell 5.1 (059 is a symlink case, so it
is not run there). First failure per case and installer, Linux:

| Case | `install.sh` and the CLI |
| --- | --- |
| 050 | `the package has no file under adapters/cursor/rules` |
| 051 | `the package has no file under adapters/skills` |
| 052 | `should not exist: project:.cursor/rules/qa.mdc` |
| 053 | `should not exist: home:.cursor/rules` |
| 054 | `project:.windsurfrules holds '<!-- bem-te-vi: references -->` (the user's edit was backed up and replaced) |
| 055 | `manifest should not record: project cline .clinerules` |
| 056 | `should not exist: project:.bem-te-vi` |
| 057 | `the package has no file under adapters/antigravity/rules` |
| 058 | `backup of project:.cursor/skills/qa-cases/SKILL.md holds '', expected 'MY OWN QA-CASES SKILL'` |
| 059 | `the package has no file under adapters/antigravity/rules` |

On Windows the same lines, for `install.ps1` and the CLI. Two things the cases needed:

- A runner directive, `expect-tree-as-package: <path> = <package folder>`, so a case can require
  every file of the 24-folder skills tree without naming each (both runners, both self-tests).
- Case 056 is red only through a path outside the old editor map. The installers before this plan
  already followed the manifest for the paths they knew, so the case records a plan 043 reference
  under a skill folder the package does not ship (`.bem-te-vi/cursor/retired-skill/`): only the
  manifest can lead uninstall to it and to its emptied folders. Without it the case would have
  passed against the old installers, which the STOP condition forbids.
- Case 059 first lacked a `seed-dir` for the folder holding the link (the runner does not create
  it); fixed in the same commit before any installer change, and red again on Linux as above.

**What changed, by step.**

- Step 2: `.qa-skills-editor-map` has the columns of this plan. One helper per installer
  (`editor_files`, `Get-EditorFiles`, `editorFilesFor`) lists the `(package file, destination)`
  pairs for an editor and target, in byte order, and install, update, adoption and the update
  prune all use it; plan 043's reference helpers are gone. On update, a recorded path the install
  no longer writes is "no longer shipped"; a recorded path that is now a folder is kept, reported
  ("is a directory now") and forgotten; emptied folders go up to the base, never through a link.
  Uninstall follows the manifest, then removes the folders its recorded files and the package's
  destinations leave empty. The notes of "Migration" item 3 and 4 are one shared wording in all
  three installers.
- Step 3: both generators write `adapters/skills/` (24 skills, 48 files), `adapters/<editor>/rules/`
  and `adapters/universal/`; 91 files, byte-identical between bash and Windows PowerShell 5.1.
- Step 4: `tests/verify-adapters.sh` and `.ps1` check the tree, the Agent Skills format, the
  references against their sources, and the budgets; both print the same figures.
- Steps 5 and 6: see the commits; the existing cases and both lifecycle suites test the same
  guarantees at the new paths. Bash Test 63 runs release 4.0.1's own installer for each editor
  and updates with `install.sh` and the CLI; PowerShell Test 50 rebuilds the 4.0.1 install from
  that release's editor map and updates with `install.ps1`. Test 54 (all editors at once, against
  a fresh install, file for file) passes unchanged.
- Step 7: `/qa` and the `qa-reference` skill say how a non-Claude install names its files;
  `tests/test-reference-links.sh` passes. `.qa-skills-known-hashes` is built from the release tags
  only, so it does not change; `./generate-known-hashes.sh --check` passes.
- Step 8: the README editor table, install table, size table and the D3 and D7 notes.

**One finding, fixed on the way.** `install.ps1`'s uninstall wrapped `Get-EditorFiles` in `@()`,
which nests the list that function returns as one object; uninstall then stopped on `Substring`.
Cases 030, 045, 056 and 057 caught it on Windows; fixed in its own commit.

**Measured always-on sizes** (`tests/verify-adapters.sh`, the same on Windows), against the budget
the check enforces:

| Editor | Files | Largest | All | Budget enforced |
| --- | --- | --- | --- | --- |
| Windsurf | 10 | 7,873 characters | 23,023 characters | 10,200 characters per file |
| Cursor | 10 | 126 lines | 415 lines | 425 lines per file |
| Copilot | 1 | 393 lines | 393 lines | 850 lines |
| Antigravity | 10 | 7,892 bytes | 23,148 bytes; 23,063 characters | 20,400 bytes per file; 68,000 characters in all |
| Cline | 10 | 7,846 characters | 22,753 characters | none (the source rules cap) |
| `universal/AGENTS.md` | 1 | 24,143 bytes, 405 lines | same | 27,852 bytes |

The skills tree is 24 folders and 48 files; the names and descriptions, all that is in context
before a skill is used, come to 7,792 characters. `tests/test-rules-size.sh` is unchanged.

**Decisions: the defaults, all of them** (Default used (Marco asked for all remaining work on
2026-10-18)): D1 `.windsurf/rules/` and `.windsurf/skills/`; D2 `.cline/rules/` and
`.cline/skills/`; D3 keep `.github/copilot-instructions.md`; D4 no global Copilot or Cline
install; D5 all nine rules always on; D6 agents as skills; D7 accept a duplicate listing, said in
the README.

**Interpretations, recorded.** Step 4's "each byte-identical to its source without frontmatter" is
read as: the 15 `qa-reference` references byte-identical to their sources (the skill is copied as
it is, frontmatter included), and the 9 `qa-rules` references identical to the rules without
frontmatter. The "no section marker" check looks for a line that starts with `<!-- source:` and a
space, the form the merged file used. The index rule tells the assistant, where a command dispatches an
agent, to read that agent's skill and do its stage itself, since no other editor runs this
package's subagents.

**Pre-manifest installs of non-Claude editors** (the pre-manifest layout of v1.2.0-v2.3.2, 2026-04
to 2026-09-16: `.cursor/rules/qa.mdc`, `.windsurfrules`, `.clinerules` and the rest) are not cleaned
by an uninstall without a manifest, which was already the case in practice: the fallback compared
them with the current package and could not match them (the decision of 2026-10-19, under
"Review of #193").

**Not run.** None of the five editors: every loading behaviour is the documented one, quoted above,
and none is observed. A manual check per editor is still the first thing to do with the editors at
hand (see "Findings outside scope").

**Backlog added** (`plans/README.md`, "Backlog from plan 047"): global installs for Copilot and
Cline (D4); `qa-plan` and `qa-cases` bodies over the 5,000-token recommendation; the
`.github/copilot-instructions.md` collision (D3).

## Review of #193 (2026-10-19)

The coordinator's review raised one blocker, one should, and four findings to record.

**Blocker 1, not fixed: a STOP condition of the review fired.** On uninstall, `install.sh` and
`install.ps1` decide "had a manifest" per editor, so once an earlier editor's uninstall empties and
deletes the manifest, each later editor falls into the no-manifest fallback, which now walks all of
that editor's 58 package destinations and deletes whatever is byte-identical to the package (for
example skills a user copied into `.agents/skills/` by hand, as the universal header says to).
The CLI decides it once per run and has no fallback for non-Claude editors. The review asked to
drop that fallback in the two shell installers only if git history shows that no release installed
a non-Claude editor without a manifest, and to stop and report otherwise. History shows the
opposite:

- The manifest first appears in `install.sh` in commit `6ea0e18` (2026-09-15), first released in
  `v2.3.3` (2026-09-16). `git show <tag>:install.sh | grep -c qa-skills-manifest` is 0 for every
  tag from `v1.2.0` to `v2.3.2` and 2 from `v2.3.3` on.
- Every one of those earlier tags installs non-Claude editors without one: `v2.3.2:install.sh` writes
  `.cursor/rules/qa.mdc`, `.windsurfrules`, `.github/copilot-instructions.md`, `.clinerules` and
  `~/.gemini/antigravity/skills/qa/SKILL.md` (lines 403-454); `v1.2.0` (2026-04-07) already wrote the
  first four, and Antigravity from `v1.2.1`. `install.ps1` at `v2.3.2` writes them too.
- The CLI's comment ("Only `claude` installs predate the manifest format") is true of the CLI alone:
  `bin/cli.js` has `EDITOR_TARGETS` only from `v2.5.0`, after the manifest.

So nothing was changed for blocker 1. For the decision, one more fact: the fallback compares a
destination with the package's current file, and `.qa-skills-known-hashes` covers `.claude/` only,
so for a non-Claude editor the fallback could never recognise what a pre-manifest release wrote (an
old merged adapter); since this plan it walks only the new destinations, which no pre-manifest
release wrote. What it can still remove is a file byte-identical to the current package: a hand
copy, or a current install whose manifest was not kept. Dropping it would lose nothing a
pre-manifest install left; deciding "had a manifest" once per base per run, as the CLI and update
already do, closes the reported repro either way.

> **Decision, 2026-10-19, coordinator.** Correct to stop; on the history above, do both, in all
> three installers where they apply. The non-Claude no-manifest fallback compares the current
> package at the new destinations, which no pre-manifest release wrote: tags `v1.2.0` to `v2.3.2`
> installed non-Claude editors with no manifest, `v2.3.3` was the first with one, and
> `.qa-skills-known-hashes` covers `.claude/` only. So the fallback cannot recognise anything a
> pre-manifest install left and can only delete copies the user made. (1) Drop it in `install.sh`
> and `install.ps1` (the CLI has none); keep the Claude Code fallback, which the known hashes back.
> (2) Decide "had a manifest" once per base per run, before any editor is uninstalled, in all three,
> so the Claude Code fallback cannot start mid-run because an earlier editor's uninstall emptied
> and deleted the manifest.
>
> **Done, 2026-10-19.** Conformance case 061, red first: with the manifest recording only Cursor,
> `uninstall project all` deleted hand copies of `adapters/skills/` in `.agents/skills/` and
> `.cline/skills/` and an `.agents/rules/` copy, and with no manifest `uninstall global antigravity`
> deleted copies in `~/.gemini/config/skills/`: `install.sh` and `install.ps1` failed 7 lines each
> ("differs from the package's adapters/skills/qa/SKILL.md", ...); the CLI passed. The case also
> keeps `.claude` files the manifest did not record; that part cannot be made red, because `all`
> uninstalls Claude Code first, while the manifest still exists. Both shell installers now decide
> the manifest state once per base per run (`note_uninstall_base`, `$script:UninstallHadManifest`),
> as the CLI already did, and have no fallback for non-Claude editors. 061 passes on all three.

**Should 2, fixed: empty-folder cleanup now follows an actual removal, the same in all three.**
Uninstall of a non-Claude editor removes the folders that its own removals emptied and, when it
removed anything, that editor's package folders; never a folder of an editor with nothing removed.
The CLI's `removeEmptyDirChain` now stops at the first missing level, as `install.sh` and
`install.ps1` always did; it climbed past it and removed a user's own empty `.github/skills`.
Conformance case 060, red first on all three: `install.sh` and `install.ps1` removed the user's
empty `.agents/rules`, `.cline/rules`, `.windsurf/rules` and `~/.cursor/skills/qa-cases`; the CLI
also `.github/skills` and `~/.gemini/config/skills`. All pass after the fix.

**Recorded, not fixed (later):**

- **3.** `install.sh`'s uninstall read the recorded paths with `awk '{ print $3 }'`, which cuts a path
  at its first space. That line went with the should-2 fix (the pruning now uses the paths it
  removed); `uninstall_recorded` reads them with `read -r HASH ENTRY_ED REL`, which keeps the rest of
  the line. No other `$3` read of the manifest is left in `install.sh`; a path with a space is
  still untested in all three installers.
  **2026-10-19: done in plan 053** (I11): conformance cases 065 and 066.
- **4.** `generate-adapters.sh` writes `adapters/skills//SKILL.md` for a command or agent with no `id` in
  its frontmatter (the PowerShell generator throws instead); only `tests/verify-adapters.sh`'s file
  count catches it.

  > **Fixed, 2026-10-19, plan 054 item 1.** Both generators now refuse, before writing anything, a
  > command or agent with no id and a skill name two sources share (which this finding did not
  > list: an agent with `id: qa-plan` was silently replaced by the `qa-plan` skill folder), with
  > the same lines and exit 1; `tests/test-generator-errors.*` holds both to
  > `tests/fixtures/generator-errors.txt`.

- **5.** The `copilot-instructions.md` budget measures lines only (850 of "about 1,000"). Whether Copilot
  code review reads only the first 4,000 characters of an instructions file: the English pages read
  on 2026-10-19 ("Using GitHub Copilot code review", both locations, and "Customize code review")
  state no character limit, only "Limit any single instruction file to a maximum of about 1,000
  lines". A search engine's summary quoted "Copilot code review only reads the first 4,000
  characters of any custom instruction file", apparently from an earlier version of a page; not
  confirmed on the current pages. If it holds, code review sees only the start of the file, the
  index and part of the first rule of about 23,000 characters.

  > **Checked, 2026-10-19, plan 054 item 2.** The limit existed and has been removed. GitHub
  > Changelog, "Copilot code review: New configurations and controls", June 12, 2026
  > (<https://github.blog/changelog/2026-06-12-copilot-code-review-new-configurations-and-controls/>):
  > "Previously, Copilot code review would stop reading `copilot-instructions.md` and
  > `*.instructions.md` files located under the `.github` directory once the file reached 4000
  > characters in size. That limit has now been removed, allowing additional customization and
  > flexibility in your custom instructions." The current pages state only the "about 1,000 lines"
  > guidance. The file is 393 lines, 23,142 characters; the layout stays as it is.
- **6.** An old merged adapter with no manifest (for example `.cursor/rules/qa.mdc` committed while
  `.qa-skills-manifest` is gitignored) is no longer recognised by update: adoption compares with
  the new destinations only.

  > **Decided by Marco, 2026-10-20: accepted.** No release before 2.3.3, the first with a manifest
  > (blocker 1 above), was published to npm. Checked the same day: `npm view @marcoamaral/bem-te-vi`
  > answers 404, and the unscoped `qa-skills` on the registry is another author's package
  > (`github.com/AZANIR/qa-skills`). Only an install made from a clone of the repository before
  > 2.3.3 can have left such an adapter.
