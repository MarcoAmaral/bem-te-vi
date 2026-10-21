---
type: regex
target: last_message
flags: i
pattern: '\b2\.1\.1\b|keyboard[^\n]{0,160}(?:div|submit|activat|Create account|Enter|Space)|(?:div|Create account)[^\n]{0,200}keyboard'
---

The `div` with an `onclick`, which a keyboard cannot reach or use, is found (2.1.1, or in words).
