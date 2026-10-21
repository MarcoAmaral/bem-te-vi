# Design: ServeRest cart and login (step 2)

Produced following `.claude/skills/qa-api/SKILL.md`, step 2, from [`contract.md`](contract.md). Techniques are the ones in `qa-reference/references/testing-design.md`. Case IDs are the ones in the specs. A case that checks a finding of the earlier static review names it (SR-nnn, in `../../qa-static/review.md`).

This is a **slice**, not the full design: the cart routes and login only, and the cases that decide whether the body matches the contract. The partitions of the 33 cart cases in `../../qa-agentic/` are not repeated.

## Cases

| ID | Operation | Technique | Checks | Source | Tags |
| -- | --------- | --------- | ------ | ------ | ---- |
| API-LOGIN-01 | `POST /login` | EP, valid partition | 200 and a body that conforms | Declared 200 | `@smoke @p0` |
| API-LOGIN-02 | `POST /login` | EP, invalid partition (wrong password) | 401 and a body that conforms | Declared 401 | `@regression @p1` |
| API-LOGIN-03 | `POST /login` | EP, invalid partition (empty fields) | The status is one the contract declares | Contract completeness | `@regression @p2` |
| API-CART-01 | `POST /carrinhos` | EP, valid | 201 and a body that conforms | Declared 201 | `@smoke @p0` |
| API-CART-02 | `GET /carrinhos/{_id}` | State transition: cart exists | 200 and a body that conforms | Declared 200 | `@smoke @p0` |
| API-CART-03 | `GET /carrinhos/{_id}` | State transition: no such cart | 400 and a body that conforms | Declared 400 | `@regression @p1` |
| API-CART-04 | `GET /carrinhos` | EP, filter by user | 200, one cart, a body that conforms | Declared 200 | `@regression @p1` |
| API-CART-05 | `POST /carrinhos` | Auth matrix: no token | 401 and a body that conforms | Declared 401 | `@regression @p1` |
| API-CART-06 | `DELETE .../cancelar-compra` | State transition: cart to no cart | 200 and a body that conforms | Declared 200 | `@regression @p1` |
| API-CART-07 | `DELETE .../cancelar-compra` | Auth matrix: no token | 401 and a body that conforms | Declared 401 | `@regression @p2` |
| API-CART-08 | `POST /carrinhos` | EP, invalid (duplicate product) | 400 and a body that conforms | Declared 400 | `@regression @p1` |
| API-CART-09 | `POST /carrinhos` | EP, valid by the declared request schema | A body built from the declared request schema is accepted | SR-001 | `@regression @p1` |
| API-CART-10 | `POST /carrinhos` | EP, invalid type (BVA on `quantidade`) | A string `quantidade` is rejected with 400 | SR-005 | `@regression @p2` |
| API-CART-11 | `GET /carrinhos` | Conformance of stored data | A cart made from a string `quantidade` still conforms | SR-005 | `@regression @p2` |
| API-CART-12 | `POST /carrinhos` | Error contract | A validation 400 carries the documented `message` | SR-006 | `@regression @p2` |

All are `@api` and `@automated`. The auth matrix is only the "no token" row: expired token, another user's resource and wrong role were not designed here, and the object-level checks belong to the `security-qa` rule.

## Not designed in this slice

- Idempotency: `DELETE /carrinhos/cancelar-compra` repeated returns 200 both times (seen by the fixtures' clean-up), but no case asserts it.
- `DELETE /carrinhos/concluir-compra` has no case (it does not restore stock, SR-004; the earlier example covered stock).
- Invalid state transitions beyond "no cart" (complete an empty cart, cancel twice) were not designed.

## Contract strategy (step 5)

**Schema conformance checks are enough here.** The provider is one small public service with no named consumers, so there is no team to share a consumer-driven contract with, and no provider pipeline to verify one in. The cheap activity is the one in these specs: validate each response body against the published schema on every run. Consumer-driven contracts would be justified only if several independently released clients depended on this API, which is not the case. Two caveats follow from [`conformance.md`](conformance.md): the schema declares no `required` fields, so a conformance check cannot notice a missing key, and the schema describes the request body wrongly (SR-001), so it must be fixed before it can be trusted as a contract. A simulator was not used.
