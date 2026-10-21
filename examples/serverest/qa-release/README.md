# Example: `qa-release` on ServeRest 3.2.2

The `qa-release` skill asked whether the ServeRest API at `https://serverest.dev` is ready to release, using the evidence the earlier examples left on it.

```text
qa-release/
├── README.md
├── run-output.txt              # the cart API tests, re-run on 2026-10-18 (list reporter)
└── release/
    └── go-no-go-3.2.2.md       # the record
```

## Prompt

```text
Is ServeRest API 3.2.2 at https://serverest.dev ready to release? Use the evidence in examples/serverest/ (qa-static, qa-agentic, qa-automate) and write the go/no-go record to release/go-no-go-3.2.2.md
```

## Run details

| Item | Value |
| ---- | ----- |
| Date | 2026-10-18 |
| Package version | 4.0.1 plus unreleased changes |
| Skill followed | `qa-release`, with the gate in `qa-plan` Quality Gates |
| Candidate | ServeRest API 3.2.2, the `version` the service returns at its root URL |
| Model | An AI coding assistant following the skill file (Claude Sonnet 5.5, `claude-sonnet-5-5`) |
| Tooling | Node v24.16.0, `@playwright/test` 1.64.1 |

The cart API tests from [`../qa-automate/`](../qa-automate/) were run again on the date above, unchanged, so the evidence names the 2026-10-18 build. Result, from [`run-output.txt`](run-output.txt): **15 passed, 1 failed** in 34.0 seconds, the same as on 2026-10-08. The failure is again TC-CART-030.

## Result

**NO-GO.** All seven criteria of the standard exit criteria are not met, and no one decided: there is no stakeholder.

- There is no gate. None of the 33 cases carries `@gate`, so the record says the gate cannot be evaluated as defined.
- 3 of the 8 `@p0` cases and 11 of the 18 `@p1` cases were run. 17 of the 33 cases were never run.
- TC-CART-030 failed. It is tagged `@p2`, so it does not fail the P1 criterion. The defect behind it (SR-005) has no severity because no defect report was written, and the record does not turn a finding's rating into one.

## Honest limits

- **The skill was run by the assistant that wrote the example**, not by a separate reader, so nothing here shows that a reader who did not write the skill would produce the same record.
- **The gate is the standard exit criteria, taken as written.** Some do not fit an API practice service (supported browsers, QA Lead and Product Owner). The record marks each one N/A and keeps the row, and does not drop a criterion the skill was given.
- **No build identifier exists.** A public service shows a version, not a build. The record says so and uses the version; a team with a deploy log would cite that.
- **Nothing was decided or accepted.** The recommendation has no one to receive it. The record states that and invents no stakeholder.
- **The evidence is old.** The cases and the review date from 2026-10-08; only the 16 tests were re-run. The other 17 cases have no run at all, on any date.
- **Counts were read from the case tags** by hand and cross-checked: 8 + 18 + 7 = 33.
- **Shared public service.** A run on another day can fail for reasons outside the suite.
- **Scratch-path redaction.** `run-output.txt` is the real output with the temporary directory replaced by `<run-dir>`.
