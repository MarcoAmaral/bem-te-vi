# QA Report: Orders API v2.1.0

## Recorded Response Mismatches

### Response 1: GET /orders/1042
**Issue: Type mismatch in `total` field**
- Recorded: `"total": "42.50"` (string)
- Contract: `total` must be `type: number`
- Severity: **High** — Consumers expecting numeric type will break on string parsing

**Issue: Null value for optional field `note`**
- Recorded: `"note": null`
- Contract: `note` is optional but typed `string`, not nullable
- Severity: **Medium** — Implies field is present but null, rather than omitted; inconsistent with schema intent
- Assumption: Schema should clarify if optional fields can be null or must be omitted

---

### Response 2: GET /orders/999999
**Issue: Missing required `code` field**
- Recorded: `{"message": "Order not found"}`
- Contract: Error schema requires both `code` (string, required) and `message` (string, required)
- Severity: **High** — Violates contract; clients expecting `code` will fail

---

### Response 3: POST /orders (5000-char note)
**Issue: Undocumented status code 500**
- Recorded: HTTP 500 returned
- Contract: Only 201 and 400 are documented
- Severity: **High** — API behavior not in spec

**Issue: Response schema mismatch**
- Recorded: `{"error": "value too long for type character varying(500)"}`
- Contract: 400 errors must use Error schema with `code` and `message` fields
- Severity: **High** — Different structure than contract

**Issue: Validation failure returns 5xx instead of 400**
- Expected: 400 Bad Request (documented for invalid input)
- Recorded: 500 Internal Server Error
- Root cause: Input validation for `note` length is missing; database constraint leaked to response
- Severity: **Critical** — API leaks implementation details; fails to validate per contract

**Assumption:** `note` field has an undocumented 500-character limit in the database schema. This should be added to the OpenAPI contract's `NewOrder.note` as `maxLength: 500` and validated at API layer before database insertion, returning 400.

---

## Required Test Suite

### Happy Path
- **GET /orders/{id}** with existing valid id → 200, Order schema with all required fields, `total` as number, `status` in enum
- **POST /orders** with valid items array and optional note → 201, Order schema with generated `id` and `status: "placed"`

### 404 Scenarios  
- **GET /orders/999999** (or any non-existent id) → 404 with Error schema including both `code` and `message` fields

### 400 Validation Scenarios
- **POST /orders** with missing `items` field → 400, Error schema
- **POST /orders** with empty `items` array `[]` → 400 (minItems: 1 violation)
- **POST /orders** with `items` as non-array (e.g., string, object) → 400, Error schema
- **POST /orders** with `note` exceeding 500 characters → 400, Error schema (after spec amendment)
- **POST /orders** with `note` as non-string → 400, Error schema
- **POST /orders** with `items` containing non-string values → 400, Error schema

### Path Parameter Validation
- **GET /orders/0** (minimum: 1 violation) → 400
- **GET /orders/-1** → 400
- **GET /orders/abc** (non-integer) → 400

### Schema Compliance
- All Error responses include both `code` (string) and `message` (string)
- `Order.total` is always numeric type, never string
- `Order.status` only values: "placed", "paid", "shipped"
- Optional fields either present with correct type or omitted (establish null-handling convention)

### Integration Scenarios
- Create order via POST, then retrieve via GET with returned `id` → full round-trip consistency
- Verify order progresses through status enum values over time
