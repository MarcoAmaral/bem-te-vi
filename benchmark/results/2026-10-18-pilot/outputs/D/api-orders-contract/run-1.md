## Contract

**Location:** OpenAPI 3.0.3 document provided in-line  
**Version:** 2.1.0  
**Tested:** Staging environment, 2026-10-15  
**Auth:** None (no authentication model declared in schema)  
**Base URL:** Assumed `https://staging-api.example.com` (not provided)  

## Conformance Report

### Mismatch 1: Total field type (Response 1)
- **Request:** `GET /orders/1042`
- **Status:** 200
- **Declared schema:** `Order.total` type `number`
- **Actual response:** `"total": "42.50"` (string)
- **Classification:** Software defect — type mismatch
- **Proposed owner:** Backend service team

### Mismatch 2: Error schema missing required field (Response 2)
- **Request:** `GET /orders/999999`
- **Status:** 404
- **Declared schema:** `Error` with required fields `code` and `message`
- **Actual response:** `{"message": "Order not found"}` (missing `code`)
- **Classification:** Software defect — schema non-conformance
- **Proposed owner:** Backend service team

### Mismatch 3: Undocumented status 500 (Response 3)
- **Request:** `POST /orders` with body containing 5,000-character note
- **Status:** 500 (not declared in schema; only 201 and 400 are documented)
- **Declared schema:** N/A for this status
- **Actual response:** `{"error": "value too long for type character varying(500)"}`
- **Classification:** Software defect — undocumented error status
- **Proposed owner:** Backend service team

### Mismatch 4: Error body shape (Response 3)
- **Request:** `POST /orders` with oversized note
- **Declared schema:** `Error` with required fields `code` and `message`
- **Actual response:** `{"error": "..."}` (wrong shape entirely)
- **Classification:** Software defect — error contract violation
- **Proposed owner:** Backend service team

### Undeclared constraint (Response 3)
- **Finding:** `NewOrder.note` has an undeclared maximum length of 500 characters; the schema defines `type: string` with no `maxLength`
- **Classification:** Documentation drift — schema incomplete
- **Proposed owner:** API documentation owner

---

## Test Design

### GET /orders/{id}

**Partitions and Boundaries:**

| Partition | Test Case | Acceptance Criterion |
| --- | --- | --- |
| Valid ID in range | `id: 1` | Returns 200 with valid Order (all required fields) |
| Valid existing ID | `id: 1042` | Returns 200; `status` matches enum; `total` is `number` (not string) |
| Non-existent ID | `id: 999999` | Returns 404 with Error containing both `code` and `message` |
| Boundary: minimum | `id: 1` | Returns 200 or 404 per data state |
| Boundary: below minimum | `id: 0` | Path validation fails (schema declares `minimum: 1`); behavior TBD |
| Boundary: negative | `id: -1` | Path validation fails; behavior TBD |
| Boundary: non-integer | `id: abc` | Returns 400 (path type mismatch); behavior TBD |

**Resource State:** Read-only endpoint; no state transitions.

**Auth:** Not declared; no auth matrix applies.

**Error Contract:** Schema documents 404. Actual API returns 404 with malformed Error body (missing `code`).

**Tags:** `@api @suite:orders @priority:p1 @automation:supported`

---

### POST /orders

**Partitions and Boundaries:**

| Partition | Test Case | Acceptance Criterion |
| --- | --- | --- |
| Valid minimal | `{"items": ["sku-1"]}` | Returns 201 with Order; all required fields present; `id` is integer, `status` in enum, `total` is number |
| Valid with note | `{"items": ["sku-1"], "note": "standard text"}` | Returns 201 with Order including non-null `note` |
| Empty items array | `{"items": []}` | Returns 400 with Error (schema declares `minItems: 1`) |
| Missing items | `{"note": "no items"}` | Returns 400 with Error (items is required) |
| Null items | `{"items": null}` | Returns 400 (type mismatch) |
| Note at limit | `{"items": ["sku-1"], "note": "<500 chars>"}` | Returns 201 (observed limit; schema undeclared) |
| Note over limit | `{"items": ["sku-1"], "note": "<5001 chars>"}` | Returns 400 or 500; observe actual behavior (API currently returns 500 with malformed error) |
| Multiple items | `{"items": ["sku-1", "sku-2", "sku-3"]}` | Returns 201 |
| Invalid item type | `{"items": [123]}` | Returns 400 (items.items must be string) |

**Resource State:** Create endpoint; no invalid transitions.

**Auth:** Not declared; no auth matrix applies.

**Error Contract:** Schema documents 400. API also returns 500 for validation failures, with non-conforming error body.

**Tags:** `@api @suite:orders @priority:p1 @automation:supported`

---

## Contract Strategy

**Schema conformance checks are sufficient** for this API. A single provider with no known consumers outside this team can catch breaking changes via schema validation of live responses. Consumer-driven contracts are not justified unless independent client teams emerge with separate release cycles. Prioritize: (1) fix the three software defects (type mismatches and error shapes), (2) add `maxLength: 500` to `NewOrder.note`, (3) document status 500, and (4) make error response shapes consistent across all statuses and status codes.
