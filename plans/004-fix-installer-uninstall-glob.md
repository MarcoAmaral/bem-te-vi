# Plan 004: Fix installer uninstall to remove all agent/command files, not a hardcoded list

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat 81858a7..HEAD -- install.sh install.ps1`
> If either file changed since this plan was written, compare the "Current
> state" excerpts against the live file before proceeding; on a mismatch,
> treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: S
- **Risk**: LOW
- **Depends on**: plan 003 (the multi-agent pipeline agents that exposed this bug) — already merged at commit `81858a7`
- **Category**: bug
- **Planned at**: commit `81858a7`, 2026-07-30

## Why this matters

`install.sh`'s and `install.ps1`'s `claude` uninstall branch (`uninstall_from_editor` /
`Uninstall-ForEditor`) delete commands and agents by a **hardcoded filename
list** instead of removing everything under `commands/` and `agents/`. This
was invisible while `qa-engineer.md` was the only agent and the command list
happened to stay in sync by luck, but it is now a confirmed, reproduced bug:
after plan 003 added `qa-groomer.md`, `qa-designer.md`, `qa-writer.md`, and
`qa-agentic.md`, running `./tests/test-lifecycle.sh`'s uninstall test leaves
the three new agent files behind in `<project>/.claude/agents/`, the
directory never empties, and the uninstall's "cleanly purged all files and
empty directories" guarantee is broken. Any real user who installs this
package via `install.sh`/`install.ps1` and later uninstalls it will have
stale agent files left in their project or global `.claude/` forever. The
list is also independently stale today — it still references the
already-removed `qa-ado.md` (harmless with `rm -f`/`Test-Path` guards, but a
symptom of the same drift problem).

## Current state

- `install.sh`, function `uninstall_from_editor`, `claude)` case,
  lines 517–547 (current, post-merge):

  ```bash
  claude)
      local TARGET_DIR="$BASE_DIR/.claude"
      echo -e "${CYAN}  Removing Claude Code files...${NC}"

      # Delete Rules
      rm -f "$TARGET_DIR"/rules/testing-guidelines.md "$TARGET_DIR"/rules/code-style-qa.md "$TARGET_DIR"/rules/accessibility-qa.md "$TARGET_DIR"/rules/security-qa.md 2>/dev/null || true

      # Delete Commands
      rm -f "$TARGET_DIR"/commands/qa.md "$TARGET_DIR"/commands/qa-cases.md "$TARGET_DIR"/commands/qa-defect.md "$TARGET_DIR"/commands/qa-bdd.md "$TARGET_DIR"/commands/qa-ado.md "$TARGET_DIR"/commands/qa-automate.md "$TARGET_DIR"/commands/qa-refinement.md "$TARGET_DIR"/commands/qa-tdd.md 2>/dev/null || true

      # Delete Skills
      rm -f "$TARGET_DIR"/skills/qa-plan/SKILL.md "$TARGET_DIR"/skills/qa-explore/SKILL.md 2>/dev/null || true

      # Delete Agents
      rm -f "$TARGET_DIR"/agents/qa-engineer.md 2>/dev/null || true

      # Delete Hooks
      rm -f "$TARGET_DIR"/hooks/validate-tc-format.sh 2>/dev/null || true

      # Clean up directories if empty
      if [ -d "$TARGET_DIR/rules" ]; then rmdir "$TARGET_DIR/rules" 2>/dev/null || true; fi
      if [ -d "$TARGET_DIR/commands" ]; then rmdir "$TARGET_DIR/commands" 2>/dev/null || true; fi
      if [ -d "$TARGET_DIR/skills/qa-plan" ]; then rmdir "$TARGET_DIR/skills/qa-plan" 2>/dev/null || true; fi
      if [ -d "$TARGET_DIR/skills/qa-explore" ]; then rmdir "$TARGET_DIR/skills/qa-explore" 2>/dev/null || true; fi
      if [ -d "$TARGET_DIR/skills" ]; then rmdir "$TARGET_DIR/skills" 2>/dev/null || true; fi
      if [ -d "$TARGET_DIR/agents" ]; then rmdir "$TARGET_DIR/agents" 2>/dev/null || true; fi
      if [ -d "$TARGET_DIR/hooks" ]; then rmdir "$TARGET_DIR/hooks" 2>/dev/null || true; fi
      if [ -d "$TARGET_DIR" ]; then rmdir "$TARGET_DIR" 2>/dev/null || true; fi

      echo -e "${GREEN}  ✓ Claude Code ($SCOPE): uninstalled.${NC}"

      # Purge Git Hook
      purge_git_hook "$SCOPE" "$BASE_DIR"
      ;;
  ```

  Also, `install.sh` line 862 (informational summary text, unrelated
  function further down the file):

  ```bash
  echo "              :   - Agents: agents/qa-engineer.md"
  ```

- `install.ps1`, function `Uninstall-ForEditor`, `'claude'` case,
  around lines 419–462 (current, post-merge):

  ```powershell
  'claude' {
      $targetDir = Join-Path $BaseDir '.claude'
      Write-Info "Removing Claude Code files..."

      # Delete Rules
      $rules = @('testing-guidelines.md', 'code-style-qa.md', 'accessibility-qa.md', 'security-qa.md')
      foreach ($r in $rules) {
          $file = Join-Path $targetDir "rules\$r"
          if (Test-Path $file) { Remove-Item -Path $file -Force }
      }

      # Delete Commands
      $cmds = @('qa.md', 'qa-cases.md', 'qa-defect.md', 'qa-bdd.md', 'qa-ado.md', 'qa-automate.md', 'qa-refinement.md', 'qa-tdd.md')
      foreach ($c in $cmds) {
          $file = Join-Path $targetDir "commands\$c"
          if (Test-Path $file) { Remove-Item -Path $file -Force }
      }

      # Delete Skills
      $skills = @('qa-plan\SKILL.md', 'qa-explore\SKILL.md')
      foreach ($s in $skills) {
          $file = Join-Path $targetDir "skills\$s"
          if (Test-Path $file) { Remove-Item -Path $file -Force }
      }

      # Delete Agents
      $file = Join-Path $targetDir "agents\qa-engineer.md"
      if (Test-Path $file) { Remove-Item -Path $file -Force }

      # Delete Hooks
      $file = Join-Path $targetDir "hooks\validate-tc-format.sh"
      if (Test-Path $file) { Remove-Item -Path $file -Force }

      # Clean up directories
      $dirs = @(
          "rules", "commands",
          "skills\qa-plan", "skills\qa-explore", "skills",
          "agents", "hooks"
      )
      foreach ($d in $dirs) {
          ...
      }
  }
  ```

  Also `install.ps1` line ~985 (informational summary text, same pattern as
  `install.sh` line 862):

  ```powershell
  Write-Host "              :   - Agents: agents\qa-engineer.md"
  ```

- **Rules, skills, and hooks are NOT part of this bug** — those subdirectories
  each only ever contain a fixed, small set of files that happen to already
  match the hardcoded lists (4 rules, 2 skills, 1 hook), and none of plans
  001–003 added new files to `rules/`, `skills/`, or `hooks/`. Do not convert
  those to globs — that would be unrequested scope expansion. Only
  `commands/` and `agents/` are affected because plans 001 and 003 added new
  files there that the hardcoded lists don't know about.
- `.claude/commands/` currently contains: `qa.md`, `qa-cases.md`,
  `qa-defect.md`, `qa-bdd.md`, `qa-automate.md`, `qa-refinement.md`,
  `qa-tdd.md`, `qa-agentic.md` (8 files, verify with `ls .claude/commands/`).
- `.claude/agents/` currently contains: `qa-engineer.md`, `qa-groomer.md`,
  `qa-designer.md`, `qa-writer.md` (4 files, verify with `ls .claude/agents/`).
- `./tests/test-lifecycle.sh` and `./tests/test-lifecycle.ps1` are the
  existing integration tests that exercise install → verify → uninstall →
  verify-clean. They currently FAIL (bash version confirmed; PowerShell
  version not run in this Linux environment, but shares the identical bug
  pattern in `install.ps1`) because of exactly this bug. **Do not modify the
  test scripts** — fixing the installer should make them pass as-is; if a
  test script itself needs a change to pass, that means the fix is wrong or
  the test has an unrelated pre-existing issue — STOP and report, don't edit
  the test to make it pass.

## Commands you will need

| Purpose | Command | Expected on success |
| --- | --- | --- |
| Bash lint | `shellcheck install.sh` | exit 0, no new warnings vs. baseline (compare to `git stash` version if unsure) |
| PowerShell lint | `pwsh -Command "Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser; Invoke-ScriptAnalyzer -Path install.ps1"` (only if `pwsh` is available in this environment — if not, skip and note it; CI's Windows runner covers this) | no `Error` severity results |
| Bash integration test | `./tests/test-lifecycle.sh` | exits 0, ends "ALL INTEGRATION TESTS PASSED SUCCESSFULLY! 100% GREEN" |
| PowerShell integration test | `pwsh ./tests/test-lifecycle.ps1` (only if `pwsh` available — if not, note it as unverified locally; CI's Windows runner will catch regressions) | exits 0 |

## Scope

**In scope** (the only files you should modify):

- `install.sh`
- `install.ps1`

**Out of scope** (do NOT touch, even though they look related):

- `tests/test-lifecycle.sh`, `tests/test-lifecycle.ps1` — these should pass
  unmodified once the installer is fixed; do not edit them to work around
  a still-broken installer.
- `bin/cli.js` — separate installer path, does not have this bug (it copies/
  removes whole directories, not individual filenames — see `cmdInit`/
  `cmdUnlink` in that file). Do not touch it.
- `rules/`, `skills/`, `hooks/` deletion logic in either installer — not
  affected by this bug, leave as fixed lists (see "Current state" note above).
- `install.ps1`'s `$installedFiles.Add(...)` list used during install-time
  manifest tracking (around line 905–913) — this is a **different, install-time**
  hardcoded list (not the uninstall path this plan targets) that has the
  same underlying "drifts when new files are added" class of bug, but fixing
  it requires understanding how `$installedFiles` is consumed elsewhere in
  the script, which is a separate investigation. Do not touch it in this
  plan — note it in your NOTES for a possible follow-up plan instead.

## Git workflow

- Branch: `fix/installer-uninstall-glob`.
- Two commits (one per file, since they're independent fixes to the same
  bug class in two different scripts — not "loads of diffs", just one
  logical change expressed twice):
  1. `fix: uninstall all commands/agents in install.sh instead of a fixed list`
  2. `fix: uninstall all commands/agents in install.ps1 instead of a fixed list`
- Do NOT push or open a PR unless the operator instructed it.

## Steps

### Step 1: Fix `install.sh`'s command/agent deletion

In `install.sh`, inside `uninstall_from_editor`'s `claude)` case, replace the
two hardcoded `rm -f` lines for Commands and Agents with globs that remove
every file in each subdirectory rather than naming files individually:

Replace:

```bash
            # Delete Commands
            rm -f "$TARGET_DIR"/commands/qa.md "$TARGET_DIR"/commands/qa-cases.md "$TARGET_DIR"/commands/qa-defect.md "$TARGET_DIR"/commands/qa-bdd.md "$TARGET_DIR"/commands/qa-ado.md "$TARGET_DIR"/commands/qa-automate.md "$TARGET_DIR"/commands/qa-refinement.md "$TARGET_DIR"/commands/qa-tdd.md 2>/dev/null || true
