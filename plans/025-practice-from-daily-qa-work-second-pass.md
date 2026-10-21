# Plan 025: Practice from daily QA work, second pass

> **Executor instructions**: Nothing here is approved yet. Each item is a candidate for Marco to
> accept, defer or reject. Implement an accepted item as its own pull request, with the checks the
> repository's CI runs. Never name the employer's clients, products, internal systems, people,
> repositories or ticket identifiers in anything this repository ships or records — the same rule as
> plan 015.

## Status

- **Priority**: P1 (decide before launch; build after, unless Marco says otherwise)
- **Effort**: varies per item, from S to M
- **Depends on**: plan 015 (first pass, all items shipped), plan 024 (Spec Kit second look)
- **Planned at**: 2026-10-12

## Why this exists

Plan 015 read the working repository at Swareco on 2026-09-29 — its project guide, ticket SOP,
templates, runner *standard* and user-behaviour profile — and all eleven of its items have shipped.
It did not read the runner *code*, the process SOPs, the suite-level documents or anything written
since. The working repository has kept growing through daily use: on 2026-10-12 it held **57 ticket
folders**, a shared Playwright runner library with a standard enforced by a checker, suite-level
traceability and status matrices, process SOPs, a question-routing guide, a test-data fixture guide,
and per-feature-area knowledge files. It also uses GitHub Spec Kit (ten Spec Kit skills installed
beside this package's commands, and one specification for its own tooling work).

As with plan 015, practice that survived contact with real tickets is worth more than practice
written from first principles, and each item below records the incident or decision it came from,
in general terms.

**Method.** On 2026-10-12, read-only: the working repository's project guide, its ticket pipeline
SOP, its pre-development analysis SOP, the runner library's standard checker and its rule list, the
suite-level traceability and status matrices, the question-routing guide, and the folder structure of
its QA area. Nothing was copied out. Classification as in plan 015: **generalisable**, **needs
abstraction**, **stays local**.

---

## Item 1 — Label what QA added · generalisable

Every scenario or test case names its **source**: the acceptance criterion it checks, or
"**Added by QA** (<reason>)" when QA added it beyond the ticket. Business rules QA inferred start with
"Added by QA." In the working repository a linter refuses a scenario with no source, and refuses
vaguer labels ("added by me").

Why it matters: a reviewer, a product owner and a developer can see at a glance which tests the
ticket asked for and which ones QA added — the scope conversation the package's release gate (plan
015 item 4) depends on, and ISTQB traceability between test basis and tests (CTFL v4.0 §1.4.4).

**Destination:** `/qa-cases`, `/qa-bdd`, the qa-writer contract, and the TC hook (a case's **Note**
or a new **Source** row must name an AC or "Added by QA (…)" — decide which in the PR; changing the
template is a TC-format change and must go through `tests/test-tc-contracts.sh`).

## Item 2 — A runner standard enforced by a checker · generalisable

The working repository's automation runner refuses to start when a spec breaks its standard. Each
rule exists because it was once only written down and then broken on a real ticket:

| Rule | What it refuses | Why (the incident, in general terms) |
| --- | --- | --- |
| R1 | `page.goto(` without a `goto-ok: <reason>` comment | Direct navigation hid a frozen pointer and a client-side routing bug |
| R2 | A local copy of the shared helper library | A copied library drifted from the shared one |
| R3 | A test that does not start with the evidence-page setup | The pointer overlay was attached after the first navigation, so early frames had none |
| R4 | Overlay/banner setup calls inside a spec | The library owns setup; specs re-doing it diverged |
| R5 | A bare `.click(` instead of the library's `click(page, target)` | A bare click teleports; the recording shows no pointer path |
| R6 | Full-page or element-only screenshots | Unreadable strips and context-free crops (already shipped: plan 015 item 1) |
| R7 | Per-runner login sessions | Fifteen copies of one admin login, one per ticket, lapsing separately |

A file can opt out of R1, R3 and R5 as a **probe** (reconnaissance, never evidence) with a first-line
comment, and a probe may not capture evidence.

The package ships R6 only (`.claude/hooks/check-test-evidence.sh`), and states R1/R5's intent as prose
in `/qa-automate` (plan 015 item 9). **Destination:** extend `check-test-evidence.sh` with R1 and R5
(configurable function names, since "the library's click" is project-specific), add the
probe-versus-evidence distinction to `.claude/rules/test-evidence.md`, and state R2/R4/R7 as one
principle in `/qa-automate`: one shared helper library, never copied, with session setup owned by it.

## Item 3 — Generate a runner, never copy the last one · needs abstraction

Every new ticket runner is created by one command that writes a thin runner (a run script, a
re-export of the shared library, the specs); copying a previous ticket's runner is forbidden, and
shared behaviour is fixed once in the library. The instance is one team's tooling; the principle —
scaffold from a template and keep shared code in one place, so a fix reaches every runner — is
general. **Destination:** a short section in `/qa-automate`.

## Item 4 — Pre-development analysis (three amigos) · generalisable

A written SOP for analysing tickets **before** development, as a timed three-role conversation
(product, QA, development): ticket tiers that decide depth, preparation per role with deadlines,
about 5–8 minutes per ticket in the meeting, explicit roles, and a fixed analysis document with six
sections. It is the shift-left step the package's `/qa-refinement` and `/qa-static` approach from
different sides, and it maps onto ISTQB's early and frequent stakeholder feedback (CTFL v4.0 §3.2.1)
and the review roles and types (§3.2.3, §3.2.4 — an informal review or walkthrough with named roles).

