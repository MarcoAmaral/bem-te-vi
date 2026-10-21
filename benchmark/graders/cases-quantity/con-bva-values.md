---
type: regex
target: last_message
pattern: '^(?=[\s\S]*(?<![\d.])0(?![\d.]))(?=[\s\S]*(?<![\d.$])1(?![\d.]))(?=[\s\S]*(?<![\d.$])20(?![\d.]))(?=[\s\S]*(?<![\d.$])21(?![\d.]))'
---

Two-value boundary value analysis of the 1 to 20 range: the values 0, 1, 20 and 21 all appear (CTFL v4.0.1 section 4.2.2).
