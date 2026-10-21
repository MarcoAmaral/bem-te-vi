---
feature: Sign-in
feature_code: AUTH
tc_count: 1
tracker_issues: [AUTH-12]
risk_level: HIGH
runbook: runbooks/RB-AUTH-sign-in.md
implementation_pack: feature-implementations/sign-in/
spec: tests/e2e/sign-in.spec.ts
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
| **Manual Env**         | Local, Staging                     |
| **Precondition**       | No cached credentials              |
| **Steps**              | 1. Open the app                    |
| **Expected**           | Sign-in overlay appears            |
| **data-testid needed** | `sign-in-overlay`                  |
| **Source**             | AC-1 — sign-in overlay shown       |
| **Note**               | None                               |
