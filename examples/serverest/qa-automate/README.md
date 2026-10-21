# Example: `/qa-automate` on the cart test cases

Playwright API tests (the `request` fixture, no browser) for 16 of the 33 cases in [`../qa-agentic/cart-no-duplicate-product/testcases.md`](../qa-agentic/cart-no-duplicate-product/testcases.md), run against the public `https://serverest.dev`.

```text
qa-automate/
├── package.json
├── playwright.config.ts
├── behaviour-profile.md                       # facts seen on the live API, dated
├── run-output.txt                             # the real run, list reporter
└── playwright/
    ├── api/ServeRestApi.ts                    # actions only, no assertions
    ├── fixtures/serverest.ts                  # per-test admin, customer and products, cleaned up afterwards
    └── tests/cart/cart-no-duplicate-product.api.spec.ts
```

## Prompt

```text
/qa-automate Automate TC-CART-001, 002, 004, 006, 009, 011, 013, 015, 016, 019, 022, 024, 025, 026, 028 and 030 from examples/serverest/qa-agentic/cart-no-duplicate-product/testcases.md as Playwright API tests (request fixture) against https://serverest.dev
```

## Run details

| Item | Value |
| ---- | ----- |
| Date | 2026-10-08 |
| Package version | 2.9.0 (before the rename to Bem-te-vi) |
| Files followed | `.claude/commands/qa-automate.md`, `.claude/rules/context-discovery.md`, `code-style-qa.md`, `test-evidence.md` |
| Model | An AI coding assistant following the command file (Claude Sonnet 5.5, `claude-sonnet-5-5`) |
| Tooling | Node v24.16.0, `@playwright/test` 1.64.0, TypeScript 5.9.3 |

## ServeRest's Portuguese

ServeRest answers in Portuguese. Its messages, paths and field names are quoted verbatim in this
example, because the tests compare against what the real server returns. English glosses:

- `/carrinhos`: carts; `concluir-compra`: complete purchase; `cancelar-compra`: cancel purchase
- `produtos`: products; `idProduto`: product ID; `idProdutosDuplicados`: duplicated product IDs
- `quantidade`: quantity; `quantidadeTotal`: total quantity; `precoTotal`: total price
- "Não é permitido possuir produto duplicado": a duplicate product is not allowed
- "Não é permitido ter mais de 1 carrinho": having more than 1 cart is not allowed
- "Não foi encontrado carrinho para esse usuário": no cart was found for this user

## Result of the real run

The tests **ran** against the live API. The result, from [`run-output.txt`](run-output.txt): **15 passed, 1 failed** in 33.4 seconds.

The failure is TC-CART-030 (`quantidade` sent as the string `"2"` is expected to return 400; the API returned 201). It is the defect noted as SR-005 in `../qa-static/review.md`, and it was predicted before the run. The test was left failing on purpose rather than skipped or marked as an expected failure, so the run shows a real defect.

To reproduce, copy the folder somewhere outside this repository and run:

```bash
npm install
npm test
```

Browsers are not needed. Afterwards no test users, administrators or products were left on the instance (checked by name through the API).

## Honest limits

- **The command file is browser-first.** `qa-automate.md` describes page objects, `data-testid` and an auth setup project. None of that applies to an API suite, so the config is simpler than the template (no `setup` project, no `storageState`, no dotenv, one project), the helper class lives in `playwright/api/` instead of `playwright/pages/`, and the `data-testid` guidance was not used. The tags, AAA structure, TC-ID comments, no-sleep rule and test isolation were applied.
- **Only 16 of 33 cases were automated.** The subset was chosen by the assistant: every `@smoke` case with a stable assertion, plus the stock and state-transition cases. TC-CART-003, 005, 007, 008, 010, 012, 014, 017, 018, 020, 021, 023, 027, 029, 031 to 033 were not automated.
- **The passes prove little about the checks being sensitive.** Only TC-CART-030 was seen to fail. The other 15 were not run against a deliberately broken target, so a pass says the live API behaves as the cases expect, not that each assertion would catch a regression.
- **Public, shared service.** Every test creates its own users and products with random names and deletes them, but the instance is shared and unversioned. A run on another day may fail for reasons outside the suite (service change, rate limiting, a wipe in the middle of a run). Retries are off.
- **Slow by design.** About 2 seconds per test, because setup creates an administrator, a customer and one or more products over the network each time. This was kept for isolation; a worker-scoped administrator would be faster.
- **Scratch-path redaction.** `run-output.txt` is the real console output with one edit: the temporary directory used for the run was replaced by `<run-dir>`.
- **Evidence rule.** The specs take no screenshots or recordings, so `test-evidence.md` has little to say here. `.claude/hooks/check-test-evidence.sh` was run on the specs and reported clean, which is expected for an API-only suite.
- **Types were not compiled separately.** TypeScript ran through Playwright's loader; `tsc --noEmit` was not run.
