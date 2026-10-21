---
type: regex
target: last_message
flags: i
pattern: '^(?=[\s\S]*(?:\bAC[- ]?0?1\b|5\.99))(?=[\s\S]*(?:\bAC[- ]?0?2\b|(?<!non-)(?<!non )(?<!not a )\bmember[\s\S]{0,200}?(?:\bfree\b|\$0(?:\.00)?(?![\d.]))))(?=[\s\S]*(?:\bAC[- ]?0?3\b|12\.99[\s\S]{0,400}?7\.99|7\.99[\s\S]{0,400}?12\.99|express[\s\S]{0,200}?7\.99))'
---

Every acceptance criterion is covered: named by its id, or by what it specifies (AC-1: the $5.99 fee; AC-2: free standard shipping for members; AC-3: the member's $7.99 express fee).
