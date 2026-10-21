# Traceability: Password reset

- Requirements: `requirements.md`, REQ-1 to REQ-5 (numbered by the pipeline)
- Test cases: `testcases.md`, 5 cases
- Results: `results.txt`
- Written: nothing (read-only run)

## Coverage

| Requirement | Test case | Technique | Automation | Link basis | Last result |
| --- | --- | --- | --- | --- | --- |
| REQ-1 | TC-RST-001 | EP | automated | traced | pass |
| REQ-2 | TC-RST-003 | State Transition | candidate | inferred | fail |
| REQ-3 | — | — | — | — | — |
| REQ-4 | TC-RST-002 | BVA | candidate | traced | not run |
| REQ-5 | TC-RST-005 | State Transition | candidate | traced | not run |

## Gaps

| ID | Kind | Item | Detail |
| --- | --- | --- | --- |
| TR-001 | No test | REQ-3 | No test case traces to or mentions this requirement |
| TR-002 | Inferred only | REQ-2 | Linked by keywords ("reset link", "expired"); confirm, then add "Traces to REQ-2" to the Note of TC-RST-003 |
| TR-003 | No passing test | REQ-2 | TC-RST-003 fail |
| TR-004 | No passing test | REQ-4 | TC-RST-002 not run |
| TR-005 | No passing test | REQ-5 | TC-RST-005 not run |
| TR-006 | No requirement | TC-RST-004 | Traces to no requirement in `requirements.md` |

## Metrics

- Requirements: 5
- With at least one test (traced or inferred): 4 of 5 (80%)
- With at least one traced test: 3 of 5 (60%)
- With at least one passing test: 1 of 5 (20%)
- Test cases: 5; with no requirement: 1

Coverage counts requirements that have a test. It is not evidence that the tests are adequate:
testing shows the presence of defects, not their absence.
