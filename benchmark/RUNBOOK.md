# Runbook: collecting a benchmark run

`METHODOLOGY.md` says what is measured and why. This file says how to collect it, step by step, so a
collection session needs no decisions: a decision made in the middle of a collection is how bias
gets in. Anything that cannot be done as written here is a dated entry in `DEVIATIONS.md`, not an
improvisation.

## What you need

- Claude Code with `claude plugin eval` (2.1.291 was used for the pilot), signed in with the account
  that pays for the run, and `git` 2.31 or later.
- Node.js 18 or later for the scripts (standard library only).
- A clean checkout of the commit that carries the frozen methodology, with nothing modified
  (`git status` empty).
- A scratch folder **outside** the repository for the tool's output; the commands below call it
  `$OUT`.
- The cost cap for this collection, decided before starting (`METHODOLOGY.md`, "Cost").

## 1. Before the first run

```bash
node benchmark/build.js --check          # graders, placebo and the frozen digest
node benchmark/analysis/analyze.js --self-test
node benchmark/build.js                  # writes benchmark/cases/ (ignored by git)
```

The digest `build.js` prints must equal `benchmark/cases.sha256`. If it does not, stop: the cases are
not the frozen ones.

Record the state of the Claude Code install, so you can show afterwards that nothing was installed:

```bash
claude plugin list > "$OUT/plugin-list-before.txt"
claude plugin marketplace list > "$OUT/marketplace-list-before.txt"
sha256sum ~/.claude/settings.json ~/.claude/plugins/installed_plugins.json \
  ~/.claude/plugins/known_marketplaces.json > "$OUT/sha-before.txt"
```

## 2. Collect

Run from the repository root, one task at a time, so that a cost ceiling can only ever cut whole
tasks and never a condition (the tool runs cases in name order, and the condition is the first
letter of the name):

```bash
for t in cases-quantity cases-order-status cases-shipping-fee defect-gift-card plan-split-payment \
         api-orders-contract a11y-signup-form flaky-run-history bdd-loyalty-points; do
  claude plugin eval . --eval-dir benchmark/cases --case "*-$t" --ablation none \
    --runs <runs per cell> --model claude-haiku-4-5-20251001 \
    --judge-model claude-haiku-4-5-20251001 --trust-plugin --no-publish --keep-temp \
    --max-cost-usd <what is left of the cap> -j 2 --output-dir "$OUT/$t"
done
```

- `--ablation none`: every case names its own plugin (`plugins:` in its `prompt.md`), so the tool's
  extra no-plugin arm is not wanted.
- `--keep-temp`: the traces are needed for the final replies, the model string and the files read.
- `--no-publish`: the report stays local.
- Keep a running total of each task's `costUsd` (in its `aggregate-result.json`) and lower
  `--max-cost-usd` for the next task to what is left. Stop when what is left would not cover a task.

Do not re-run a single case because its result looks wrong. A run that ended on an API error
(`error` set, score 0) is re-collected once, in a new invocation, and the re-collection is a line in
`DEVIATIONS.md`.

## 3. Extract, redact and analyse

From the repository root, with the aggregates in task order:

```bash
node benchmark/analysis/extract.js --out benchmark/results/<date> \
  "$OUT"/cases-quantity/aggregate-result.json "$OUT"/cases-order-status/aggregate-result.json ...
```

`<date>` is the collection date, with `-pilot` appended for a pilot. The folder then holds
`runs.jsonl`, one Markdown file per generation under `outputs/`, and each redacted aggregate under
`aggregate/`. Then:

```bash
node benchmark/analysis/analyze.js benchmark/results/<date> > benchmark/results/<date>/analysis.md
grep -rnE '/tmp/|/home/|/Users/|/mnt/|@[A-Za-z0-9-]+\.(com|net|org|io|dev)' benchmark/results/<date>
```

`extract.js` already refuses to finish when a local path survives; the `grep` is a second look, and
any address it prints must be one of the fixtures' reserved `.example` addresses or not be there.

## 4. After the last run

```bash
claude plugin list | diff "$OUT/plugin-list-before.txt" -
claude plugin marketplace list | diff "$OUT/marketplace-list-before.txt" -
sha256sum -c "$OUT/sha-before.txt"
```

All three must report no difference. Then delete the kept temporary folders (`kept temp:` lines in
the tool's output; they are read-only, so `chmod -R u+w` them first).

## 5. Read before you publish

Open a sample of the outputs for every task and condition and check the grader verdicts against
them by eye. A verdict that is wrong is a grader defect: record it in `DEVIATIONS.md` with the
output that showed it. After the methodology is frozen, a defective grader is **not** fixed and
re-scored silently; the analysis is reported as collected, and a corrected re-score, if any, is
reported beside it and labelled as such.

## 6. Publish

Commit the results folder, then update the README's "Does it work?" table from `analysis.md`, with
the date, the model string, the number of runs per cell, the measured cost and a link to the results.

## Arm 2 and the human review

Arm 2 is collected only after its amendment to `METHODOLOGY.md` is committed (the project folder, the
invocation, the capture). The blind human review is drawn with:

```bash
node benchmark/analysis/blind.js benchmark/results/<date> "$OUT/review" "$OUT/review-key"
```

The review folder goes to the judge; the key folder stays outside the repository until every
review sheet is back, then both are committed under `benchmark/results/<date>/review/`.
