# Plan 018: Ship the MIT license the package already claims

> **Executor instructions**: This plan was written outside the qa-skills repo (in Marco's portfolio
> repo) on 2026-10-08, against qa-skills `main` at v2.8.0. Copy it to `plans/` under the next free number
> (018 at time of writing) and add a row to `plans/README.md`. Read it fully first. It is a small, single
> PR. Do not change any installed file under `.claude/`, `adapters/` or `bin/`.

## Status

- **Priority**: P1. It blocks making the repo public and publishing to npm.
- **Effort**: S
- **Depends on**: nothing
- **Planned at**: 2026-10-08

## Why this matters

The package says it is MIT in two places but never ships the license:

- `package.json` → `"license": "MIT"`
- `README.md` → the license badge (line 15) and the `## License` section (line ~398) both link to
  `LICENSE`, and the section says "[MIT](LICENSE) — use it, fork it, improve it."
- **There is no `LICENSE` file in the repo.** `npm pack --dry-run` lists 39 files and none is a license.

Consequences:

1. **The README link is broken**: it 404s on GitHub.
2. **The terms are unclear.** The MIT grant is the license *text*, with its copyright line. Without it,
   users can't rely on the permission, and the "keep this notice" condition has no notice to keep.
   That's the very condition that makes copies carry the author's name.
3. **GitHub shows no license** in the sidebar or API (`license: null`), which puts some users and
   companies off adopting it, and some directories won't list it.

Every comparable QA skill pack (petrkindlmann/qa-skills, PramodDutta/qaskills, neonwatty/qa-skills,
QAIA, …) ships an MIT `LICENSE`. See the competitor scan in the portfolio repo,
`docs/research/qa-skills-competitors.md`.

## Steps

### 1. Branch from `main`

```bash
git switch main && git pull
git switch -c fix/add-license-file
```

(At planning time the working copy was on `docs/coverage-and-plan-statuses`. Don't stack on it.)

### 2. Add `LICENSE` at the repo root

The standard MIT text, verbatim (SPDX `MIT`), with this copyright line:

```text
MIT License

Copyright (c) 2026 Marco Amaral

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- **Year 2026**: the first commit is 2026-03-24. Don't write a range or "present".
- **Holder "Marco Amaral"**, the same name used in the README ("Built by Marco Amaral").
- Plain text, LF line endings (`.gitattributes` already enforces `eol=lf`). The file name is exactly
  `LICENSE`, with no extension, so GitHub's license detector and npm both pick it up.

### 3. Leave everything else alone

- **`package.json`**: no change. `"license": "MIT"` is already right, and npm **always** includes a root
  `LICENSE` in the tarball whatever `"files"` says. Don't add it to `"files"`.
- **`.npmignore`**: no change (it doesn't exclude LICENSE, and couldn't).
- **README**: no change. The existing links start resolving once the file exists.
- **Installers / manifest / known hashes**: no change. `init` copies `.claude/` content into projects,
  not the root LICENSE, so `.qa-skills-known-hashes` and the conformance suite aren't affected.

### 4. Check that nothing third-party needs attribution

MIT only covers what Marco wrote. Confirm nothing shipped was copied from another project:

```bash
git ls-files .claude bin adapters | xargs grep -n -i -E "copyright|licensed under|adapted from|source:|credit" || echo "none"
```

At planning time this found no third-party notices in shipped files. `.tmp_repos/` (local clones of
`superpowers` and `multica-agent-tools`) is gitignored and not tracked. **STOP** if the check finds
copied third-party content: list it for Marco instead of guessing. The fix is a `NOTICE` /
third-party section, which needs his decision.

### 5. Commit

One atomic commit, per `CONTRIBUTING.md` and commitlint:

```text
fix: ship the MIT LICENSE file the package already declares
```

Why `fix:` and not `chore:`/`docs:`: the published tarball changes (users gain the license file),
and it fixes a broken README link and a declared-but-missing license. CONTRIBUTING reserves
`feat:`/`fix:` for changes that reach installers, and this one does. Release Please will cut a patch
release. If Marco prefers no release for it, use `chore:` and the file ships with the next release.

### 6. PR

Title the same as the commit (the `pr-title.yml` workflow checks it). Body: what's missing, the
consequences above, and the verification output below. Don't edit `CHANGELOG.md` or the version.

## Verification (all must pass; paste the output in the PR)

```bash
test -f LICENSE && head -3 LICENSE                  # "MIT License" / blank / "Copyright (c) 2026 Marco Amaral"
file LICENSE                                         # ASCII text (no "with CRLF line terminators")
npm pack --dry-run 2>&1 | grep -E "LICENSE|total files"   # LICENSE listed; total files 40 (was 39)
git ls-files .claude bin adapters | wc -l            # unchanged from main
bash tests/conformance/run.sh                        # all cases still pass
```

After merge (only once the repo is public, otherwise the API can't detect it):

```bash
gh api repos/MarcoAmaral/qa-skills --jq .license.spdx_id   # MIT
```

## STOP conditions

- Third-party content found in step 4 → stop, report it, don't add a NOTICE on your own.
- `npm pack` doesn't list LICENSE → stop. Something in packaging config is unusual; report it rather
  than working around it with `"files"`.
- Any conformance case fails → stop. This change must not touch install behavior.

## Out of scope (separate decisions for Marco)

- **The name clash**: "qa-skills" is also the unscoped npm package `qa-skills` (AZANIR, GPL-3.0) and two
  other GitHub repos. Whether to rebrand before the public launch is a positioning decision, not part
  of this plan.
- **Flipping the repo to public and `npm publish`**: these come after this plan and after a secrets scan
  of the full history.
- **Author attribution inside skill files** (e.g. an `author:` field in SKILL.md frontmatter) so copies
  carry the name. Optional, and it touches installed files and their hashes, so it needs its own plan.
