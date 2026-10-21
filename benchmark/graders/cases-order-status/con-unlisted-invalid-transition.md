---
type: regex
target: last_message
flags: i
pattern: '(?:attempt|cannot|can''t|can ?not|refus|reject|invalid|not allowed|not permitted|prevent|block|disallow)[^\n]{0,160}(?:non-?paid|unpaid|not (?:yet )?paid|without (?:a )?payment|non-?shipped|not (?:yet )?shipped|already (?:delivered|cancell?ed)|\b(?:Delivered|Cancell?ed) order|\bship\w*\s+(?:a |an |the )?(?:Placed|unpaid|non-?paid)\b|\bdeliver\w*\s+(?:a |an |the )?(?:Placed|Paid|unpaid)\b|\b(?:pay|payment)\w*\s+(?:on |for |to )?(?:a |an |the )?(?:Shipped|Delivered|Cancell?ed)\b)|(?:non-?paid|unpaid|not (?:yet )?paid|without (?:a )?payment|non-?shipped|not (?:yet )?shipped|already (?:delivered|cancell?ed)|\b(?:Delivered|Cancell?ed) order|\bship\w*\s+(?:a |an |the )?(?:Placed|unpaid|non-?paid)\b|\bdeliver\w*\s+(?:a |an |the )?(?:Placed|Paid|unpaid)\b|\b(?:pay|payment)\w*\s+(?:on |for |to )?(?:a |an |the )?(?:Shipped|Delivered|Cancell?ed)\b)[^\n]{0,160}(?:attempt|cannot|can''t|can ?not|refus|reject|invalid|not allowed|not permitted|prevent|block|disallow)'
---

A case for an invalid transition the ACs do not list (AC-5 lists only cancelling a Shipped order): shipping an unpaid order, delivering one that was not shipped, paying or cancelling a Delivered or Cancelled order. The line must say the action is attempted or refused. State transition testing covers invalid transitions, not only the valid ones (CTFL v4.0.1 section 4.2.4).
