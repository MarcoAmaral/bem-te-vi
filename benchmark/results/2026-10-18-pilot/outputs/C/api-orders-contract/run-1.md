# API Contract Mismatches

## Response 1: GET /orders/1042 (200)

**Mismatch:** `total` field is a string `"42.50"` but schema requires `type: number`
- Contract expects: `{"id": number, "status": enum, "total": number, "note"?: string}`
- Recorded: `"total": "42.50"` is a string

## Response 2: GET /orders/999999 (404)

**Mismatch:** Missing required `code` field from Error schema
- Contract requires: `{"code": string, "message": string}`
- Recorded: `{"message": "Order not found"}` — `code` is missing

## Response 3: POST /orders (500)

**Mismatches:**
1. Status code 500 is not documented in the contract. Contract specifies only 201 (success) and 400 (invalid order).
2. Response body `{"error": "value too long for type character varying(500)"}` does not match Error schema, which requires `code` and `message` fields.
3. The `note` field has an undocumented 500-character limit (enforced by the database as `character varying(500)`), but the schema places no constraint on it.

---

# Test Coverage Needed

## Type Safety
- **GET /orders/{id} total field type:** Verify `total` returns a number, not a string (test with decimal values like 42.50, 0.01, 100)

## Error Response Schema
- **404 error format:** Verify Error response includes both `code` and `message` fields (not just `message`)
- **400 error format:** Verify invalid POST requests return properly formed Error objects with `code` and `message`
- **500 error handling:** Verify server errors (or field validation errors) return documented status codes; if 500 is possible, it must be documented in the contract

## Input Validation
- **POST /orders note length:** Test boundary cases
  - note with exactly 500 characters → should succeed (201) or should return 400 with Error schema
  - note with 501 characters → should return 400 (not 500) with `{"code": "...", "message": "..."}`
  - note field omitted → should succeed (it's optional)
- **POST /orders items array:**
  - Empty array `[]` → should return 400 (minItems: 1 constraint)
  - Single item → should succeed
  - Test non-string items if the schema allows coercion
- **POST /orders missing items field:** should return 400 (required field)

## Request Parameter Validation
- **GET /orders/{id} with id < 1:** should return 400 or 404 (schema specifies minimum: 1)
- **GET /orders/{id} with non-integer id:** should return 400
- **GET /orders/{id} with valid id:** verify all required Order fields (`id`, `status`, `total`) are always present and properly typed

## Happy Path
- **GET /orders/{id} with valid id:** verify all fields present, types correct, status is one of [placed, paid, shipped]
- **POST /orders with valid payload:** verify returned Order has all required fields with correct types

## Documentation Gap
- Add `maxLength: 500` constraint to the `note` property in both `NewOrder` and `Order` schemas, or remove the database constraint and allow longer notes.