```

with:

```bash
            # Delete Commands (glob — avoids drift when new qa-*.md commands are added)
            rm -f "$TARGET_DIR"/commands/qa*.md 2>/dev/null || true
```

Replace:

```bash
            # Delete Agents
            rm -f "$TARGET_DIR"/agents/qa-engineer.md 2>/dev/null || true
```

with:

```bash
            # Delete Agents (glob — avoids drift when new qa-*.md agents are added)
            rm -f "$TARGET_DIR"/agents/qa-*.md 2>/dev/null || true
```

Do not change the Rules, Skills, or Hooks deletion lines, and do not change
the directory-cleanup (`rmdir`) block below them — it already works
correctly once the files are gone.

Also update the informational line at (originally) line 862 from:

```bash
                echo "              :   - Agents: agents/qa-engineer.md"
```

to:

```bash
                echo "              :   - Agents: agents/qa-engineer.md, agents/qa-groomer.md, agents/qa-designer.md, agents/qa-writer.md"
```

**Verify**: `grep -n "qa-engineer.md\"" install.sh` — confirm the old
single-file hardcoded `rm -f` pattern for agents no longer exists (only the
informational echo line and the glob should remain). `bash -n install.sh` →
exits 0 (syntax check).

### Step 2: Fix `install.ps1`'s command/agent deletion

In `install.ps1`, inside `Uninstall-ForEditor`'s `'claude'` case, replace the
hardcoded `$cmds` array + loop and the single-agent `Remove-Item` with glob
-based removal using `Get-ChildItem -Filter`:

Replace:

```powershell
            # Delete Commands
            $cmds = @('qa.md', 'qa-cases.md', 'qa-defect.md', 'qa-bdd.md', 'qa-ado.md', 'qa-automate.md', 'qa-refinement.md', 'qa-tdd.md')
            foreach ($c in $cmds) {
                $file = Join-Path $targetDir "commands\$c"
                if (Test-Path $file) { Remove-Item -Path $file -Force }
            }
