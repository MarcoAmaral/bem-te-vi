---
type: regex
target: last_message
flags: i
pattern: '^(?=[\s\S]*(?:\bAC[- ]?0?1\b|(?:valid|accept\w*|updates? to|success\w*|saved?)[^\n]{0,80}(?<![\d.])(?:1|20)(?![\d.])|(?<![\d.])(?:1|20)(?![\d.])[^\n]{0,80}(?:valid|accept\w*|success\w*|saved)))(?=[\s\S]*(?:\bAC[- ]?0?2\b|Remove this item\?))(?=[\s\S]*(?:\bAC[- ]?0?3\b|You can buy at most 20 of this item))'
---

Every acceptance criterion is covered: named by its id, or by what it specifies (AC-1: 1 or 20 accepted; AC-2 and AC-3: their exact messages).
