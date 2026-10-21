# Plan 015: Bring practice from daily QA work back into the package

> **Executor instructions**: This is a catalogue and sequencing plan. Each item marked
> *generalisable* becomes its own change, with tests where it changes behaviour. Nothing in this
> repository may name the employer's clients, products, internal systems, repositories or ticket
> identifiers — carry the practice, never the instance.

## Status

- **Priority**: P1
- **Effort**: L, spread across several changes
- **Depends on**: plan 014 for sequencing; item 3 overlaps plan 016
- **Planned at**: 2026-10-02

## Why this exists

The package is now used in daily QA work at Swareco, where its rules and commands were ported into
a working repository and then customised as real tickets exposed their limits. That repository has
grown its own standard operating procedure, templates, an automation runner and a checker for it —
each written down after something went wrong on a real ticket.

Practice that survives contact with real tickets is worth more to the package than practice written
from first principles, and recording where each improvement came from is part of what makes this
repository useful as monograph evidence. This plan inventories what was learned there, decides what
generalises, and places each item against plan 014.

**Method.** The working repository's project guide, its ticket pipeline SOP, its template folder,
its automation runner standard and its user-behaviour profile were read on 2026-09-29. Each
practice is classified as:

- **Generalisable** — applies to any team; can be written into the package as it stands.
- **Needs abstraction** — the idea generalises, but the instance is tied to one product or tool.
- **Stays local** — product knowledge; it belongs in the working repository, not here.

---

## Item 1 — Test evidence as a deliverable · generalisable · *new, not in plan 014*

`code-style-qa.md` covers how test code is written — locators, Arrange-Act-Assert, no hard-coded
sleeps. It says nothing about **evidence**: what proves to a reviewer that a test ran and passed.
Daily work produced a complete, enforced standard:

- Screenshots are the **viewport** at a fixed size, with the subject in view — never a full
  scrolled page, which yields multi-thousand-pixel strips, and never an element-only crop, which
  loses all context. Both failure modes happened before the rule was written.
- A screenshot is refused unless the visible-pointer overlay and the run banner are present, so a
  reviewer can see where an action landed and which case a frame belongs to.
- Every recorded video gets a review frame extracted from partway through, because **a green run
  is not evidence of the recording**: the recording has to be opened and looked at.
- Evidence file names are ASCII-only. A documentation platform silently dropped uploads whose
  names contained a middle dot, so files could no longer be matched to their rows.
- A skipped test still writes a near-empty recording under the real test's name; recordings below
  a size threshold are never converted, so they cannot overwrite real evidence.

None of this is in ISTQB CTFL v4.0, and none is in the package. It is the most differentiated
practice in the catalogue. **Destination:** a new rule, `.claude/rules/test-evidence.md`, referenced
from `/qa-automate`, with the fixed viewport size as a stated default rather than a hard value.

## Item 2 — Ship a checker, not just a rule · generalisable · *overlaps plan 014 A1*

The working repository's runner standard records why it exists: a rule about the pointer overlay
was broken four times, each time in a new way, **because it was written down and not enforced**.
The answer was a checker that runs before every execution and refuses, with file, line and fix, a
navigation without a stated reason, a local copy of the shared library, a spec that never starts
its evidence page, a bare click, and a full-page or element screenshot.

This is the same failure, and the same remedy, as this repository's own merge-rule incident: a
documented rule missed twice until it was enforced. The package ships about 3,100 lines of prose
rules and enforces exactly one of them (`validate-tc-format.sh`). **Destination:** for this
repository, plan 016's conformance suite. For the package, ship checkers alongside the rules that
can be checked mechanically — item 1's evidence rules first.

## Item 3 — Localhost is a dry run, never a result · generalisable

A local run answers one question per case: *is this test feasible, and what value should it
produce?* That value becomes the oracle the shared environment is compared against. A local pass
signs nothing off. The package has no environment model at all. **Destination:**
`testing-guidelines.md`, beside the test pyramid.

## Item 4 — A release gate, separate from the analysis · generalisable · *overlaps plan 014 B2*

Every ticket gets a **release gate**: the smallest set of cases that answers "do the fixes work,
and did they break anything that already worked?" — usually five to eight. The broader analysis
still happens and is still written down, because that is where findings come from, but it does not
gate the change. Findings the change did not cause never gate it; they become their own tickets.
Separating the two is what keeps delivery fast without losing depth, and lets a reviewer see in one
table what actually has to pass.

The package has priority tags and coverage targets but no notion of a gate distinct from the full
analysis. **Destination:** `skills/qa-plan` (whose entry and exit criteria it sharpens) and
`/qa-cases`. This is plan 014 B2's "when to stop" question, answered from practice.

