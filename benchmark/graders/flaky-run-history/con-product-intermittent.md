---
type: regex
target: last_message
flags: i
pattern: '(?:latest order|orders >|#1043)[\s\S]{0,600}?(?:product (?:defect|bug|issue)|real (?:defect|bug)|application (?:defect|bug)|backend|server[- ]side|replica|race condition|stale|consisten|write[- ]read lag|cach)'
---

The latest-order test is traced to the product, not the test: the API or backend returns the list without the new order for a time (stale data, a race, replication or caching).
