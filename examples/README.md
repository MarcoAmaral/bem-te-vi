# Examples

Real output from the QA commands and skills on someone else's software, committed as produced. Most examples target **ServeRest**, a public practice API and front end (API documentation `https://serverest.dev`, front end `https://front.serverest.dev`); the migration example targets the public Cypress suite of `cypress-example-todomvc`.

Each folder has a `README.md` with the exact prompt, the date, the package version and a list of honest limits: what was wrong, assumed or only partly done. Read the limits before trusting any output.

| Command | What it was run on | Folder | Headline result |
| ------- | ------------------ | ------ | --------------- |
| `/qa-static` | The cart ("Carrinhos") section of the ServeRest API documentation | [`serverest/qa-static/`](serverest/qa-static/) | 14 findings: 6 Major, 3 Minor, 5 Questions; schema contradicts the API |
| `/qa-agentic` | The story "As a customer, I can't add the same product to my cart twice" | [`serverest/qa-agentic/`](serverest/qa-agentic/) | 14 requirements, a checklist, 33 test cases; fails the package's own format hook |
| `/qa-automate` | 16 of those cases, as Playwright API tests | [`serverest/qa-automate/`](serverest/qa-automate/) | Run live: 15 passed, 1 failed (a real defect) |
| `qa-api` | The cart and login routes of ServeRest against its OpenAPI document, plus a read-only GraphQL API | [`serverest/qa-api/`](serverest/qa-api/) | 21 cases, 16 passed, 5 failed: each failure is a mismatch between schema and API |
| `qa-migrate` | The 32-test Cypress suite of `cypress-example-todomvc`, plus a small Selenium suite | [`todomvc-cypress-to-playwright/`](todomvc-cypress-to-playwright/) | 32 = 31 migrated + 1 dropped; 4 old tests could never fail; decommission NO-GO |
| `qa-flaky` | The ServeRest cart suite and the migrated TodoMVC suite, repeated 10 and 20 times | [`flaky/`](flaky/) | 9 flaky tests with one cause (HTTP 429 in setup), 1 deterministic defect told apart; TodoMVC 0 failures in 640; seeded flake retired with a repeat-run and red-green proof |
| `qa-release` | Whether ServeRest API 3.2.2 is ready to release, from the evidence above | [`serverest/qa-release/`](serverest/qa-release/) | NO-GO: no gate was marked, 3 of 8 P0 cases run, the one failing case has no defect severity |
| `qa-a11y` | The login and sign-up pages of the ServeRest front end, against WCAG 2.2 AA | [`serverest/qa-a11y/`](serverest/qa-a11y/) | 9 failures: axe found 4, 1 more sat in its `incomplete` group, 4 only by hand (keyboard, language, field border, focus ring) |

The ServeRest examples were produced on 2026-10-08 with package version 2.9.0, before the rename to Bem-te-vi (the `qa-release` example on 2026-10-18, reusing their evidence); the migration example on 2026-10-13, before 4.0.0; the `qa-api` example on 2026-10-18, with the skill before its first release; the flaky example on 2026-10-18, on 4.0.1 plus the unreleased skill. The accessibility audit example was produced on 2026-10-18 with package version 4.0.1 plus the changes on the integration branch.

These files document the package. They are not installed by it: `examples/` is not in the npm package.

## Recording the demo

The README's demo GIF is rendered from a script: see [`demo/README.md`](../demo/README.md) to
re-record it. [`demo-script.md`](demo-script.md) is the earlier storyboard for recording it by hand
(plan 019 phase 7), kept as the record.
