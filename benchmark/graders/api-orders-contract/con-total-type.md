---
type: regex
target: last_message
flags: i
pattern: '\btotal\b[^\n]{0,200}\bstring\b|\bstring\b[^\n]{0,200}\btotal\b'
---

The 200 response's `total` is a string where the schema declares a number.
