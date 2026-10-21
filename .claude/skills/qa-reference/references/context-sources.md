---
id: ref-context-sources
---
# Context Sources Reference

> **Read on demand** | Detail behind the `context-discovery` rule | Part of the `qa-reference` skill

The rule says which sources to search and in what order. This file says how to read the sources
that need more than a line: what to look for, how much to trust it, and what to do when it
disagrees with the ticket. When this file and the rule seem to disagree, the rule wins.

---

## 📐 A Spec Directory

Some repositories keep their specifications in a dedicated folder, often hidden at the root and
created by a spec-driven development tool — a spec directory such as `.specify/`. Treat it as a
requirements source; never depend on it.

- **Detect, do not assume.** Look for a hidden spec directory at the repository root, or a
  specification folder the project guide or README points to. Read what is actually in it. Do not
  expect particular file names inside it, and do not refer to any tool's command names: both
  change between versions of the tools that create them.
- **Read it before re-deriving requirements from the ticket.** The specification's identified
  requirements, acceptance scenarios and success criteria are the authoritative statement of
  intent. Keep the identifiers it already uses (`FR-001`, `SC-002`, `AC-3`) rather than
  renumbering, so a test can be traced back to the line it came from.
- **A project-principles file inside it** (sometimes called a constitution) states rules the team
  has declared for its own work. Read it as a constraint on what you produce. It is the parallel
  of this package's shipped rules, which act as a QA constitution: a team that wants a rule
  stricter or relaxed for its project says so in its own project guide, which assistants already
  read, rather than editing the installed rule files.
- **It is still declared intent** (Tier 3): nothing enforces it. Where it disagrees with the code
  or a test, Tier 1 wins for current behaviour and the disagreement is a finding.
- **A spec and the ticket disagree**: report both statements and ask which one is current. Do not
  silently follow the newer-looking one.
- **Never write into it.** The specification belongs to its author and to the tool that manages
  it. Report findings; the author edits.
- **Absent or unfamiliar**: carry on with the other sources. Nothing here may fail, or ask the user
  to install a tool, because a repository has no spec directory.

---

## 🗂️ The Tracker Records What Was Tested

For the question *"was this tested, and with what result?"*, the issue tracker — ticket status,
linked test runs, test-management records, result comments — is the source of truth, not the
documentation. Documentation pages are written after the fact and lag behind: a ticket can be
fully tested with no test-plan page, and a page can describe tests that never ran.

- **Read the tracker first for test status.** For this question treat tracker records as a
  Tier 2 source, not Tier 4 background. Say which records or which query you read.
- **Sweep the tracker for suite-level traceability.** When building a traceability or status
  matrix across many tickets, query the tracker directly rather than collecting documentation
  pages; a missing page is not evidence of a missing test.
- **The tracker and the documentation disagree**: the tracker wins for what was tested; report the
  page that says otherwise as documentation drift, with both statements.
- **Neither has it**: say the test status is unknown. Never read silence as "tested" or "passed".

---

## 🧭 Feature-Area Knowledge Files

Some teams keep one living file per product feature area — how it behaves, which test data works,
known pitfalls, related tickets — so the next ticket in that area starts from what the last one
learned.

- **Find them.** Look for a folder of per-area notes, or a link from the project guide, the README
  or the ticket folder. Pick the file for the area the ticket touches; read related areas only when
  the ticket crosses into them.
- **Read it before designing tests.** It is the fastest route to the pitfalls a newcomer would
  miss. It is still declared intent (Tier 3): verify a behaviour it describes against Tier 1 before
  writing it into an `Expected` field, and report a mismatch as documentation drift.
- **Offer additions, do not impose the practice.** When the work teaches something new about the
  area (a pitfall, a data constraint, a surprising behaviour), propose the addition to the user.
  If the repository keeps no such files, do not create the convention unasked.

---

## 🙋 Before You Ask

A blocked question is a defined step, not a wait. Work through it in order:

1. **Can it be answered now, without anyone?** Read the code, run the feature locally, check the
   existing tests, the deployment record or the tracker. If that settles it, cite the source and
   carry on.
2. **Look where the answer usually is** before asking: the search tiers in the rule, the ticket's
   comments and linked tickets, the feature-area file, earlier tickets in the same area.
3. **Leave the work ready for the answer.** Write the test with the open point marked as an
   assumption or a clearly marked placeholder, so the answer only fills a value. Continue with
   everything the question does not block.
4. **Route it to the owner of the answer**: expected behaviour and business rules to product;
   implementation, technical limits and data shape to development; environments, access and test
   data provisioning to whoever runs them.
5. **Ask so the answer comes back usable.** One question per point; say what you already checked;
   offer the options you see (A or B) and what you will assume if there is no answer; prefer a
   question that can be answered in one line.
6. **Record question and answer where the next person will find them**: the ticket, or the ticket
   folder's `comments.md` draft. An answer given only in a chat is lost.

---

## 📰 Publishing to a Shared Platform: Lint, Review, Build, Verify

A test plan, results page or report that ends up on a shared documentation platform goes through
four gates. The platform and its limits are the team's (see "Derive, Don't Override" in the rule);
the gates are the same everywhere.

1. **Lint.** Draft in plain Markdown, in the repository or the ticket folder. That draft is the
   only version a person reviews. Run the team's Markdown linter and check the platform
   constraints written in the team's template before handing it over.
2. **Review.** A person reads and approves the Markdown. Nothing is published before approval.
3. **Build.** Only after approval, convert the Markdown into the platform's format. Never hand-edit
   the built output: fix the Markdown and build again, so the reviewed text and the published text
   cannot drift apart.
4. **Verify.** Before writing, keep a copy of the page as it is now. After writing, read the page
   back from the platform and compare it with what was sent. Keep the before-copy, the body sent
   and the read-back side by side with a short sync log (date, page, outcome), so a bad write can
   be undone and audited.

Publishing changes shared state that other people read: ask before the write, as for any other
write outside the working copy.
