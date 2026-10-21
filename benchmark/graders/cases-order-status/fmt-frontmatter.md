---
type: regex
target: last_message
flags: m
pattern: '(?<![\s\S])-{3}\r?\n(?=(?:(?!^-{3}[ \t]*\r?$)[\s\S])*?^feature:)(?=(?:(?!^-{3}[ \t]*\r?$)[\s\S])*?^feature_code:)(?=(?:(?!^-{3}[ \t]*\r?$)[\s\S])*?^tc_count:)(?=(?:(?!^-{3}[ \t]*\r?$)[\s\S])*?^tracker_issues:)(?=(?:(?!^-{3}[ \t]*\r?$)[\s\S])*?^risk_level:)(?=(?:(?!^-{3}[ \t]*\r?$)[\s\S])*?^(?:runbook|cdt):)(?=(?:(?!^-{3}[ \t]*\r?$)[\s\S])*?^implementation_pack:)(?=(?:(?!^-{3}[ \t]*\r?$)[\s\S])*?^spec:)(?=(?:(?!^-{3}[ \t]*\r?$)[\s\S])*?^last_updated:)(?:(?!^-{3}[ \t]*\r?$)[\s\S])*?^-{3}[ \t]*\r?$'
---

The reply starts with the frontmatter block `validate-tc-format.sh` requires: `---` on the first line, the nine keys it checks (`runbook` or its old name `cdt`), and a closing `---`. Restated from `evals/qa-cases-format` (plan 037).
