# Plan 022: Install through the Claude Code plugin marketplace and `npx skills add`

> **Executor instructions**: This is a plan only. Nothing here is implemented. **STOP: Marco must
> approve the recommendation and answer the decisions in "Decisions for Marco" before any file in
> "Files to add" is created.** The public repository (plan 020 part B) must exist first, because both
> install paths take `owner/repo` and the final names depend on it.

## Status

- **Priority**: P1 (plan 019 phase 10)
- **Effort**: M
- **Depends on**: plan 020 merged and the public repository `MarcoAmaral/bem-te-vi` live; plan 019
  phase 3 (frontmatter on skills and commands, already on `main`)
- **Planned at**: 2026-10-08, against v2.9.0 on `main`

## Why this matters

Competitors install in one line: `/plugin marketplace add owner/repo` (Claude Code) or
`npx skills add owner/repo` (Vercel's skills CLI). Bem-te-vi installs only through its own CLI and
shell installers. Both one-liners are also how people discover packages (plan 019 phase 12 lists
claudepluginhub.com as depending on this plan).

## What the official documentation says (researched 2026-10-08)

Sources, all fetched on 2026-10-08:

- Plugin manifest reference: <https://code.claude.com/docs/en/plugins/manifest-reference>
- Marketplace reference: <https://code.claude.com/docs/en/plugins/marketplace-reference>
- Create a marketplace: <https://code.claude.com/docs/en/plugins/create-marketplace>
- Install and manage plugins: <https://code.claude.com/docs/en/plugins/install>
- Plugin loading reference (cache, versions, updates): <https://code.claude.com/docs/en/plugins/loading>
- Plugin components: <https://code.claude.com/docs/en/plugins/components>
- Vercel skills CLI: <https://github.com/vercel-labs/skills>

### Claude Code plugins

1. **Layout.** `.claude-plugin/plugin.json` is optional (only `name` is required). Defaults are
   plugin-root `skills/`, `commands/`, `agents/` and `hooks/hooks.json`. Everything except the manifest
   goes at the plugin root, never inside `.claude-plugin/`.
2. **Custom component paths work.** The manifest may point elsewhere. Every path starts with `./`, must
   resolve inside the plugin root, and must exist.
   - `commands`: a file, a directory or an array. It **replaces** the default `commands/`, so
     `"commands": ["./.claude/commands/"]` works.
   - `skills`: directories of `<name>/SKILL.md`. It **adds** to the default, so
     `"skills": ["./.claude/skills/"]` works.
   - `agents`: `.md` **files only, directories are not accepted**. Each agent is listed by path.
   - `hooks`: a `.json` file wrapped in a top-level `"hooks"` key, or an inline object, merged with
     `hooks/hooks.json`. Commands use `${CLAUDE_PLUGIN_ROOT}`.
3. **Plugins cannot ship rules.** There is no rules component in the standard layout or the manifest
   reference. A `CLAUDE.md` at the plugin root is **not loaded**, and `claude plugin validate` warns
   `CLAUDE.md at the plugin root is not loaded as project context`. The documented advice is to put
   instructions in a skill (components page, and "Standard layout" in the manifest reference).
4. **Namespacing.** Every component is namespaced under the plugin `name`, so `/qa-cases` becomes
   `/bem-te-vi:qa-cases` and agent `qa-writer` becomes `bem-te-vi:qa-writer`. Names beginning with
   `claude-` or `anthropic-` are refused by `claude plugin validate`; `bem-te-vi` is fine.
5. **A marketplace may be the same repository.** `.claude-plugin/marketplace.json` needs `name`,
   `owner` and `plugins[]`; each entry needs `name` and `source`. `"source": "."` means the marketplace
   root itself, so one repository can be both marketplace and plugin. Keep the entry name equal to the
   `plugin.json` name.
6. **Install, update, uninstall.**
   - `/plugin marketplace add MarcoAmaral/bem-te-vi`, then `/plugin install bem-te-vi@<marketplace>`.
     Shell forms: `claude plugin marketplace add`, `claude plugin install <p>@<m> [--scope user|project|local]`.
   - Update: `claude plugin update <p>@<m>`. Auto-update is **off by default** for third-party
     marketplaces. With no `version` in `plugin.json` or the entry, the version is the 12-character
     commit SHA, so every commit is an update; a `version` string pins users until it changes.
   - Uninstall: `claude plugin uninstall`. Plugin files live in `~/.claude/plugins/cache/`, not in the
     project, so uninstall does not touch project files. Old versions are deleted 14 days later.
7. **Cache copy.** A marketplace plugin is copied into the cache, so only files inside the plugin root
   exist at run time. With `"source": "."` the whole repository is the plugin root and is copied,
   including `tests/`, `plans/` and `adapters/` (size and noise, not a correctness problem).
8. **Validation exists.** `claude plugin validate ./` checks manifest and marketplace; use it in CI.

### `npx skills add` (vercel-labs/skills)

1. Discovers `SKILL.md` folders in `skills/`, `skills/.curated/`, agent-specific directories such as
   `.claude/skills/`, and about 50 others, walking three levels deep. It also reads
   `.claude-plugin/marketplace.json` and `plugin.json` when present. Frontmatter requires `name`
   (lowercase, hyphens) and `description`; both of this repository's skills already have them.
2. Installs into 75+ agents (Claude Code `.claude/skills/` or `~/.claude/skills/`, Cursor, Codex,
   Cline, OpenCode and more). Flags: `--skill`, `-a/--agent`, `-g/--global`, `--list`, `-y/--yes`.
   The default method is a symlink to a canonical copy; copy is the alternative. Also `update`,
   `remove` and `find`.
3. **Installs skills only. Not commands, agents, rules or hooks.** The README says so.

### What could not be confirmed

- How `npx skills update` detects changes (no lockfile format or hashing is documented) and whether
  `remove` ever touches a file the tool did not create. Both are measured in the verification, not assumed.
- Exactly what `npx skills add` lists for this repository, which has two skills, ten commands and four
  agents. It should list only the two skills; verification step 4 confirms it.
- Behaviour of the symlink method on Windows (the tool offers copy as an alternative).

## What each install path delivers

| Capability | `bem-te-vi init` (CLI and shell installers) | Claude Code plugin | `npx skills add` |
| --- | --- | --- | --- |
| Rules (`.claude/rules/*`, 9 files) | Yes | **No** (platform limit) | **No** |
| Slash commands (10) | Yes, as `/qa-cases` | Yes, namespaced `/bem-te-vi:qa-cases` | **No** |
| Skills (`qa-explore`, `qa-plan`) | Yes | Yes, namespaced | Yes (the only thing it installs) |
| Agents (4 pipeline subagents) | Yes | Yes (listed per file) | **No** |
| Hooks (`check-test-evidence.sh`, `validate-tc-format.sh`) | Yes, copied and made executable | **None**: the repository ships these as scripts the user runs, not as event registrations (see rejected approaches) | **No** |
| Other editors (Cursor, Codex, Gemini, Copilot) | Yes (`--editor`) | Claude Code only | 75+ agents, skills only |
| Where files land | The user's project or `~/.claude/` | `~/.claude/plugins/cache/`, nothing in the project | The agent's skills directory |
| Manifest and known hashes | Yes (`.qa-skills-manifest`, `.qa-skills-known-hashes`) | Not applicable (Claude Code keeps `installed_plugins.json`) | Its own state |
| Update | `bem-te-vi update`, manifest-safe, local edits preserved | `claude plugin update` or auto-update; replaces the cached copy | `npx skills update` |
| Uninstall | Removes only files still exactly as installed, keeps and reports the rest | `claude plugin uninstall`, cache only | `npx skills remove` |
| Backup of a user's colliding file | Yes, `.qa-skills-backup-<UTC>` | Not applicable: nothing is written into the project, so nothing can collide | Unknown, verify |
| Needs Node | Yes (shell installers: no) | No | Yes |

**Summary**: a plugin install gives commands, skills and agents but **not the rules**. The CLI stays
the complete install, and its manifest-safe update and uninstall stay its advantage.

### A defect the plugin path would expose

Eight of the ten commands, both `qa-groomer` and `qa-designer` agents, and the `qa-explore` skill tell
the model to apply `.claude/rules/...` (for example `qa-cases.md` line 13: "apply
`.claude/rules/context-discovery.md`"). In a plugin-only install that file does not exist in the
user's project, so the instruction points at nothing and the command runs without the rule its first
step names. Decision 2 asks how to handle it; the default keeps the command text unchanged and has
the README say so.

## Recommendation

1. **Ship the Claude Code plugin from the same repository, pointing at `.claude/`.** No second content
   tree. One `.claude-plugin/plugin.json` with `commands` and `skills` pointing into `.claude/` and
   `agents` listing the four files; one `.claude-plugin/marketplace.json` with `"source": "."`.
2. **Add nothing for `npx skills add`.** It already works from `.claude/skills/*/SKILL.md`. Only README
   wording and a verification step. If it lists anything unexpected, adjust frontmatter, not layout.
3. **State the limits in the README**: plugin and `skills add` installs lack the rules; the CLI is the
   full install; the plugin prefixes command names.
4. **Close the rules gap in a separate later plan**: either a rules-only CLI flag
   (`bem-te-vi init --rules`) that the plugin README points to, or rules carried by a skill. Each
   changes CLI or content behaviour for every user.
5. Versioning: see decision 4.

## Decisions for Marco

1. **Ship the plugin without rules, or wait?** Recommendation: ship, with honest README wording. The
   alternative is to wait for the rules solution and ship everything together.
2. **Commands that cite `.claude/rules/...`** in a plugin-only install. Options:
   (a) leave as is and document (recommended, no content change);
   (b) reword so a missing rule file is explicitly non-fatal;
   (c) carry the rules in skills. (b) and (c) touch shipped content and need their own plan.
3. **Marketplace name**, the word users type after `@`. Suggested `bem-te-vi` for both marketplace and
   plugin, giving `/plugin install bem-te-vi@bem-te-vi`. It must avoid the reserved names and the
   GitHub download-folder rule (`MarcoAmaral-bem-te-vi`).
4. **Versioning.** (a) Leave `version` unset: every commit on `main` reaches users who update,
   including unreleased work. (b) Set `version` in `plugin.json` and have Release Please bump it with
   `package.json` (add it to `release-please-config.json` `extra-files`), so users move only on
   releases. Recommended: (b), matching this repository's release discipline.
5. **Plugin size.** With `"source": "."` the cached copy includes `tests/`, `plans/`, `adapters/` and
   `decisions/`. Narrowing it would mean moving `.claude/`. Recommended: accept.

## Files to add (after approval)

| File | Purpose |
| --- | --- |
| `.claude-plugin/plugin.json` | `name: bem-te-vi`, `description`, `author`, `license`, `repository`, `homepage`; `commands: ["./.claude/commands/"]`, `skills: ["./.claude/skills/"]`, `agents` listing the four files in `.claude/agents/`; `version` per decision 4 |
| `.claude-plugin/marketplace.json` | `name`, `owner`, `description`, one `plugins[]` entry with `"source": "."` |
| `tests/plugin/verify-plugin.sh` | CI step: JSON parses, every listed path exists, the agent list equals `ls .claude/agents`, entry name equals manifest name, and `claude plugin validate .` when the CLI is available |
| `README.md` (section "Install") | Three install paths with the table above, the rules limit, the prefixed command names |
| `CONTRIBUTING.md` | One line: adding or removing an agent file means editing `plugin.json` too (CI enforces it) |

Not changed: everything under `.claude/`, `bin/cli.js`, both installers, the generators and
`adapters/`. `package.json` `files` stays as is, since `.claude-plugin/` is for the repository, not the
npm tarball. `plans/README.md` is updated by the PR that lands this plan, not by the plan itself.

**One source of truth.** The manifests only *reference* `.claude/`; no content is copied or
generated. The single duplicated fact is the agent list in `plugin.json` (the platform wants files, not
a directory), and `verify-plugin.sh` fails CI if it drifts from `.claude/agents/`.

## README wording (draft)

> **Install with Claude Code's plugin marketplace**
>
> ```text
> /plugin marketplace add MarcoAmaral/bem-te-vi
> /plugin install bem-te-vi@bem-te-vi
> ```
>
> This installs the commands, agents and skills, with the plugin prefix (`/bem-te-vi:qa-cases`).
> **It does not install the rules** (`.claude/rules/`): Claude Code plugins cannot ship rules, so
> commands that mention a rule file will not find it. For the complete install, including rules, and
> an update and uninstall that never touch your own files, use `npx @marcoamaral/bem-te-vi init`.
>
> **Install just the skills for any agent**
>
> ```bash
> npx skills add MarcoAmaral/bem-te-vi
> ```
>
> This installs the two skills (`qa-explore`, `qa-plan`) only: no commands, agents or rules.

## Rejected approaches

- **A second `plugin/` content tree** (copy or generate `commands/`, `skills/`, `agents/` at the plugin
  root): the documented defaults, but it duplicates content and needs a generator and drift check for no
  gain, since custom paths into `.claude/` are supported.
- **Shipping the rules inside a skill so the plugin has them**: it works, but every rule becomes
  context-loaded skill content, which cuts against the token reduction in plan 019 phase 9. Its own plan.
- **A `SessionStart` hook that copies the rules into the project**: writes into the user's repository
  outside the manifest, bypassing the backup and hash safety of CLAUDE.md invariant 5.
- **Registering `check-test-evidence.sh` and `validate-tc-format.sh` as plugin hooks**: they are
  checkers the user runs, not event handlers; wiring them to events would change behaviour for plugin
  users only.
- **A separate marketplace repository**: two repositories to keep in step, when one repository can be
  both.
- **Pinning `source` to a `sha`**: a moving target for a marketplace meant to track releases.

## Verification

Run in throwaway directories, from the public repository (or a local clone via
`claude plugin marketplace add ./<clone>`), with a clean `HOME` for each path.

1. **Static**: `bash tests/plugin/verify-plugin.sh` and `claude plugin validate .` pass. Remove one agent
   from the list and confirm the script fails (red, then green).
2. **Plugin path**: in a clean project run `claude plugin marketplace add <source>`,
   `claude plugin install bem-te-vi@bem-te-vi --scope project`, then `claude plugin list` and
   `claude plugin details bem-te-vi`. Expected inventory: 10 commands, 2 skills, 4 agents, 0 hooks.
   Start a session and confirm `/bem-te-vi:qa-cases` is offered. Confirm the project gained no files
   other than the `.claude/settings.json` entry.
3. **Plugin update and uninstall**: push a trivial release-version change to the source, run
   `claude plugin update`, confirm the new version; run `claude plugin uninstall` and confirm the
   project is untouched.
4. **`skills add` path**: `npx skills add <source> --list` must list exactly `qa-explore` and
   `qa-plan`. Install one with `-a claude-code -y`, check `.claude/skills/`, edit the installed file,
   then run `npx skills update` and `npx skills remove`. **Record whether either touches the edited
   file**; this is the unconfirmed point above.
5. **CLI regression**: `./tests/test-lifecycle.sh` and `./tests/conformance/run.sh` still pass (no
   installer file changed). A project with the CLI install and the plugin both enabled works; commands
   appear twice (`/qa-cases` and `/bem-te-vi:qa-cases`) and the README says so.
6. **Docs**: `npx --yes markdownlint-cli@0.49.1 --dot README.md plans/022-plugin-marketplace-and-agent-skills-install.md`
   is clean.

## STOP

**Needs Marco's approval before implementation.** Once decisions 1 to 5 are answered, the executor
works on a `feat/plugin-marketplace` branch in the public repository with three commits
(`feat: add Claude Code plugin manifest and marketplace`, `test: verify plugin manifest against
.claude`, `docs: document plugin and skills installs`) and opens a PR for his approval.
