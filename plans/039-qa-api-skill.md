# Plan 039: The `qa-api` skill (REST and GraphQL API testing, schema and contract checks)

> **Executor instructions**: This plan was approved on 2026-10-14 (see "Approval gate"). Work on `feat/qa-api-skill`:
> first the skill with its frontmatter check passing, then the README, then the worked example, then
> the dry run. One concern per commit. Run every verification command and read its output. If
> anything in "STOP conditions" occurs, stop and report. When done, update this plan's row in
> `plans/README.md`.
>
> **Drift check (run first)**: `git diff --stat a2f08e7..HEAD -- .claude/commands/qa.md .claude/commands/qa-static.md .claude/commands/qa-automate.md .claude/rules/context-discovery.md .claude/rules/testing-guidelines.md .claude/skills .claude-plugin generate-adapters.sh generate-adapters.ps1 README.md examples/README.md examples/serverest plans/034-*.md`
> A change to any of these since planning means a line reference below may be stale: re-read it
> before relying on it.

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: LOW (new shipped files; no installer, rule or existing command changes beyond the router)
- **Depends on**: plan 032 (self-contained tree; see "Known hashes"), plan 034 (where shared reference
  content lives; see Step 2), plan 019 phase 3 (frontmatter, merged), phase 11 (`examples/` layout)
- **Category**: feature (new shipped skill)
- **Planned at**: commit `a2f08e7` (`github/main`), 2026-10-14
- **Decided by Marco, 2026-10-14**: approved as planned; GraphQL is exercised against the public countries API (see "Approval gate").
- **Source**: plan 019 phase 13, row `qa-api`
- **Implemented**: in this private repository, before plan 020 part B's public cut-over

## Why this matters

API tests are where most of an automation suite's cheap, stable checks live (the `@api` level tag
exists for them, `testing-guidelines.md:76`), yet the package has no workflow for them. The evidence
is in the package's own example: running `/qa-automate` on ServeRest's cart cases produced an API
suite, and its honest limits say "**The command file is browser-first.** `qa-automate.md` describes
page objects, `data-testid` and an auth setup project. None of that applies to an API suite"
(`examples/serverest/qa-automate/README.md`, section "Honest limits"). The `/qa-static` example on
the same API found that the published OpenAPI schema contradicts the live API (SR-001: schema says
object, API requires an array; SR-005: a string `quantidade` is accepted with 201), but it had to
call the live API to find that, outside a static review (`examples/serverest/qa-static/README.md`,
"Not a pure static review").

What is missing is the dynamic half: checking that real responses conform to the declared contract,
designing per-endpoint tests from the contract with the techniques the package already teaches, and
deciding when a team needs consumer-driven contract tests rather than schema checks. The failure the
skill prevents is **a green API suite that asserts status codes only**, so a response that drifted
from its contract (renamed field, wrong type, missing error body) passes every test.

## Current state (overlap check)

What already exists, and so must be **referenced, not restated**:

| Need | Already covered by | Evidence |
| --- | --- | --- |
| Static review of an API schema (OpenAPI) before anything runs | `/qa-static` | `.claude/commands/qa-static.md:2` (description names "API schema"), `:10`, `:44` (technical review default for a schema), `:90` (interface-specification defects, CTFL §3.1.3) |
| Contracts as Tier 1 ground truth | `context-discovery.md` | `.claude/rules/context-discovery.md:21-22` ("OpenAPI/GraphQL/proto schemas") |
| Test design techniques (EP, BVA, decision table, state transition) | `testing-design.md` | `.claude/skills/qa-reference/references/testing-design.md` (rule pointer `testing-guidelines.md:57`) |
| `@api` level tag and its CTFL level | rule and reference | `testing-guidelines.md:76`; `testing-design.md:68` (`@api` → system or system integration testing) |
| Playwright conventions, AAA, no sleeps, isolation | `code-style-qa.md`, `automation-code.md` | `.claude/rules/code-style-qa.md`; `.claude/skills/qa-reference/references/automation-code.md:9-62` |
| `page.route` / `waitForResponse` for browser tests | `/qa-automate` | `.claude/commands/qa-automate.md:400-401`, `:506-513` |
| BOLA, CSRF, role escalation at the API | `security-checks.md` | `.claude/skills/qa-reference/references/security-checks.md:31-38`, `:104-116` |
| Tool choice (activity and category first) | `test-tools.md` | `.claude/rules/test-tools.md`; `references/test-tools.md:59-68` |

