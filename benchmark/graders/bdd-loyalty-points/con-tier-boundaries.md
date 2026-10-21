---
type: regex
target: last_message
pattern: '^(?=[\s\S]*(?<![\d.,])499(?![\d.,]))(?=[\s\S]*(?<![\d.,])500(?![\d.,]))(?=[\s\S]*(?<![\d.,])1,?999(?![\d.,]))(?=[\s\S]*(?<![\d.,])2,?000(?![\d.,]))'
---

Both tier boundaries are tested on both sides: 499 and 500, 1,999 and 2,000.
