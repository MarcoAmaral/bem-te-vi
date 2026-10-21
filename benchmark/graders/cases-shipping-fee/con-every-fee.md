---
type: regex
target: last_message
flags: i
pattern: '^(?=[\s\S]*5\.99)(?=[\s\S]*12\.99)(?=[\s\S]*7\.99)(?=[\s\S]*(?:\$0\.00|\$0\b|\bfree\b))'
---

Every fee outcome of the rules appears: free, $5.99, $12.99 and $7.99.
