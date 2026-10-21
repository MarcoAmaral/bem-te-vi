# Example: `qa-api` on the ServeRest cart and login, and on a public GraphQL API

The skill's five steps on the same slice the other ServeRest examples use (cart and login), plus its GraphQL half on the public countries API. Playwright API tests (the `request` fixture, no browser) that validate each response **body** against the published OpenAPI schema, not only the status.

```text
qa-api/
├── package.json
├── playwright.config.ts
├── run-output.txt                              # the real run, list reporter
├── mutation-output.txt                         # two assertions made to fail on purpose
├── api-tests/
│   ├── contract.md                             # step 1: the contract, its version, the auth model
│   ├── design.md                               # step 2: cases, techniques, contract strategy (step 5)
│   ├── conformance.md                          # step 3: every mismatch, classified
│   └── graphql/
│       ├── contract.md
│       └── conformance.md
└── playwright/
    ├── api/ServeRestApi.ts                     # actions only, no assertions
    ├── contract/contract.ts                    # loads the OpenAPI document once; returns schema errors, never asserts
    ├── fixtures/serverest.ts                   # per-test admin, customer and products, cleaned up afterwards
    └── tests/
        ├── cart-contract.api.spec.ts
        ├── login-contract.api.spec.ts
        └── countries-graphql.api.spec.ts
```

## Prompt

```text
Use the qa-api skill to test the cart and login routes of https://serverest.dev against its OpenAPI document at https://serverest.dev/swagger.json, and run the skill once against the public GraphQL API https://countries.trevorblades.com/ (read-only). Re-check findings SR-001 and SR-005 from examples/serverest/qa-static/review.md as conformance mismatches.
```

## Run details

| Item | Value |
| ---- | ----- |
| Date | 2026-10-18 |
| Package version | 4.0.1 plus the unreleased `qa-api` skill (branch `feat/qa-api-skill`) |
| Files followed | `.claude/skills/qa-api/SKILL.md`, `.claude/rules/context-discovery.md`, `code-style-qa.md`, `test-evidence.md` |
| Model | An AI coding assistant following the skill (Claude Sonnet 5.5, `claude-sonnet-5-5`) |
| Tooling | Node v24.16.0, `@playwright/test` 1.64.1, `ajv` 8.20.0, `graphql` 16.14.2, TypeScript 5.9.3 |

## ServeRest's Portuguese

Its messages, paths and field names are quoted verbatim, because the tests compare against what the server returns. See the glossary in [`../qa-automate/README.md`](../qa-automate/README.md); added here: `não pode ficar em branco` is "cannot be blank", `produtos não contém 1 valor obrigatório` is "produtos does not contain 1 required value", `deve ser um array` is "must be an array".

## Result of the real run

From [`run-output.txt`](run-output.txt): **21 cases, 16 passed, 5 failed**, in 29.5 seconds.

| Part | Cases | Passed | Failed |
| ---- | ----- | ------ | ------ |
| REST: cart | 12 | 8 | 4 (API-CART-09, 10, 11, 12) |
| REST: login | 3 | 2 | 1 (API-LOGIN-03) |
| GraphQL: countries | 6 | 6 | 0 |

Each of the five failures is a real mismatch between the published schema and the live API, left failing on purpose (not skipped, not marked as expected failures). [`api-tests/conformance.md`](api-tests/conformance.md) classifies them: SR-001 and SR-006 are still present as documentation drift, SR-005 as a software defect (seen on both the request and the stored data), and the `/login` 400 is a new finding. The check also surfaced its own limit: the schema declares no `required` keys, so a missing key conforms, and API-CART-12 had to assert the key directly.

## Success criteria, as written before the run

| Criterion | Met? |
| --------- | ---- |
| `contract.md` names the schema URL, fetch date and version, and how the deployed version was confirmed | Partly. URL, date and version are there; the deployed version could not be confirmed (no version route, no deployment record) and the file says so |
| `conformance.md` re-detects SR-001 and SR-005, classified | Yes |
| Specs validate bodies against the schema, run live, and leave nothing behind | Yes. After the run no user named "Contract test" and no product named "Contract test product" remained (queried through the API) |
| One assertion shown to be sensitive (red-green) | Yes, two. [`mutation-output.txt`](mutation-output.txt): in a throwaway copy the loaded schema was changed so `/login` 200 `authorization` is an `integer` and `GET /carrinhos/{_id}` `precoTotal` is a `string`. Both cases failed for the expected reason (`/authorization must be integer`, `/precoTotal must be string`). The mutation was two lines added to `Contract.load` in the copy (`document.components.schemas.loginComSucesso.properties.authorization.type = "integer"` and `document.components.schemas.getCarrinhosId.properties.precoTotal.type = "string"`); the copy is not kept here |
| `check-test-evidence.sh` runs clean | Yes: "clean (6 files)" |

To reproduce, copy the folder outside this repository and run `npm install` then `npm test`. Browsers are not needed.

## What this changed in the skill

- API-GQL-06 showed that a request that is not valid GraphQL syntax was answered **400** while a validation error was answered **200**. The skill's GraphQL section first said errors always arrive with 200; it now says "usually" and tells the tester to record what the service does.

## Honest limits

- **Dated, shared, unversioned.** Every live claim is from 2026-10-18. ServeRest and the countries API are public and can change; a failing run on another day may be a service change. Retries are off, one worker.
- **A rate limit exists.** An unrelated script fetching `swagger.json` from the same machine got HTTP 429 once while this work was being prepared. The suite itself was not rate limited.
- **The 5 failures are expected today, not permanent.** If the maintainer fixes the schema or the API, they will start to pass; that is the point of keeping them failing.
- **API-GQL-04 provokes a server error on purpose** (an uncompilable regular expression). It documents behaviour seen once; a server fix would make it fail for a good reason.
- **The slice is small.** 15 REST cases over 6 routes; no case for `concluir-compra`, expired tokens, idempotency or invalid transitions beyond "no cart". `design.md` lists them as not designed.
- **The contract is the live document, not a snapshot.** The specs fetch it on every run, so a schema change moves the tests. The SHA-256 in `contract.md` is of the copy read when the file was written.
- **The deployed version was not confirmed.** See `api-tests/contract.md`.
- **Scratch-path redaction.** The two output files are the real console output with one edit: the temporary directory was replaced by `<run-dir>`.
- **Evidence rule.** The specs take no screenshots or recordings; the checker was run and reported clean, which is expected for an API-only suite.
- **Types.** `tsc --noEmit --strict` passed on the specs and helpers (checked once, not part of `npm test`).
- **No schema fuzzing and no consumer-driven contracts.** Step 5 recommends schema checks for this provider and says why.