Measured gap (`grep -rn -i "graphql\|openapi\|contract\|schema" .claude --include=*.md`, run at
planning): no file covers response-vs-contract conformance, consumer-driven contract testing,
GraphQL operations, or API-specific test design (per-endpoint partitions, resource lifecycle as a
state machine, error-body contracts, idempotency). `/qa-automate`'s config, structure and examples
are browser-first (`qa-automate.md:26-84`, `:213-353`).

**Verdict: build, scoped.** Most of the *content* the skill needs exists; the *workflow* that ties
contract → design → conformance check → automation does not. The skill holds only the
API-specific parts and points to everything in the table above.

Package plumbing at planning time:

- Skills are discovered by folder: `generate-adapters.sh:69-91` appends every `SKILL.md` and its
  `references/*.md` (sorted) to the merged adapter; `.claude-plugin/plugin.json` lists
  `"./.claude/skills/"` as a folder, so the plugin needs no edit (CONTRIBUTING.md §4).
- `adapters/` is gitignored (`.gitignore:33-34`): regenerate and verify, never commit it.
- Every skill and reference is concatenated into every non-Claude adapter (~256 KB of sources today:
  `cat .claude/{rules,commands,agents}/*.md .claude/skills/*/SKILL.md .claude/skills/*/references/*.md | wc -c`).
  Size matters: target `SKILL.md` ≤ 10 KB (qa-migrate is 15.8 KB, qa-plan 18.7 KB).
- The router lists skills at `.claude/commands/qa.md:58-61` and routes at `:82-84`; the README lists
  them at `README.md:153` ("the four skills"), `:196-198`, `:442`; `examples/README.md:7-12` is the
  examples table.
- The installers' post-install hint names only `qa-plan` and `qa-explore` (`install.sh:1255`,
  `install.ps1:1411`): already stale, **out of scope** (installer file-safety area, CLAUDE.md §5).

## ISTQB CTFL v4.0.1 grounding

Verified against the official PDF `<local copy of ISTQB_CTFL_Syllabus_v4.0.1.pdf>`
(v4.0.1, 2024-09-15), by reading the section text, on 2026-10-14. Cite only these:

| Section | What it supports in the skill |
| --- | --- |
| §2.2.1 Test Levels | Component integration testing targets interfaces between components; system integration testing targets "the interfaces of the system under test and other systems and external services" and needs an environment "preferably similar to the operational environment". Frames which API tests are which level, and why a shared public instance is a constraint |
| §2.2.2 Test Types | Functional (correctness of what the endpoint does) and black-box testing "derives tests from documentation not related to the internal structure" — the contract is that documentation |
| §4.2.1 Equivalence Partitioning | Partitions can be identified for "interface parameters" among other things; per-field valid/invalid partitions of a request |
| §4.2.2 Boundary Value Analysis | Numeric and length limits declared (or missing) in the schema |
| §4.2.4 State Transition Testing | A resource's lifecycle (create → read → update → delete, cart open → completed/cancelled) as states and events, including invalid transitions |
| §5.1.7 Testing Quadrants | Q2 (business facing, support the team) lists "API testing" among tests that check acceptance criteria and can be manual or automated |
| §1.4.3 Testware | Stubs, drivers, simulators and service virtualizations are test environment items: the vocabulary for a mocked provider |
| §3.1.3 (via `/qa-static`) | Interface-specification defects (mismatched number, type or order of parameters) are found statically; the skill hands schema-only review to `/qa-static` |
| §6.1, §6.2 | Tool categories and risks when recommending a contract or schema tool |

**Not cited, because the syllabus does not say it:** contract testing, consumer-driven contracts,
schema validation, GraphQL, and idempotency. A search of the extracted text for "contract test",
"schema" and "graphql" returns nothing; "API testing" appears only at §4.3 (white-box techniques at
higher levels, "not discussed in this syllabus") and §5.1.7. The skill marks these as practice from
the sources below, not ISTQB content, exactly as `qa-migrate/SKILL.md:28` does for flakiness.

