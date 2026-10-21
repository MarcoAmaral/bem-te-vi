---
type: regex
target: last_message
flags: i
pattern: 'avatar[\s\S]{0,300}?(?:not flaky|deterministic|consistent(?:ly)? fail|fails? (?:in )?(?:every|all|10 of 10|10/10|consistently|always)|always fails)|(?:not flaky|deterministic)[\s\S]{0,300}?avatar'
---

The avatar test, which fails in every run, is kept apart as a deterministic failure, not called flaky.
