---
type: regex
target: last_message
flags: im
pattern: '^[^\n]*Title[^\n]{0,12}?[:|][^\n]*\S\s[–—-]\s\S'
---

The title starts with the component, then a dash, then what failed, as the package's title rule asks (`[Component] – [What failed] when [condition]`). The `when` clause is not required, because two of the command's own good titles omit it.
