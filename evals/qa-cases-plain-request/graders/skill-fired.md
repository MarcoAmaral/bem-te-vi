---
type: tool_used
tool: Skill
input_match: '"skill"\s*:\s*"(?:[\w-]+:)?qa-cases"'
---

The plugin arm loaded the `/qa-cases` command on its own, from a request that does not name it.
A plugin-fired indicator: Claude Code reports it in the plugin arm and leaves it out of the score.
