# Conformance: ServeRest cart and login (step 3)

Produced following `.claude/skills/qa-api/SKILL.md`, step 3, by running `../playwright/` on 2026-10-18 against `https://serverest.dev`. Output: [`../run-output.txt`](../run-output.txt) (REST rows) and the GraphQL rows in [`graphql/conformance.md`](graphql/conformance.md). Every created user, product and cart was deleted; afterwards no user named "Contract test" and no product named "Contract test product" existed (checked through the API).

## Result

15 REST cases ran: 10 passed, 5 failed. Each failure is a **mismatch between the contract and the live API**, not a flaky test. The 5 are classified below.

| Case | Request | Declared | Actual | Classification | Proposed owner |
| ---- | ------- | -------- | ------ | -------------- | -------------- |
| API-CART-09 | `POST /carrinhos` with `{"produtos": {"idProduto": …, "quantidade": 1}}` | `requestBodyCarrinho` declares `produtos` as one **object**; the check shows this body valid against it | 400 `{"produtos": "produtos deve ser um array"}` | **Documentation drift.** The API requires an array; the schema is wrong. Its own `example` is an array. Same as SR-001, still present | Document owner |
| API-CART-10 | `POST /carrinhos` with `quantidade: "2"` | The item schema declares `quantidade` as `integer` | 201 | **Software defect.** A value that is invalid by the contract is accepted. Same as SR-005, still present | Software owner |
| API-CART-11 | `GET /carrinhos?idUsuario=…` after that cart | `quantidade` and `quantidadeTotal` are `integer` | `/carrinhos/0/produtos/0/quantidade must be integer`; `/carrinhos/0/quantidadeTotal must be integer` | **Software defect**, the stored consequence of API-CART-10 (SR-005: `quantidadeTotal` came back as the string `"02"`) | Software owner |
| API-CART-12 | `POST /carrinhos` with `produtos: []` | The 400 body is `{message: string}` | 400 `{"produtos": "produtos não contém 1 valor obrigatório"}`, no `message` key | **Documentation drift**, same as SR-006: two 400 shapes exist and only one is documented | Document owner |
| API-LOGIN-03 | `POST /login` with empty `email` and `password` | Only 200 and 401 are declared | 400 `{"email": "email não pode ficar em branco", "password": "password não pode ficar em branco"}` | **Documentation drift.** A status the contract does not declare. A new finding: the static review did not cover `/login` | Document owner |

The 10 passing cases confirm the declared 200, 201, 400 and 401 bodies of the slice conform to their schemas.

## Findings of the static review, re-checked

| Finding | Re-detected? | Where |
| ------- | ------------ | ----- |
| SR-001 `produtos` object versus array | Yes, still present | API-CART-09 |
| SR-005 string `quantidade` accepted | Yes, still present; both the request side and the stored data | API-CART-10, API-CART-11 |
| SR-006 two shapes of 400 | Yes, still present | API-CART-12 |
| SR-002, SR-003, SR-004, SR-009 to SR-011, SR-013, SR-014 | Not a conformance question (ambiguity, state rules, business questions); not re-run | None |
| SR-007 documented text of the cancel message | Not checked: the documented text is an `example`, and an `example` is not a constraint a schema check can enforce | None |
| SR-008 `idCarrinho` versus `idCarrinhos` | Not checked: the route (`DELETE /produtos/{_id}`) is outside this slice | None |
| SR-012 unauthenticated reads | Observed again as a fact (the reads in API-CART-02 to 04 send no token); no case asserts it | None |

## What the schema cannot catch

- The slice's schemas declare **no `required` keys**, so a response that **omits** a field still conforms. API-CART-12 only found the missing `message` because it asserts the key itself. Conformance to a schema with no `required` is weaker than it looks.
- **No `additionalProperties`**, so an extra field (for example `idProdutosDuplicados` on the duplicate 400) conforms.
- **Examples are not checked.** `example` values in the document are free text; the pipe-separated list of messages in the 400 `example` (SR-002) cannot be validated.

## Not exercised

`DELETE /carrinhos/concluir-compra` (no case), `GET /carrinhos` without the user filter (it returns every user's carts on a shared instance, so a conformance failure could come from someone else's data and was avoided on purpose), expired tokens, and any route outside the slice.
