---
type: regex
target: last_message
flags: im
pattern: '^\|[^\n]*(?:sandbox|half[- ]time|0\.5 FTE|one tester|single tester|10[- ]working[- ]days?|deadline)[^\n]*\||^[^\n]*\brisk\w*\b[^\n]*(?:sandbox|half[- ]time|0\.5 FTE|one tester|single tester|10[- ]working[- ]days?|deadline)|^[^\n]*(?:sandbox|half[- ]time|0\.5 FTE|one tester|single tester|10[- ]working[- ]days?|deadline)[^\n]*\brisk'
---

The brief's constraints (the sandbox's two days, the half-time tester, the deadline) are treated as project risks: named in a table row, as a risk register has them, or on a line that calls them a risk. The word "project" is not required.
