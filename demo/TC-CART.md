---
feature: Cart — no duplicate product
feature_code: CART
tc_count: 9
tracker_issues: [ISSUE-ID]
risk_level: MEDIUM
runbook: N/A — no runbook requested for this feature
implementation_pack: N/A — no implementation pack
spec: N/A — not automated yet
last_updated: 2026-10-20
---

# Test Cases — Cart: no duplicate product

| Field            | Value                                                          |
| ---------------- | -------------------------------------------------------------- |
| **Project**      | ServeRest API (https://serverest.dev)                          |
| **Author**       | Claude — Senior QA Analyst                                     |
| **Date Created** | 2026-10-20                                                     |
| **Last Updated** | 2026-10-20                                                     |
| **Methodology**  | ISTQB CTFL v4.0 — EP, Decision Table, State Transition, Error Guessing |

**Context discovery.** The working directory holds only `story.md`: no tests, schemas, config or docs were found (Tiers 1–4 empty), and no tracker ID was given (`[ISSUE-ID]` is a placeholder). Everything about the API's request shape and messages below is therefore an **assumption from general knowledge of ServeRest, not verified against the running system**: `POST /carrinhos` takes `Authorization: <token>` and a body `{"produtos":[{"idProduto":"<id>","quantidade":N}]}`; success is 201 with "Cadastro realizado com sucesso"; duplicate product is 400 with "Não é permitido possuir produto duplicado"; a second cart is 400 with "Não é permitido ter mais de 1 carrinho". Confirm each against `GET /` Swagger on the target environment before running. The story's criteria are numbered AC-1..AC-3 as given. `@gate` marks the release-gate cases (TC-CART-001, 002, 003).

**Decision table (condition → action)**

| Condition                           | R1  | R2  | R3  | R4  |
| ----------------------------------- | --- | --- | --- | --- |
| Same idProduto listed twice         | F   | T   | F   | T   |
| User already has a cart             | F   | F   | T   | T   |
| **Actions**                         |     |     |     |     |
| 201, cart created                   | X   |     |     |     |
| 400 (duplicate or second cart)      |     | X   | X   | X   |

---

## TC-CART-001: Create a cart with distinct products

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@smoke @p0 @api @cart @candidate @gate` |
| **Issue**              | [ISSUE-ID] |
| **Automation Score**   | HIGH (58/67.5) |
| **ISTQB Technique**    | Decision Table — R1 (no duplicate, no existing cart); EP — valid partition |
| **Manual Env**         | Local (ServeRest), https://serverest.dev |
| **Precondition**       | Authenticated user with no cart; two existing products, A and B, with enough stock (assumption: stock is enforced) |
| **Steps**              | 1. `POST /carrinhos` with `produtos` = [A qty 1, B qty 1] and the user's token |
| **Expected**           | Status 201; body `message` is "Cadastro realizado com sucesso" and `_id` is returned. `GET /carrinhos/{_id}` lists A and B once each. |
| **data-testid needed** | N/A — API test, no UI element |
| **Source**             | AC-2 |
| **Note**               | Message text is an unverified assumption (see introduction). |

---

## TC-CART-002: Reject a cart listing the same product twice

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@smoke @p0 @api @cart @candidate @gate` |
| **Issue**              | [ISSUE-ID] |
| **Automation Score**   | HIGH (57/67.5) |
| **ISTQB Technique**    | Decision Table — R2 (duplicate, no existing cart); EP — invalid partition |
| **Manual Env**         | Local (ServeRest), https://serverest.dev |
| **Precondition**       | Authenticated user with no cart; existing product A |
| **Steps**              | 1. `POST /carrinhos` with `produtos` = [A qty 1, A qty 1] and the user's token |
| **Expected**           | Status 400; `message` is "Não é permitido possuir produto duplicado" (assumed text). No `_id` returned. |
| **data-testid needed** | N/A — API test, no UI element |
| **Source**             | AC-1 |
| **Note**               | Message text is an unverified assumption. |

---

## TC-CART-003: Reject a second cart for a user who already has one

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@smoke @p0 @api @cart @candidate @gate` |
| **Issue**              | [ISSUE-ID] |
| **Automation Score**   | HIGH (56/67.5) |
| **ISTQB Technique**    | Decision Table — R3 (no duplicate, existing cart); State Transition — invalid transition (HasCart → create) |
| **Manual Env**         | Local (ServeRest), https://serverest.dev |
| **Precondition**       | Authenticated user who already has a cart created via TC-CART-001 steps (seeded in this test's own setup, not by running TC-CART-001); existing product C not in that cart |
| **Steps**              | 1. `POST /carrinhos` with `produtos` = [C qty 1] and the user's token |
| **Expected**           | Status 400; `message` is "Não é permitido ter mais de 1 carrinho" (assumed text). |
| **data-testid needed** | N/A — API test, no UI element |
| **Source**             | AC-3 |
| **Note**               | Message text is an unverified assumption. |

---

## TC-CART-004: Reject a duplicate that is not adjacent in the list

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@regression @p1 @api @cart @candidate` |
| **Issue**              | [ISSUE-ID] |
| **Automation Score**   | HIGH (53/67.5) |
| **ISTQB Technique**    | Error Guessing — duplicate detection that only compares neighbours |
| **Manual Env**         | Local (ServeRest), https://serverest.dev |
| **Precondition**       | Authenticated user with no cart; existing products A and B |
| **Steps**              | 1. `POST /carrinhos` with `produtos` = [A qty 1, B qty 1, A qty 1] |
| **Expected**           | Status 400 with the duplicate-product message; no cart is created. |
| **data-testid needed** | N/A — API test, no UI element |
| **Source**             | Added by QA (AC-1 says "twice" but does not say the two entries must be adjacent) |
| **Note**               | N/A — no caveats |

---

## TC-CART-005: Reject the same product with different quantities

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@regression @p1 @api @cart @candidate` |
| **Issue**              | [ISSUE-ID] |
| **Automation Score**   | HIGH (52.5/67.5) |
| **ISTQB Technique**    | EP — invalid partition (same idProduto, differing quantidade) |
| **Manual Env**         | Local (ServeRest), https://serverest.dev |
| **Precondition**       | Authenticated user with no cart; existing product A with stock ≥ 3 |
| **Steps**              | 1. `POST /carrinhos` with `produtos` = [A qty 1, A qty 2] |
| **Expected**           | Status 400 with the duplicate-product message; quantities are not merged into one line (no cart created). |
| **data-testid needed** | N/A — API test, no UI element |
| **Source**             | Added by QA (the story is silent on whether duplicates with different quantities are merged or rejected; story intent "can't add the same product twice" implies reject) |
| **Note**               | Interpretation to confirm with the PO; if merging is intended, the Expected result changes. |

---

## TC-CART-006: A rejected duplicate request leaves no cart behind

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@regression @p1 @api @cart @candidate` |
| **Issue**              | [ISSUE-ID] |
| **Automation Score**   | HIGH (50/67.5) |
| **ISTQB Technique**    | State Transition — NoCart → (rejected create) → NoCart, then NoCart → HasCart |
| **Manual Env**         | Local (ServeRest), https://serverest.dev |
| **Precondition**       | Authenticated user with no cart; existing products A and B |
| **Steps**              | 1. `POST /carrinhos` with [A, A] <br> 2. `POST /carrinhos` with [A, B] |
| **Expected**           | Step 1: 400. Step 2: 201 (the failed attempt did not consume the user's one-cart allowance). |
| **data-testid needed** | N/A — API test, no UI element |
| **Source**             | Added by QA (the ticket is silent on state after a rejected request) |
| **Note**               | Steps are one flow because the assertion is about the state between them. |

---

## TC-CART-007: Duplicate in a second request for a user who has a cart

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@regression @p2 @api @cart @candidate` |
| **Issue**              | [ISSUE-ID] |
| **Automation Score**   | MEDIUM (47/67.5) |
| **ISTQB Technique**    | Decision Table — R4 (duplicate and existing cart) |
| **Manual Env**         | Local (ServeRest), https://serverest.dev |
| **Precondition**       | Authenticated user who already has a cart (seeded in setup); existing product A |
| **Steps**              | 1. `POST /carrinhos` with `produtos` = [A qty 1, A qty 1] |
| **Expected**           | Status 400, and the existing cart is unchanged (`GET /carrinhos/{id}` returns the same products as before). Which of the two messages is returned is not specified by the story; record the observed one. |
| **data-testid needed** | N/A — API test, no UI element |
| **Source**             | Added by QA (the ticket does not say which rule wins when AC-1 and AC-3 both apply) |
| **Note**               | Assumption: either message is acceptable; status 400 and unchanged cart are the verified outcomes. |

---

## TC-CART-008: A different user can create a cart with the same products

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@regression @p2 @api @cart @candidate` |
| **Issue**              | [ISSUE-ID] |
| **Automation Score**   | MEDIUM (44/67.5) |
| **ISTQB Technique**    | Error Guessing — over-broad uniqueness check (duplicate detection or one-cart rule applied across users) |
| **Manual Env**         | Local (ServeRest), https://serverest.dev |
| **Precondition**       | Users U1 (has a cart containing product A) and U2 (no cart), both authenticated |
| **Steps**              | 1. As U2, `POST /carrinhos` with `produtos` = [A qty 1] |
| **Expected**           | Status 201; U1's cart is unchanged. |
| **data-testid needed** | N/A — API test, no UI element |
| **Source**             | Added by QA (the story says "a user who has a cart"; scope per user is implied, not stated) |
| **Note**               | N/A — no caveats |

---

## TC-CART-009: Reject cart creation without a valid token

| Field                  | Value |
| ---------------------- | ----- |
| **Tags**               | `@regression @p1 @api @cart @candidate` |
| **Issue**              | [ISSUE-ID] |
| **Automation Score**   | HIGH (52/67.5) |
| **ISTQB Technique**    | EP — invalid partition (missing / malformed token) |
| **Manual Env**         | Local (ServeRest), https://serverest.dev |
| **Precondition**       | No token available |
| **Steps**              | 1. `POST /carrinhos` with valid distinct products and no `Authorization` header <br> 2. Repeat with `Authorization: invalid` |
| **Expected**           | Both requests: status 401 (assumed); no cart is created. |
| **data-testid needed** | N/A — API test, no UI element |
| **Source**             | Added by QA (the ticket is silent on unauthenticated requests; security baseline for a state-changing endpoint) |
| **Note**               | Status code is an unverified assumption. |
