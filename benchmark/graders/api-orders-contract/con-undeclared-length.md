---
type: regex
target: last_message
flags: i
pattern: 'maxLength|max(?:imum)? length|length limit|no (?:upper )?(?:length )?limit|unbounded'
---

The schema declares no maximum length for `note`, while the server enforces one.