## Research basis

Read for scope, never copied. Headings and descriptions only were read on 2026-10-14:

- `petrkindlmann/qa-skills` (MIT): `skills/api-testing/SKILL.md` (165 lines: Playwright API testing,
  schema validation, response headers, anti-patterns) and `skills/contract-testing/SKILL.md` (204
  lines: Pact, broker, schema-first vs consumer-first, `can-i-deploy`).
- `QAIA-Project/QAIA` (MIT): `plugins/qaia-core/skills/openapi-ingest/SKILL.md`,
  `plugins/qaia-playwright/skills/contract-probe/SKILL.md` (probe documented behaviour with bounded,
  non-destructive inputs).

What this plan does differently: ties every check to the package's existing technique, tag and
evidence rules; treats a schema/API disagreement as a finding to report both ways (documentation
drift or software defect, `context-discovery.md:48`), not something to "fix" in the test; and makes
no tool the answer by default (`test-tools.md`).

## What the skill does

`.claude/skills/qa-api/SKILL.md`, a workflow in five steps, each leaving a file under `api-tests/`
so work resumes from disk:

| Step | Output | Notes |
| --- | --- | --- |
| 1. Find the contract | `api-tests/contract.md`: where the contract lives (OpenAPI, GraphQL SDL/introspection, proto, or none), its version, the deployed version under test (deployment record, `context-discovery.md:36-40`), auth model | No contract → say so and derive one from observed behaviour, marked as assumption |
| 2. Design per endpoint/operation | `api-tests/design.md`: per endpoint, partitions and boundaries per field, the resource state model, auth/role matrix, error contract | Techniques from `testing-design.md`; tags from the rule |
| 3. Conformance check | `api-tests/conformance.md`: each sampled real response validated against the declared schema; every mismatch classified | Read-only or throwaway data only on shared environments |
| 4. Automate | Specs using the runner's HTTP client (Playwright `request` fixture when the repo uses Playwright), helpers with actions only | Points to `code-style-qa.md`; API-specific structure only |
| 5. Contract strategy | One paragraph: schema checks are enough, or consumer-driven contracts are justified, and why | Recommendation follows `test-tools.md` order |

API-specific content that lives in the skill (the only new content):

- **Assert the body, not only the status.** Every test validates the response body against the
  contract's schema for that status, including error bodies. A 400 with the wrong error shape is a
  failure.
- **Mismatch triage.** Schema says X, API does Y: record both, classify as documentation drift or
  software defect per `context-discovery.md:48`, and never adjust the test until the owner decides
  (the ServeRest SR-001 and SR-005 cases are the worked examples).
- **Positive half too** (`testing-design.md:79`): a validation that rejects everything passes every
  negative test.
- **Resource lifecycle as state transitions**, including invalid ones (delete twice, update after
  delete, complete an empty cart).
- **Idempotency and retries**: `PUT`/`DELETE` repeated give the same state; a `POST` retried by a
  client does not duplicate (say whether the API promises this).
