# Plan 002: Gitignore untracked scratch/reference directories

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git status --porcelain` and compare against
> the "Current state" list below. If the set of untracked top-level entries
> has changed materially (new unexplained scratch dirs, or `interview.txt` /
> `.tmp_repos` / `agentic-to-plan` / `docs` are now absent), treat it as a
> STOP condition and re-verify before proceeding.

## Status

- **Priority**: P1
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: security / hygiene
- **Planned at**: commit `39ac591`, 2026-07-29

## Why this matters

`git status --porcelain` currently shows four untracked top-level entries that
are **not** listed in `.gitignore`:

```text
?? .tmp_repos/
?? agentic-to-plan/
?? docs/
?? interview.txt
```

`.tmp_repos/` contains full local clones (including their own `.git/`
directories) of two external repositories (`superpowers`, `multica-agent-tools`)
being used as reference material for this planning effort — they are not part
of this package and must never be committed; doing so would vendor two
unrelated projects' full git histories into this repo.

`interview.txt` holds unrelated personal scratch notes, including personal data. This has nothing to do with the QA Skills
package and must not be committed to a public GitHub repository — the file
should not be part of this project's history at all, and its absence from
`.gitignore` means the very next broad `git add` could commit it (the repo's
own `CLAUDE.md` §"Executing actions with care" explicitly calls out checking
`git status` after a broad add for exactly this class of accident).

`docs/` (currently just `docs/specs/qa-skill-overhaul.md`) and
`agentic-to-plan/` (a LinkedIn post + screenshot used as design input) are
legitimate planning artifacts for this repo but are not yet a deliberate
decision to ship — they should at minimum be a conscious inclusion, not an
accidental one.

This plan only changes `.gitignore`. It does not commit, delete, or move any
of the four entries — that determination (ship `docs/`? delete
`.tmp_repos/`? relocate `interview.txt`?) belongs to the repo owner, not to
an automated executor.

## Current state

- `.gitignore` (full current content, repo root):

  ```gitignore
  # OS files
  .DS_Store
  Thumbs.db
  Desktop.ini

  # Editor/IDE files
  *.swp
  *.swo
  *~
  .idea/
  .vscode/*
  !.vscode/extensions.json
  *.sublime-project
  *.sublime-workspace

  # Environment / secrets
  .env
  .env.local
  *.key
  *.pem

  # Logs
  *.log

  # Dependencies
  node_modules/

  # Temporary files
  *.bak
  *.tmp

  # Generated adapters (regenerate with generate-adapters.sh)
  adapters/

  # Raw reference textbooks and syllabus (local developer use only, excluded from repo)
  CTFL/
  EngSW/
  ```

  Note the existing precedent at the bottom: `CTFL/` and `EngSW/` are already
  excluded with the comment "local developer use only, excluded from repo" —
  the four new entries follow the same pattern.
- `interview.txt` (repo root) — holds unrelated personal data. **Do not read, quote,
  or reproduce its contents anywhere in your commit message, PR description,
  or plan status update** — only reference it by filename.
- `.tmp_repos/` — contains `.tmp_repos/superpowers/` and
  `.tmp_repos/multica-agent-tools/`, each a full clone with its own `.git/`.
- `agentic-to-plan/` — contains `linkedin-post.txt` and `agentic-qa.png`.
- `docs/` — contains `docs/specs/qa-skill-overhaul.md`.

## Commands you will need

| Purpose | Command | Expected on success |
| --- | --- | --- |
| Confirm untracked set before editing | `git status --porcelain` | shows the four `??` entries listed above (plus any files already being modified by other in-progress plans) |
| Confirm ignore takes effect | `git status --porcelain` (after edit) | none of `.tmp_repos/`, `agentic-to-plan/`, `docs/`, `interview.txt` appear, tracked or untracked |
| Confirm ignore rule matches | `git check-ignore -v .tmp_repos agentic-to-plan docs interview.txt` | prints one matching `.gitignore` rule per path, exit 0 |

## Scope

**In scope** (the only files you should modify):

- `.gitignore`

**Out of scope** (do NOT touch, even though they look related):

- Do not delete, move, or edit the contents of `.tmp_repos/`, `agentic-to-plan/`,
  `docs/`, or `interview.txt`. Gitignoring them is the entire scope of this
  plan — what (if anything) happens to their contents is a separate decision
  for the repo owner.
- Do not `git rm --cached` anything — none of these four paths are currently
  tracked (`git status --porcelain` shows them as `??`, not `M`/`A`), so
  there is nothing to untrack. If you find any of them already tracked when
  you check, that contradicts "Current state" — treat it as a STOP condition.
- `CTFL/` / `EngSW/` entries already in `.gitignore` — leave as-is.

## Git workflow

- Branch: `chore/gitignore-scratch-dirs` (matches repo convention of
  `feat/...`, `fix/...`, `chore/...` per `CLAUDE.md` §5).
- Single commit, conventional-commits format:
  `chore: gitignore local scratch and reference directories`
- Do NOT push or open a PR unless the operator instructed it.

## Steps

### Step 1: Confirm nothing in scope is already tracked

Run `git status --porcelain` and confirm all four of `.tmp_repos/`,
`agentic-to-plan/`, `docs/`, `interview.txt` appear with a `??` prefix
(untracked), not `A`/`M`/`D`. If any appear as already tracked or staged,
STOP (see STOP conditions).

**Verify**: output contains lines starting `?? .tmp_repos/`,
`?? agentic-to-plan/`, `?? docs/`, `?? interview.txt`.

### Step 2: Add the new `.gitignore` entries

Append a new section to the end of `.gitignore`, after the existing
`CTFL/` / `EngSW/` block, following the same style (a `#` comment line
explaining why, then the path(s)):

```gitignore
# Local scratch, planning, and reference material (not shipped, local developer use only)
.tmp_repos/
agentic-to-plan/
docs/
interview.txt
```

**Verify**: `tail -8 .gitignore` shows exactly these 6 new lines appended
after the `EngSW/` line.

### Step 3: Confirm the ignore rules take effect

**Verify**: `git status --porcelain` no longer lists `.tmp_repos/`,
`agentic-to-plan/`, `docs/`, or `interview.txt` in its output. Also run
`git check-ignore -v .tmp_repos agentic-to-plan docs interview.txt` — it
should print one `.gitignore:<line>:<pattern>  <path>` line per argument and
exit 0 (a non-zero exit or missing line for any path means that path is
still not ignored).

## Test plan

No automated test suite covers `.gitignore` content. Verification is purely
the two commands in Step 3. Do not add a test for this — it would be
disproportionate to a one-line-per-path config change.

## Done criteria

Machine-checkable. ALL must hold:

- [ ] `git status --porcelain` shows no entries for `.tmp_repos`,
      `agentic-to-plan`, `docs`, or `interview.txt`
- [ ] `git check-ignore -v .tmp_repos agentic-to-plan docs interview.txt`
      exits 0 and prints 4 matching lines
- [ ] `git status --porcelain` shows only `.gitignore` as modified
      (`M .gitignore`), no other files touched
- [ ] `plans/README.md` status row for 002 updated to DONE

## STOP conditions

Stop and report back (do not improvise) if:

- Any of the four paths shows as already tracked (`A`/`M` instead of `??`)
  in `git status --porcelain` before you start — this means someone already
  committed part of this content upstream of your working tree, and blindly
  gitignoring it now would hide a file that's already in history (gitignore
  does not remove tracked files). Report this instead of running `git rm
  --cached` yourself.
- `interview.txt` contents would need to be read or quoted for any reason —
  do not do this; the plan is fully specifiable without it.
- The repo owner has, since this plan was written, added a `README.md` or
  other file inside `docs/` intended for publication (i.e. `docs/` looks like
  it's meant to ship, not stay local) — re-confirm intent before ignoring it,
  since that would silently exclude shippable documentation.

## Maintenance notes

- If `docs/` or `agentic-to-plan/` are later decided to be genuinely part of
  the shipped/published repo (e.g. `docs/specs/` becomes a permanent home for
  design docs the team wants in history), remove the corresponding line from
  `.gitignore` and `git add` them deliberately at that time.
- `.tmp_repos/` should probably never be un-ignored — it's explicitly scratch
  clones of third-party repos for local reference.
- `interview.txt` looks entirely unrelated to this project; the repo owner
  should consider deleting it outright (out of scope here — this plan only
  prevents accidental commit).
