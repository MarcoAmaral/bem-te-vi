# API Contract Compliance Report

## Mismatches Found

### Response 1: GET /orders/1042 → 200
| Field | Expected | Actual | Status |
|-------|----------|--------|--------|
| `total` | number | string `"42.50"` | ❌ Type mismatch |
| `note` | string or omitted | `null` | ❌ Null not allowed; must be string or absent |

### Response 2: GET /orders/999999 → 404
| Field | Expected | Actual | Status |
|-------|----------|--------|--------|
| `code` | string (required) | missing | ❌ Required field absent |
| `message` | string (required) | present ✓ | ✓ Correct |

### Response 3: POST /orders → 500
| Issue | Details |
|-------|---------|
| **Status Code** | Returned 500; spec requires 201 (success) or 400 (invalid request) | ❌ Invalid |
| **Response Schema** | Has `error` field; spec requires `code` and `message` | ❌ Mismatch |
| **Missing Validation** | Schema doesn't specify `note` max length; server enforces 500 chars | ⚠️ Spec gap |

---

## Test Suite Design

### 1. **Happy Path Tests**
- GET /orders/{validId} returns 200 with Order schema where `total` is numeric
- GET /orders/{validId} returns `status` as one of: placed, paid, shipped
- POST /orders with valid NewOrder (minItems=1) returns 201 with complete Order object
- POST /orders with optional `note` field returns Order with `note` populated

### 2. **Type Validation Tests**
- Response `total` field is a JSON number, not a string
- Response `id` is a JSON integer
- Response `note` is either a JSON string or omitted entirely (never null)

### 3. **Error Response Schema Tests**
- 404 responses include both `code` and `message` fields (both required)
- 400 responses include both `code` and `message` fields (both required)
- Error responses never use `error` field name

### 4. **Path Parameter Validation**
- GET /orders/0 returns 400 (id minimum: 1)
- GET /orders/-5 returns 400 (invalid)
- GET /orders/abc returns 400 (not an integer)

### 5. **Request Body Validation**
- POST /orders with empty `items: []` returns 400 (minItems: 1 required)
- POST /orders with missing `items` field returns 400
- POST /orders with `note` exceeding 500 characters returns 400 (not 500)
- POST /orders with invalid JSON returns 400
- POST /orders with `items` containing non-strings returns 400

### 6. **Boundary Tests**
- POST /orders with `note` of exactly 500 characters succeeds
- POST /orders with `note` of 501 characters returns 400 with proper Error schema
- GET /orders with very large id (2147483647) handled correctly

### 7. **Status Enum Tests**
- Returned Order `status` only contains values from [placed, paid, shipped]
- No other status values appear in responses

### 8. **Optional Field Tests**
- POST /orders without `note` field returns 201 (not required)
- Returned Order can omit `note` when not provided

---

## Recommendations

1. **Schema Amendment**: Add `maxLength: 500` to `NewOrder.properties.note`
2. **Implementation Fix**: Return 400 for oversized `note`; include `code` field in Error responses
3. **Serialization Fix**: Serialize `total` as JSON number; never include `null` for optional string fields
