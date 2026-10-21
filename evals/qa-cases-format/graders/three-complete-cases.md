---
type: regex
weight: 2
target: last_message
flags: m
match: count:3
pattern: '^## TC-[A-Z0-9]+-[0-9]+:.*(?=(?:(?!^#)[\s\S])*?^\|[ \t]*(?:\*\*)?Tags(?:\*\*)?[ \t]*\|[ \t]*[^|\s])(?=(?:(?!^#)[\s\S])*?^\|[ \t]*(?:\*\*)?Issue(?:\*\*)?[ \t]*\|[ \t]*[^|\s])(?=(?:(?!^#)[\s\S])*?^\|[ \t]*(?:\*\*)?Automation Score(?:\*\*)?[ \t]*\|[ \t]*[^|\s])(?=(?:(?!^#)[\s\S])*?^\|[ \t]*(?:\*\*)?ISTQB Technique(?:\*\*)?[ \t]*\|[ \t]*[^|\s])(?=(?:(?!^#)[\s\S])*?^\|[ \t]*(?:\*\*)?Manual Env(?:\*\*)?[ \t]*\|[ \t]*[^|\s])(?=(?:(?!^#)[\s\S])*?^\|[ \t]*(?:\*\*)?Precondition(?:\*\*)?[ \t]*\|[ \t]*[^|\s])(?=(?:(?!^#)[\s\S])*?^\|[ \t]*(?:\*\*)?Steps(?:\*\*)?[ \t]*\|[ \t]*[^|\s])(?=(?:(?!^#)[\s\S])*?^\|[ \t]*(?:\*\*)?Expected(?:\*\*)?[ \t]*\|[ \t]*[^|\s])(?=(?:(?!^#)[\s\S])*?^\|[ \t]*(?:\*\*)?data-testid needed(?:\*\*)?[ \t]*\|[ \t]*[^|\s])(?=(?:(?!^#)[\s\S])*?^\|[ \t]*(?:\*\*)?Note(?:\*\*)?[ \t]*\|[ \t]*[^|\s])(?=(?:(?!^#)[\s\S])*?^\|[ \t]*(?:\*\*)?Source(?:\*\*)?[ \t]*\|[ \t]*(?:ACs?[-_ #.]*[0-9]|Added by QA \([^)]*[^) ][^)]*\)))'
---

Exactly three `## TC-CODE-NNN:` cases each carry all eleven field rows that validate-tc-format.sh
requires, every one with a value, and a Source that names an acceptance criterion or reads
"Added by QA (reason)". A row counts only inside its own case: the block ends at the next heading,
as it does in the hook.
