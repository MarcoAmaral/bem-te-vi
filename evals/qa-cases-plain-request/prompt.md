---
description: >-
  The same story and format checks as qa-cases-format, asked for in plain words with no slash
  command. It measures whether the qa-cases description makes Claude Code load the command on a
  request for test cases; without it, the reply cannot have the package's format.
expected_outcome: >-
  The plugin arm calls the Skill tool for qa-cases, and its reply starts with the frontmatter block
  (feature, feature_code, tc_count, tracker_issues, risk_level, runbook, implementation_pack, spec,
  last_updated) and holds exactly three "## TC-CODE-NNN:" cases, each with all eleven field rows
  filled and a Source that names an acceptance criterion or "Added by QA (reason)".
tags: [qa-cases, format, triggering]
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

Write formal test cases for the user story below. Write exactly three test cases. Reply with the
test-case document only, as Markdown, starting at its first line, with no introduction and no code
fence around it.

Story PWD-7: As a registered user, I want to reset my password by email, so that I can sign in
again when I forget it.

- AC-1: Submitting a registered email on the "Forgot password" form shows "If that email is
  registered, a reset link has been sent."
- AC-2: The reset link expires 30 minutes after it is sent.
- AC-3: The new password must be 8 to 64 characters long.
