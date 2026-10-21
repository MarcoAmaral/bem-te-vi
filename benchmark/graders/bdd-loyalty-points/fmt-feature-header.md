---
type: regex
target: last_message
flags: im
pattern: '^[ \t]*(?:#+[ \t]*)?Feature:[^\n]*\n(?:[^\n]*\n){0,3}?[ \t]*As an?\b[^\n]*\n[ \t]*I want\b[^\n]*\n[ \t]*So that\b'
---

The feature starts with the package's header: `Feature:`, then As a / I want / So that.
