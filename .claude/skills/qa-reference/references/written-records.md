---
id: ref-written-records
---
# Written Records Reference

> **Read on demand** | The two conventions every shipped document follows | Part of the `qa-reference` skill

Read this when a template field has nothing to put in it, or when something in a document that has been shared turns out to be wrong. Test cases, defect reports, test plans and the pipeline's test cases all follow it.

---

## Every Field, Every Record

Every field the template defines appears in every record you write. When a field does not apply, or does not apply yet, keep it and write `N/A — <why>` (for example `N/A — no UI element is asserted`, `Root Cause : N/A — not yet analysed`, `Related Defects : N/A — none found`). There is one spelling: the em dash and a reason. A bare `N/A` is not enough, because the reader cannot tell "considered and empty" from "forgotten".

A field that is silently missing is a defect in the generated document, not a shortcut. This applies to frontmatter keys, to every row of a risk register and to every column of a release gate table. The package's `validate-tc-format.sh` checks test cases: an omitted row or an empty cell fails, `N/A — <reason>` passes.

If the target repository's tracker or template already defines its own schema, that schema owns the field names, order and allowed values (see the `context-discovery` rule, "Derive, Don't Override"); this convention owns how each field is filled.

## Correct, Don't Delete

Nothing found wrong in a record that has been shared or filed is deleted. Correct it in place, in one of two forms:

- **A dated, attributed correction note** next to the original: `Correction, YYYY-MM-DD, <author or agent>: <what was wrong and what is right>`.
- **Strike-through with a reason**: `~~old text~~ (superseded YYYY-MM-DD: <why>)`.

This covers a wrong severity, a misread root cause, a reproduction that turned out to be intermittent, a re-assessed risk score, a revised estimate, a gate case that moves in or out of the gate. The history of what was believed, and when it changed, is part of the record: it is what lets a later reader audit a decision. Before a record is first shared, ordinary editing is fine.
