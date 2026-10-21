---
type: regex
target: last_message
flags: i
pattern: '^(?=[\s\S]*(?:\bAC[- ]?0?1\b|\bPlaced\b[^\n]{0,80}\bPaid\b))(?=[\s\S]*(?:\bAC[- ]?0?2\b|\bPaid\b[^\n]{0,80}\bShipped\b))(?=[\s\S]*(?:\bAC[- ]?0?3\b|\bShipped\b[^\n]{0,80}\bDelivered\b))(?=[\s\S]*(?:\bAC[- ]?0?4\b|\b(?:Placed|Paid)\b[^\n]{0,120}\bCancell?ed\b))(?=[\s\S]*(?:\bAC[- ]?0?5\b|Shipped orders cannot be cancell?ed))'
---

Every acceptance criterion is covered: named by its id, or by what it specifies (the state change on one line, or AC-5's exact message).
