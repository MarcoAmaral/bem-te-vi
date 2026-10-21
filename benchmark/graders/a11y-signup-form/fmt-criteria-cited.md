---
type: regex
target: last_message
pattern: '^(?=[\s\S]*\b1\.1\.1\b)(?=[\s\S]*\b3\.1\.1\b)(?=[\s\S]*\b(?:1\.3\.1|3\.3\.2|4\.1\.2)\b)(?=[\s\S]*\b2\.1\.1\b)(?=[\s\S]*\b2\.4\.3\b)(?=[\s\S]*\b2\.4\.7\b)'
---

Every seeded barrier is reported under its WCAG criterion number (1.1.1, 3.1.1, 1.3.1 or 3.3.2 or 4.1.2, 2.1.1, 2.4.3, 2.4.7), as the package's findings format requires.