```

with:

```powershell
            # Delete Commands (glob — avoids drift when new qa-*.md commands are added)
            $cmdsDir = Join-Path $targetDir "commands"
            if (Test-Path $cmdsDir) {
                Get-ChildItem -Path $cmdsDir -Filter "qa*.md" -File | Remove-Item -Force
            }
```

Replace:

```powershell
            # Delete Agents
            $file = Join-Path $targetDir "agents\qa-engineer.md"
            if (Test-Path $file) { Remove-Item -Path $file -Force }
```

with:

```powershell
            # Delete Agents (glob — avoids drift when new qa-*.md agents are added)
            $agentsDir = Join-Path $targetDir "agents"
            if (Test-Path $agentsDir) {
                Get-ChildItem -Path $agentsDir -Filter "qa-*.md" -File | Remove-Item -Force
            }
```

Do not change the Rules, Skills, or Hooks deletion blocks, and do not change
the `$dirs` cleanup loop below — it already works once the files are gone.

Also update the informational line at (originally) around line 985 from:

```powershell
                    Write-Host "              :   - Agents: agents\qa-engineer.md"
```

to:

```powershell
                    Write-Host "              :   - Agents: agents\qa-engineer.md, agents\qa-groomer.md, agents\qa-designer.md, agents\qa-writer.md"
