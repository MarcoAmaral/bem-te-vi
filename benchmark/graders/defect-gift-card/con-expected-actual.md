---
type: regex
target: last_message
pattern: '^(?=[\s\S]*Gift card: [-−–]€20\.00)(?=[\s\S]*Something went wrong\. Please try again\.)'
---

Both the expected outcome (the summary line) and the actual one (the toast text) are quoted exactly; a typographic minus or dash in place of the hyphen is accepted.
