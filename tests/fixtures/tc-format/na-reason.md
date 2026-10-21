---
feature: Sign-in
feature_code: AUTH
tc_count: 1
tracker_issues: [AUTH-12]
risk_level: HIGH
cdt: N/A — no execution notebook for this feature
implementation_pack: N/A — no implementation pack
spec: N/A — not automated yet
last_updated: 2026-10-07
---

# Test Cases — Sign-in

## TC-AUTH-001: Show the sign-in dialog when unauthenticated

| Field                  | Value                              |
| ---------------------- | ---------------------------------- |
| **Tags**               | `@smoke @p0 @e2e @auth @candidate` |
| **Issue**              | AUTH-12                            |
| **Automation Score**   | HIGH (52/57.5)                     |
| **ISTQB Technique**    | Functional — entry point           |
| **Manual Env**         | N/A — runs in CI only              |
| **Precondition**       | No cached credentials              |
| **Steps**              | 1. Open the app                    |
| **Expected**           | Sign-in overlay appears            |
| **data-testid needed** | N/A — no element is asserted       |
| **Source**             | AC-1 — sign-in overlay shown       |
| **Note**               | N/A — no caveats                   |