```

**Verify**: `grep -n "qa-engineer.md" install.ps1` — confirm the old
`$file = Join-Path $targetDir "agents\qa-engineer.md"` hardcoded single-file
pattern no longer exists (only the informational `Write-Host` line and the
new `Get-ChildItem`/glob block should remain). If `pwsh` is available:
`pwsh -Command "Get-Content install.ps1 | Out-Null; [System.Management.Automation.Language.Parser]::ParseFile('install.ps1', [ref]$null, [ref]$null) | Out-Null; echo 'PARSE OK'"`
→ prints `PARSE OK` (syntax check). If `pwsh` is not available in this
environment, skip this specific check and say so in NOTES — do not treat it
as a failure.

### Step 3: Run the integration test suite

Run `./tests/test-lifecycle.sh`. This is the actual regression test for this
bug — it must now pass since the test creates a sandbox project, installs,
lists `.claude/agents/` (which will have all 4 agent files after plan 003),
uninstalls, and asserts the directory is fully gone.

**Verify**: exits 0, output ends "ALL INTEGRATION TESTS PASSED SUCCESSFULLY!
100% GREEN". If it still fails, re-read the failure output carefully — do
not assume Step 1 is correct just because it looks right; the previous
failure mode was specifically "`.claude` folder still exists in project"
after uninstall, so check for exactly that symptom being gone.

If `pwsh` is available, also run `pwsh ./tests/test-lifecycle.ps1` and
confirm it exits 0. If `pwsh` is not available, note this in NOTES — it is
not a STOP condition, just an unverified-locally caveat (CI's
`test-windows` job in `.github/workflows/ci.yml` covers this).

## Test plan

No new test file is needed — `./tests/test-lifecycle.sh` (bash) and
`./tests/test-lifecycle.ps1` (PowerShell) already exercise exactly this bug
end-to-end (install → verify 4 agent files present → uninstall → verify
`.claude/` fully removed) and currently fail specifically because of it.
Making them pass, unmodified, is the verification for this plan.

## Done criteria

Machine-checkable. ALL must hold:

- [ ] `grep -n 'rm -f "\$TARGET_DIR"/agents/qa-engineer.md'` in `install.sh` returns no matches (old hardcoded line gone)
- [ ] `grep -n 'qa-engineer.md"' install.ps1` inside the uninstall function's old `$file = Join-Path ...` form returns no matches (old hardcoded line gone)
- [ ] `bash -n install.sh` exits 0
- [ ] `./tests/test-lifecycle.sh` exits 0 and prints "ALL INTEGRATION TESTS PASSED SUCCESSFULLY! 100% GREEN"
- [ ] `shellcheck install.sh` exits 0
- [ ] `git status --porcelain` shows only `install.sh` and `install.ps1` modified
- [ ] `plans/README.md` status row for 004 updated to DONE

## STOP conditions

Stop and report back (do not improvise) if:

- `./tests/test-lifecycle.sh` still fails after Step 1 — re-check whether
  the glob pattern actually matches all files in `.claude/commands/` and
  `.claude/agents/` as currently populated (`ls .claude/commands/
  .claude/agents/` and compare against the glob by hand:
  `echo .claude/commands/qa*.md` / `echo .claude/agents/qa-*.md`).
- Any file under `.claude/rules/`, `.claude/skills/`, or `.claude/hooks/`
  needs to change for the test to pass — that would mean the bug is
  somewhere other than where this plan expects; stop and report.
- Fixing this requires editing `tests/test-lifecycle.sh` or
  `tests/test-lifecycle.ps1` — those are out of scope; a passing installer
  should make the existing, unmodified tests pass.

## Maintenance notes

- `install.ps1`'s `$installedFiles` tracking list (around line 905–913,
  used during install to build a manifest/summary) has the same underlying
  "hardcoded list drifts when files are added" problem, but in the opposite
  direction (install-time, not uninstall-time) and is out of scope for this
  plan (see "Out of scope" above). Worth a follow-up plan if new agents/
  commands keep being added.
- Any future new file added under `.claude/commands/` or `.claude/agents/`
  will now be picked up automatically by both uninstallers' globs — no
  further installer changes needed when future pipeline stages or commands
  are added, as long as they follow the existing `qa*.md`/`qa-*.md` naming
  convention already used by every file in those directories.