**Destination:** decide between a new `/qa-predev` command and a "three amigos" review preset inside
`/qa-static` (preferred: reuse `/qa-static`'s roles and process, add the tiering and the timed
agenda). Verify the section numbers against the syllabus before citing them.

## Item 5 — Report every case's outcome, honestly named · generalisable

The working repository's results pages list **every case, one per row** — pass, fail, blocked, not
run, verified by a developer, dropped — with what each proves and where it was checked, plus a
**"Not run — resume point"** section so someone else can pick the work up. QA's own scripted runs
are never called "automated"; "automated" means a test in the team's automation suite. A results
page's title repeats the ticket's summary verbatim, so tracker and documentation stay traceable.

This sharpens the completion report the package already describes (`skills/qa-plan`, CTFL v4.0
§5.3.2). **Destination:** `skills/qa-plan` (completion report) and `/qa-cases` (result columns).

## Item 6 — A publishing pipeline: lint, review, build, verify · needs abstraction

Documents destined for a shared documentation platform are drafted as plain Markdown (the only thing
the human reviews), linted before handover, built into the platform's format only after approval,
and verified by reading the published page back — with a copy of the page before the write, the body
sent and the page read back kept beside a sync log. The platform and its sizes are one team's; the
pipeline is general and extends plan 015 item 11 (publishing contracts).
**Destination:** a section in `.claude/rules/context-discovery.md`'s "Derive, Don't Override", or a
small `test-reporting` rule if items 5 and 6 together justify one.

## Item 7 — Suite-level artifacts, verified against the tracker · generalisable

Beyond ticket documents, the working repository keeps a master test plan, a risk register, a tagging
standard, a **traceability matrix** and a **status matrix**, filterable by suite. Its traceability was
confirmed by sweeping the issue tracker directly, because the documentation platform lagged the
tracker: most confirmed tickets had no test-plan page at all.

Two generalisable points: suite-level traceability and status are deliverables, not just ticket-level
ones; and **the tracker, not the documentation, is the source of truth for what was tested** — a
refinement of `context-discovery.md`'s tiers. **Destination:** `skills/qa-plan` (suite artifacts),
`context-discovery.md` (tracker over documentation), and plan 024's traceability-command candidate,
which this is real-world evidence for.

## Item 8 — Feature-area knowledge · needs abstraction

One living file per product feature area, collecting what QA learned there: behaviour, data,
pitfalls, related tickets. The next ticket in that area starts from it. The content is product
knowledge (stays local); the practice — keep per-area QA knowledge and read it first — is general.
**Destination:** `context-discovery.md` (a feature-area knowledge file is a source to read), and the
ticket folder convention in `/qa-agentic` (link the area file).

## Item 9 — Before you ask: question routing · generalisable

A decision tree for a blocked tester: what QA can do itself today, where to look before asking, how
to leave the work ready for the answer, and how to ask so the answer comes back usable. It turns
"waiting on someone" into a defined step. **Destination:** `.claude/rules/context-discovery.md`
("When context is missing") or `skills/qa-explore`.

## Item 10 — Test data as a documented fixture set · generalisable

A guide to the shared test environment's known fixtures (which records exist, what state they are
in, what may be changed), so tests start from known data and shared state is not disturbed (plan 015
item 8's "a change to shared state is a write"). **Destination:** `skills/qa-plan` (test data
management) and `testing-guidelines.md`.

## Item 11 — Process SOPs and handover · stays local, with one general lesson

Bug and hotfix process drafts, an epic testing plan SOP, periodic tracker sweeps, a ticket index
with a status snapshot, and a handover document for a colleague. These are one team's process. The
general lesson worth one line in `skills/qa-plan`: keep a **handover-ready** state (index, status,
resume points), so QA work can change hands without loss.

## Item 12 — Spec Kit in real use · input to plan 024

The working repository installs ten Spec Kit skills (analyze, checklist, clarify, constitution,
converge, implement, plan, specify, tasks, tasks-to-issues) next to this package, and has one
specification for its own QA-tooling work. That is evidence for plan 024: QA uses Spec Kit for its
tooling, and both sets of skills coexist in one project. **Destination:** plan 024's decisions; and
check that this package's command and skill descriptions do not collide with Spec Kit's in the same
listing.

## Stays local

Product, client and system names; the internal QA tool and its field schema; the documentation
platform's page sizes; issue-tracker project keys and identifiers; people and their roles; staging
URLs, fixtures and credentials; vendor integrations in the runner library. They are the instances;
items 1-12 are what they taught.

---

## Sequencing

| Order | Items | Why |
| --- | --- | --- |
| 1 | 1, 5 | Small, high value, and they make test documents reviewable at a glance |
| 2 | 2 | Extends a checker that already ships; each rule has a real incident behind it |
| 3 | 4 | The largest new capability; reuse `/qa-static` |
| 4 | 7, 8, 9, 10 | Text additions to existing skills and rules |
| 5 | 3, 6 | Need abstraction first |
| — | 11, 12 | One line in `qa-plan`; input to plan 024 |

## Verification

- Each accepted item: the repository's CI check list; for item 1, `tests/test-tc-contracts.sh` and
  the TC hook updated together; for item 2, red-then-green fixtures for each new checker rule.
- Grep every change for employer-specific terms before committing, as plan 015 required.
- **STOP: Marco decides which items to build, and whether before or after the public launch.**
