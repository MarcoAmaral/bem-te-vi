---
type: regex
target: last_message
flags: i
pattern: '(?:\bAC[- ]?0?4\b|\bfast\b|loads? quickly)[\s\S]{0,400}?(?:measurable|vague|ambiguous|testable|not specific|not specified|unspecified|undefined|subjective|no (?:threshold|target|metric)|clarif|interpret|assum)'
---

AC-4 ("should load fast") is flagged as not measurable as written, or the threshold used is stated as an assumption.