## Item 5 — Template completeness · generalisable

Every field a template defines must appear in what is generated from it, even with nothing to put
there: write "N/A" or "Not applicable — *why*" and keep the row. A field silently missing from a
generated document is a defect in that document, not a shortcut. **Destination:** the test-case,
defect and test-plan commands, and `validate-tc-format.sh`, which can check it.

## Item 6 — Derive, don't override · generalisable

When a target repository already has a schema for some artifact — a tool's field contract, a
template the team uses — the schema owns field names, order and allowed values, and the package's
rules own *how the content is produced*. Neither rewrites the other; on a genuine conflict the
assistant says so and asks. `linting-standards.md` applies this idiom to lint configuration only.
For a package installed into other people's repositories it should be general. **Destination:** a
short section in `context-discovery.md`.

## Item 7 — Correct, don't delete · generalisable

Nothing found wrong in a working document is deleted. It is corrected in place with a dated,
attributed note, or struck through with a note explaining why. This is stronger than this
repository's "record rejected approaches", and plan 014's own corrections of 2026-10-01 follow it.
**Destination:** the documentation-producing commands, and `CONTRIBUTING.md` for this repository.

## Item 8 — Field heuristics · generalisable

Short, hard-won rules from the SOP's "what experience has added", worth carrying nearly verbatim:

- **Always test the positive half too.** A guard that refuses everything passes every negative
  test while being badly broken.
- **Capture irreversible states first.** Some evidence windows close permanently — a balance that
  reads wrong only until a payment applies.
- **Confirm what an environment runs from its deployment record, not its branch name.** A branch
  called `staging` may track the release line rather than the staging environment. This refines
  `context-discovery.md` tier 1 with *deployed state* as a distinct source.
- **A change to shared state during testing is a write.** Announce it, record the original state
  and time, and restore it.
- **Write a run sheet as a linear, numbered script.** Someone executing at speed should never have
  to jump between sections; repeating a value inline beats a cross-reference.
- **Mark clearly where to stop** when later stages are blocked, so nobody starts a pass they
  cannot finish.
- **Pace recordings.** An unpaced automated run finishes in seconds and is unwatchable.

**Destination:** `testing-guidelines.md` and `skills/qa-explore`.

## Item 9 — Reach every screen through the interface · needs abstraction

Automation that navigates as a user does — the page's own back link rather than the browser's,
search submitted from the field, forms filled with Tab, toasts read before they are cleared —
finds bugs that direct URL navigation hides. Daily work found one: client-side navigation broke an
assertion that a direct `goto` never exercised. The principle generalises; the observed behaviour
profile is one product's. **Destination:** a short principle in `/qa-automate`, plus guidance on
capturing a behaviour profile for the product under test.

## Item 10 — A ticket folder as the unit of work · needs abstraction

Everything for a ticket lives in one portable folder — plan, cases, run sheet, evidence, data
requests, draft comments — so the work is inspectable at any stage and nothing lives only in
someone's head. The exact file list is one team's; the principle, and a minimal default layout,
generalise. **Destination:** the `/qa-agentic` pipeline, which already writes staged files and could
adopt a documented folder convention.

## Item 11 — Publishing contracts · needs abstraction

A target platform's constraints (table widths, image sizes, ASCII-only names) are a field contract
like item 6. The constraints are platform-specific; the habit of writing them down once, in the
template, is not. **Destination:** a note in item 6's section, with ASCII-only file names as the
one constraint worth stating generally.

## Stays local

Product navigation paths and selectors, the product's menu structure, its admin tools, the
company's internal QA tool and its schema, client and project names, ticket and repository
identifiers, and credentials. They are the instances; items 1-11 are what they taught.

---

## Sequencing against plan 014

| Order | Item | Why here |
| --- | --- | --- |
| 1 | 2 → plan 016 | The conformance suite is plan 014's top stability item already |
| 2 | 8, 3 | Small, high-value text; no design needed |
| 3 | 1 | The genuinely new rule; ship its checker with it |
| 4 | 4, with plan 014 B2 | Answers B2's "when to stop" from practice |
| 5 | 5, 6, 7 | Conventions; 5 can be enforced by the existing hook |
| 6 | 9, 10, 11 | Need abstraction first |

## Verification

- Every change that alters behaviour carries a test; every change to `.claude/` regenerates the
  adapters and passes `tests/verify-adapters.sh`.
- Before each change merges, grep it for the employer's client, product, system and repository
  names and ticket prefixes. None may appear.
