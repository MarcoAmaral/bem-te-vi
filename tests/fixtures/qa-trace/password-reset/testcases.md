---
feature: Password reset
feature_code: RST
tc_count: 5
tracker_issues: [SAMPLE-1]
risk_level: HIGH
cdt: N/A — fixture, never executed by hand
implementation_pack: N/A — fixture
spec: tests/e2e/password-reset.spec.ts
last_updated: 2026-10-12
---

# Test Cases — Password reset

## TC-RST-001: Send a reset link to a registered email address

| Field                  | Value                                         |
| ---------------------- | --------------------------------------------- |
| **Tags**               | `@smoke @p1 @e2e @auth @automated`            |
| **Issue**              | SAMPLE-1                                      |
| **Automation Score**   | HIGH (50/57.5)                                |
| **ISTQB Technique**    | EP                                            |
| **Manual Env**         | Local                                         |
| **Precondition**       | An account exists for `user@example.com`      |
| **Steps**              | 1. Request a reset for `user@example.com`     |
| **Expected**           | A reset link arrives at `user@example.com`    |
| **data-testid needed** | `reset-request-submit`                        |
| **Source**             | AC-1                                          |
| **Note**               | Traces to REQ-1                               |

## TC-RST-002: Reject an 11-character new password

| Field                  | Value                                          |
| ---------------------- | ---------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @auth @candidate`        |
| **Issue**              | SAMPLE-1                                       |
| **Automation Score**   | HIGH (48/57.5)                                 |
| **ISTQB Technique**    | BVA                                            |
| **Manual Env**         | Local                                          |
| **Precondition**       | A valid reset link is open                     |
| **Steps**              | 1. Enter an 11-character password <br> 2. Save |
| **Expected**           | The password is rejected with a length message |
| **data-testid needed** | `new-password-error`                           |
| **Source**             | AC-4                                           |
| **Note**               | Traces to REQ-4                                |

## TC-RST-003: Refuse a reset link opened after it expired

| Field                  | Value                                          |
| ---------------------- | ---------------------------------------------- |
| **Tags**               | `@regression @p1 @e2e @auth @candidate`        |
| **Issue**              | SAMPLE-1                                       |
| **Automation Score**   | MEDIUM (40/57.5)                               |
| **ISTQB Technique**    | State Transition                               |
| **Manual Env**         | Local                                          |
| **Precondition**       | A reset link was sent 31 minutes ago           |
| **Steps**              | 1. Open the reset link                         |
| **Expected**           | The page says the link has expired             |
| **data-testid needed** | `reset-link-expired`                           |
| **Source**             | Added by QA (written before ACs were numbered) |
| **Note**               | Written before the requirements were numbered  |

## TC-RST-004: Keep the session after choosing remember me

| Field                  | Value                                                  |
| ---------------------- | ------------------------------------------------------ |
| **Tags**               | `@regression @p3 @e2e @auth @automated`                |
| **Issue**              | SAMPLE-1                                               |
| **Automation Score**   | MEDIUM (38/57.5)                                       |
| **ISTQB Technique**    | Error Guessing                                         |
| **Manual Env**         | Local                                                  |
| **Precondition**       | Signed out                                             |
| **Steps**              | 1. Sign in with remember me <br> 2. Reopen the browser |
| **Expected**           | Still signed in                                        |
| **data-testid needed** | `remember-me`                                          |
| **Source**             | Added by QA (found while exploring)                    |
| **Note**               | N/A — found while exploring; no requirement yet        |

## TC-RST-005: Refuse a reset link that was already used

| Field                  | Value                                           |
| ---------------------- | ----------------------------------------------- |
| **Tags**               | `@regression @p2 @e2e @auth @candidate`         |
| **Issue**              | SAMPLE-1                                        |
| **Automation Score**   | MEDIUM (41/57.5)                                |
| **ISTQB Technique**    | State Transition                                |
| **Manual Env**         | Local                                           |
| **Precondition**       | A reset link was already used to set a password |
| **Steps**              | 1. Open the same reset link again               |
| **Expected**           | The page says the link was already used         |
| **data-testid needed** | `reset-link-used`                               |
| **Source**             | AC-5                                            |
| **Note**               | N/A — linked to its requirement by Source only  |
