---
type: regex
target: last_message
flags: i
pattern: '(?:filters results by tag|search >|summer)[\s\S]{0,600}?(?:shared (?:data|state|tag|fixture|test data)|isolation|order[- ]dependen|data collision|interfer|parallel|collid)'
---

The search test is traced to data shared with another spec (isolation, order or parallel runs).
