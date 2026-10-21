---
type: regex
target: last_message
flags: m
match: not_contains
pattern: '^## TC-[A-Z0-9]+-[0-9]+:.*$(?!(?=(?:(?!^#)[\s\S])*?^\|[ \t]*(?:\*\*)?Tags(?:\*\*)?[ \t]*\|[ \t]*[^|\s])(?=(?:(?!^#)[\s\S])*?^\|[ \t]*(?:\*\*)?Issue(?:\*\*)?[ \t]*\|[ \t]*[^|\s])(?=(?:(?!^#)[\s\S])*?^\|[ \t]*(?:\*\*)?Automation Score(?:\*\*)?[ \t]*\|[ \t]*[^|\s])(?=(?:(?!^#)[\s\S])*?^\|[ \t]*(?:\*\*)?ISTQB Technique(?:\*\*)?[ \t]*\|[ \t]*[^|\s])(?=(?:(?!^#)[\s\S])*?^\|[ \t]*(?:\*\*)?Manual Env(?:\*\*)?[ \t]*\|[ \t]*[^|\s])(?=(?:(?!^#)[\s\S])*?^\|[ \t]*(?:\*\*)?Precondition(?:\*\*)?[ \t]*\|[ \t]*[^|\s])(?=(?:(?!^#)[\s\S])*?^\|[ \t]*(?:\*\*)?Steps(?:\*\*)?[ \t]*\|[ \t]*[^|\s])(?=(?:(?!^#)[\s\S])*?^\|[ \t]*(?:\*\*)?Expected(?:\*\*)?[ \t]*\|[ \t]*[^|\s])(?=(?:(?!^#)[\s\S])*?^\|[ \t]*(?:\*\*)?data-testid needed(?:\*\*)?[ \t]*\|[ \t]*[^|\s])(?=(?:(?!^#)[\s\S])*?^\|[ \t]*(?:\*\*)?Note(?:\*\*)?[ \t]*\|[ \t]*[^|\s])(?=(?:(?!^#)[\s\S])*?^\|[ \t]*(?:\*\*)?Source(?:\*\*)?[ \t]*\|[ \t]*(?:ACs?[-_ #.]*[0-9]|Added by QA \([^)]*[^) ][^)]*\))))'
---

No `## TC-CODE-NNN:` case lacks any of the eleven field rows the hook requires, each with a value, and a Source naming an acceptance criterion or `Added by QA (reason)`. A row counts only inside its own case, up to the next heading, as in the hook.
