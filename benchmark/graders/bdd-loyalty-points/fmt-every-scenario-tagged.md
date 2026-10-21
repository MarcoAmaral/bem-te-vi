---
type: regex
target: last_message
flags: m
match: not_contains
pattern: '^(?![ \t]*@)[^\n]*\n[ \t]*Scenario(?: Outline)?:'
---

Every scenario has a tag line directly above it, as the package's writing rules require.
