---
type: regex
target: last_message
flags: i
match: not_contains
pattern: '(?<!obsolete[\s\S]{0,200})\b4\.1\.1\b(?![\s\S]{0,200}obsolete)'
---

The duplicate id is not reported under 4.1.1 Parsing, which WCAG 2.2 made obsolete; a mention that says it is obsolete is allowed.