- **Auth matrix**: each endpoint × {no token, expired, other user's resource, wrong role}; the
  BOLA and escalation checks are `security-checks.md:31-34,104-116`, referenced, not restated.
- **GraphQL specifics**: errors arrive with HTTP 200 in an `errors` array, so status-only assertions
  are vacuous; partial data with errors; field-level nullability from the SDL; query depth/cost
  limits when the server declares them; introspection disabled in production is not a defect.
- **Shared-environment discipline**: unique names, clean-up, no writes to records the team marks
  read-only (`qa-plan` fixture set section, `.claude/skills/qa-plan/SKILL.md:192-203`).

## Commands you will need

| Purpose | Command | Expected |
| --- | --- | --- |
| Frontmatter | `./tests/test-frontmatter.sh` | exit 0, counts the new skill |
| Reference pointers | `./tests/test-reference-links.sh` | `✔ All N reference pointers resolve.` |
| Adapters | `./generate-adapters.sh --clean && ./tests/verify-adapters.sh` | exit 0; `grep -c "qa-api\|API Testing" adapters/universal/AGENTS.md` > 0 |
| Plugin | `./tests/plugin/verify-plugin.sh` | exit 0 |
| Known hashes | `./generate-known-hashes.sh --check` | exit 0, unchanged (new file is in no tag) |
| Lifecycle | `./tests/test-lifecycle.sh` | `100% GREEN` |
| Conformance | `./tests/conformance/run.sh` | exit 0 |
| Rules size | `./tests/test-rules-size.sh` | unchanged (no rule edited) |
| Markdown lint | `npx --yes markdownlint-cli@0.49.1 --dot <changed .md files>` | no output |
| Evidence checker on the example specs | `.claude/hooks/check-test-evidence.sh examples/serverest/qa-api/playwright` | clean |

## Scope

**In scope**: `.claude/skills/qa-api/SKILL.md`; at most one `references/` file under it if Step 2
says so; `.claude/commands/qa.md` (one skill-list line, one routing row);
`README.md` (`:153` count, `:196-198` table, `:442` comment); `examples/serverest/qa-api/`;
`examples/README.md`; `plans/README.md`.

**Out of scope**: `/qa-automate` (making it less browser-first is a separate change); `/qa-static`;
the installers and their hint text; any rule; performance and load testing of APIs (a different
activity and tool category); bundling Pact, Schemathesis or any other executable tool.

## Git workflow

Branch `feat/qa-api-skill`. Conventional Commits, one concept each, **no AI attribution lines**:

1. `feat: add the qa-api skill for API and contract testing` — `SKILL.md`, its reference if any, and
   the `qa.md` router lines (shipped together: a skill with no route is unreachable from `/qa`).
2. `docs: list the qa-api skill in the README`
3. `docs: add the qa-api worked example on ServeRest`
4. `docs(plans): record plan 039 outcome`

`feat:` is right for commit 1 only: it is the one that reaches installed users (CONTRIBUTING.md §2).

## Steps

### Step 1: re-run the overlap check

Repeat the grep above and the table's file:line checks on the branch head. If a command or skill
now covers response-vs-contract conformance or API test design, **STOP** (see conditions).

### Step 2: decide where on-demand content lives

Plan 034 (`plans/034-public-content-and-structure.md`, drafted in parallel and read at the end of
this planning session) settles two things this plan must follow; implement after its PR B merges:

- **Pointer convention** (034 step 3): a rule by name ("the `context-discovery` rule"), a reference
  by skill-relative path (`qa-reference/references/testing-design.md`), a command by slash name
  (`/qa-static`), a script by name with its Claude Code location and a fallback. No `.claude/...`
  paths in the skill; `tests/test-reference-links.sh` will fail on them after 034.
- **Where new reference content goes** (034 "Maintenance notes"): `.claude/skills/qa-reference/references/<topic>.md`,
  flat, one topic per file, with a row in `qa-reference/SKILL.md`'s contents table, a "read it when"
  clause, and a `verify-adapters.sh` marker.

So: keep the API-specific workflow in `SKILL.md`; if anything long remains (GraphQL notes, the
mismatch-triage table), it becomes `qa-reference/references/api-contracts.md` under those rules.
Prefer no reference file if `SKILL.md` stays ≤ 10 KB. If 034 is rejected or changed, re-read it and
follow what merged; the line references in this plan to `qa-automate.md` may also have moved
(034 step 5 splits it).

### Step 3: write the skill

Frontmatter per plan 019 phase 3 and `tests/test-frontmatter.sh` (name = folder; description ≤ 1024
characters, saying what it does **and when to use it**). Draft, to check against the finished body:

```yaml
---
name: qa-api
description: "Tests REST and GraphQL APIs against their contract: finds the OpenAPI or GraphQL schema, designs per-endpoint tests with equivalence partitions, boundaries and resource state transitions, checks real responses (bodies and errors, not only status codes) for schema conformance, and recommends schema checks or consumer-driven contract tests. Use when asked to test an API, an endpoint, a contract, an OpenAPI or GraphQL schema, or to write API tests."
---
```

Body sections: when it activates; rules it reuses (the overlap table, as pointers); the five steps;
the API-specific content above; "Not ISTQB content" note; output discipline (what was run versus
read, as `qa-migrate/SKILL.md:149-153`). Disambiguate in the first lines: "Reviewing a schema
without running anything is `/qa-static`; this skill runs requests."

### Step 4: route it

`qa.md`: add a skill-list line beside `:60` and a routing row beside `:82`, e.g. `"API test",
"endpoint", "contract test", "OpenAPI", "GraphQL"` → **API Testing Skill** (`skills/qa-api/`). Keep
"review the spec" on `/qa-static` (`:78`). Then commit 1.

### Step 5: README

`README.md:153` count and list, a row in the auto-loaded table (`:196-198`), the `:442` comment.
Commit 2.

### Step 6: worked example on ServeRest

Target: `https://serverest.dev`, OpenAPI at `https://serverest.dev/swagger.json` (HTTP 200,
`application/json`, checked 2026-10-14; OpenAPI 3.0.0, API version 3.2.2 per
`examples/serverest/qa-static/README.md`). Scope: the cart (`/carrinhos`) and login endpoints, the
same slice as the existing examples, so the reader can follow one story through four outputs.

Success criteria, written before running:

- `contract.md` names the schema URL, its fetch date and version, and how the deployed version was
  confirmed.
- `conformance.md` re-detects SR-001 and SR-005 from `../qa-static/review.md` as conformance
  mismatches, each classified, or explains why it no longer reproduces (ServeRest may have changed).
- The specs validate response bodies against the schema, run live, and every created user, product
  and cart is deleted (checked through the API afterwards, as the `/qa-automate` example did).
- At least one assertion is shown to be sensitive: for one passing test, the expected schema or
  value is mutated in a throwaway copy and the test fails for the expected reason (red-green,
  `automation-code.md:88-94`). The output is kept.
- `.claude/hooks/check-test-evidence.sh` runs clean on the specs (no screenshots expected).

Kept in `examples/serverest/qa-api/`: `README.md` (exact prompt, model, date, package version,
tooling versions, honest limits), `api-tests/*.md`, the specs and helpers, `package.json`,
`playwright.config.ts`, `run-output.txt`, `mutation-output.txt`. Unedited, apart from redacting
scratch paths, which the README states. Add the row to `examples/README.md:7-12`. Commit 3.

**GraphQL** is not exercised by ServeRest. Option for Marco (decision 2): run Steps 1-3 once against
the public `https://countries.trevorblades.com/` (answered a query on 2026-10-14; read-only), or ship
with the GraphQL rows marked "reviewed, not exercised", as `qa-migrate` did for Selenium at first.

### Step 7: verify and record

Run the commands table. Record the result in an "Outcome" section of this plan and the
`plans/README.md` row. Commit 4.

## Known hashes and plan 032

`.qa-skills-known-hashes` records files shipped in **tagged** releases
(`generate-known-hashes.sh:36-50`), so a new, unreleased `SKILL.md` changes nothing and
`--check` must still pass. Plan 032 keeps its frozen list open until the cut-over (`# state: open`), so a private release of this skill is added to it by the release workflow's refresh step; nothing extra is needed.

## Done criteria

- [ ] Every command in the table passes on the branch head; outputs pasted in the PR.
- [ ] `SKILL.md` ≤ 10 KB, or the PR says why not.
- [ ] `grep -n "qa-api" .claude/commands/qa.md README.md examples/README.md` shows the router line,
      routing row, README entries and example row.
- [ ] The example meets every success criterion in Step 6, or its README lists which failed.
- [ ] No sentence in the skill cites CTFL for contract testing, schemas or GraphQL.
- [ ] `plans/README.md` row for 039 added and updated.

## STOP conditions

- Step 1 finds another file now covering contract conformance or API test design: report the
  overlap and propose shrinking this plan instead.
- Plan 034 places skill content somewhere that contradicts Step 2 and is not yet merged: ask which
  layout to follow.
- ServeRest's `swagger.json` is gone or the API is down on the run date: report; do not switch
  targets silently.
- The example would need credentials or data that are not throwaway.
- A test or tool would need a rule change (e.g. a new tag): that is a separate plan.

## Rejected approaches

- **Extend `/qa-automate` with an API section instead**: it is already 618 lines over many topics
  (audit backlog, "Structure"); an API workflow is multi-step and stateful, which is what skills
  are for here (`plan 023`, "Command or skill").
- **Make Pact the default**: consumer-driven contracts need a broker, both teams' cooperation and
  a provider verification step; for most target repos schema conformance is the cheaper first
  activity. The skill recommends Pact-style contracts only when the conditions are named.
- **Bundle a schema validator or fuzzer**: the package is Markdown plus installers and model-agnostic;
  executable tools add a maintenance and security surface (same reason as plan 023).
- **Cite ISTQB for contract testing**: the syllabus has no such text.

## Maintenance notes

- If `/qa-automate` later becomes level-neutral, move the "automate" step's structure there and keep
  only the API-specific checks here.
- ServeRest is public and changing: the example's README must date every live claim.

## Approval gate

Approved by Marco on 2026-10-14. Decisions:

1. One skill, `qa-api`, covering REST and GraphQL.
2. GraphQL is exercised on the public countries API.
3. Released before the public cut-over (plan 032 keeps its hash list open until then).
4. Order among 039-042: by plan number.

## Outcome

Implemented 2026-10-18 on `feat/qa-api-skill`, from `github/next` at `71312a3`. Marco asked on
2026-10-18 for all remaining work to be done; the plan was already approved (2026-10-14, "approved as
planned; GraphQL is exercised against the public countries API"), so the approval gate was passed
and nothing needed a default.

### Step 1: overlap and drift check (2026-10-18)

The drift check listed 31 changed files since `a2f08e7`: plan 034 landed (the `qa-automate.md`
split, pointer convention, `qa-reference/references/` files, `qa.md`, `context-discovery.md`), so
every `file:line` reference above is **stale** and was re-read instead. The grep for graphql,
openapi, contract and schema over `.claude` found nothing covering response-versus-contract
conformance, consumer-driven contracts, GraphQL operations or API test design (matches were
`/qa-static`, `context-discovery.md` Tier 1, the agents' "Output Contract" headings and
"schema" in the sense of a tracker). No STOP condition fired. Plan 034's layout does not contradict
Step 2.

### Step 2: where content lives

All content is in `SKILL.md`: 10,406 bytes, cut from 11.2 KB. The target was <= 10 KB, so it is
about 0.4 KB over; the PR says so. No `qa-reference` file was added. Pointers
follow 034: rules by name, references by skill-relative path, commands by slash name, no `.claude/`
paths.

### What was built

- `.claude/skills/qa-api/SKILL.md` and the router lines in `qa.md` (commit 1).
- README: skills count, auto-loaded table row, structure comment (commit 2).
- `examples/serverest/qa-api/` and its row in `examples/README.md` (commit 4).
- One correction to the skill from what the example showed: GraphQL errors "usually" arrive with
  200 (commit 3).

### Worked example result

21 cases against live services on 2026-10-18: 16 passed, 5 failed. REST 15 cases (10 passed, 5
failed), GraphQL 6 cases (all passed). The 5 failures are classified mismatches: SR-001 and SR-006
still present (documentation drift), SR-005 still present on both request and stored data (software
defect), and a new finding, an undeclared 400 on `POST /login` (documentation drift). Red-green: in
a throwaway copy two schema types were changed; both cases failed for the expected reason. The
evidence checker reported clean; `tsc --noEmit --strict` passed. After the run no test user or
product was left. Success criterion not fully met: the deployed version of ServeRest could not be
confirmed (no version route, no deployment record); `contract.md` says so.

### Findings recorded for the plan

- ServeRest's schema has no `required`, no `additionalProperties` and no `minimum`, so a schema
  check cannot notice a missing key. The skill's step 3 says to check what the schema does not say;
  the example needed a direct assertion for SR-006.
- A GraphQL syntax error was answered 400 (apparently by a gateway) while validation and server
  errors were 200. Plan text said GraphQL errors arrive "with HTTP 200"; the skill now says "usually".
- An unrelated script fetching the ServeRest document from the same machine was answered 429 once.

### Rejected during implementation

- Importing the `qa-automate` example's helpers instead of a copy: an example folder must run on
  its own once copied out of the repository.
- A committed snapshot of the OpenAPI document as the contract: the specs fetch the live document so
  the contract and the service are read together; the hash of one read copy is recorded instead.
