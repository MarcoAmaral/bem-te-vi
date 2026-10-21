---
type: regex
target: last_message
flags: i
pattern: '\b(?:1\.3\.1|3\.3\.2|4\.1\.2)\b|unlabell?ed|(?:no|missing|without|lacks?|lacking)[^\n]{0,60}label|placeholder[^\n]{0,100}(?:label|not a substitute|instead)'
---

The inputs with only a placeholder and no label are found (1.3.1, 3.3.2 or 4.1.2, or in words).
