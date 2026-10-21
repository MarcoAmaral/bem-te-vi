# Example: `qa-a11y` on the ServeRest front end

The audit is [`a11y/audit.md`](a11y/audit.md), with the evidence in [`a11y/evidence/`](a11y/evidence/) and the raw axe-core results and measurements in [`a11y/raw/`](a11y/raw/). The Playwright specs that produced them are in [`playwright/`](playwright/), and the real run is in [`run-output.txt`](run-output.txt).

```text
qa-a11y/
├── README.md
├── package.json
├── playwright.config.ts
├── run-output.txt                      # the real run, list reporter
├── a11y/
│   ├── audit.md                        # scope, axe triage, manual checks, findings, claim
│   ├── evidence/                       # 21 viewport screenshots, 1440 x 900
│   └── raw/                            # axe-core results per page and state, manual measurements
└── playwright/
    ├── support/evidence.ts             # pointer overlay, case label, viewport screenshot helper
    └── tests/
        ├── axe-scan.a11y.spec.ts       # step 2: eight scans, four result groups kept
        ├── manual-checks.a11y.spec.ts  # step 3: keyboard, focus, targets, zoom, errors
        └── finding-evidence.a11y.spec.ts  # step 4: one screenshot per finding
```

## Task

```text
Audit the accessibility of the ServeRest front end (https://front.serverest.dev) against WCAG 2.2 AA with the qa-a11y skill: the login page and the sign-up ("cadastro") page, in their default and validation-error states. The run is read-only: do not create, change or delete anything on the site.
```

The task was set by the plan for this skill, not typed into an installed agent. The plan also listed a successful sign-up as a state; the read-only instruction dropped it (see the limits).

## Run details

| Item | Value |
| ---- | ----- |
| Date | 2026-10-18 |
| Package version | 4.0.1 plus the changes merged on the `next` branch since that release (the `qa-a11y` skill and the axe-core template fix are in this same branch) |
| Skill followed | `qa-a11y/SKILL.md`, five steps |
| Model | An AI coding assistant following the skill file (Claude Sonnet 5.5, `claude-sonnet-5-5`) |
| Tooling | Node v24.16.0, `@playwright/test` 1.64.1, `@axe-core/playwright` 4.14.0 (axe-core 4.14.0), Chromium 156.0.8078.4, TypeScript 5.9.3 |
| Target | `https://front.serverest.dev` (HTTP 200 on the run date), front-end bundle `main.63e8c0e3.chunk.js`, API at `https://serverest.dev` |
| Run | 15 specs, 15 passed in 51 seconds, headless Chromium, no video |

To rerun: `npm install`, `npx playwright install chromium`, `npx playwright test`. There is no lock file, so a rerun may install newer versions than the ones above, and ServeRest may have changed.

## ServeRest's Portuguese

The pages are in Portuguese. Quoted strings are verbatim because the checks depend on them; `audit.md` carries the glosses (`Cadastre-se` is sign up, `Entrar` is log in, `Email é obrigatório` is email is required).

## Result

Nine failures on the two pages, none marked blocking because no blocking threshold was given. Where each came from:

- **axe-core violations (4):** the logo without `alt`, low-contrast prompt text, low-contrast administrator label, low-contrast error text.
- **axe-core `incomplete`, resolved by hand (1):** the `×` close glyph in the error alerts, 2.17:1. A test that asserts `violations` alone would never have read it.
- **Only by hand (4):** the "sign up" and "log in" switch controls are `<a>` elements with no `href`, so the keyboard never reaches them; `lang="en"` on Portuguese content, which axe passes; the 1.49:1 field border; the 1.19:1 to 1.34:1 focus ring.

The conclusion in `audit.md` says the pages do not meet WCAG 2.2 AA, and says nothing is conformant: it lists the criteria checked by the scanner and by hand, the ones only by hand, the four not applicable, and what was not checked at all.

## How each success criterion fared

| Criterion written before the run | Result |
| -------------------------------- | ------ |
| `audit.md` lists scope, target, threshold, tool versions, date and build | Met. The threshold is recorded as not given |
| Every axe result group is triaged; every `incomplete` item has a verdict | Met: 10 incomplete nodes in 2 rules (5 close glyphs, 5 close buttons), each with a verdict |
| Manual checks cover keyboard-only completion of both forms, focus visibility, error identification (3.3.1) and target size (2.5.8) | **Partly met.** Login was completed by keyboard to the API's answer. Sign-up was driven by keyboard to the browser's own validation, which stopped it; a sign-up was never completed. The other three are met |
| Every finding names its criterion and has a viewport screenshot that meets the evidence rule | Met, with the limits below |
| `check-test-evidence.sh` runs clean on the specs | Met, plain and with `--runner-standard`: both print `clean (4 files)` |
| The conclusion says which criteria were not checked | Met |

## Honest limits

- **The sign-up success state was not audited.** Creating a user on a public practice service is a write, and the run was read-only. Every other page state and the pages behind login are also unaudited. The audit lists them as such.
- **Keyboard-only sign-up was not completed.** It stops where the browser's own email validation stops it (no request was sent).
- **Every non-GET request was refused.** Four POSTs from the manual specs and two from the scans, all answered 400 (`a11y/raw/`). Both specs fail if any non-GET answer is 2xx. No user was created.
- **No screen reader, no colour-blindness simulation, one browser.** Whether the `role="alert"` messages are announced is not checked. Only Chromium ran; Firefox and WebKit may differ.
- **200% zoom is emulated.** It is a 720 x 450 CSS viewport at device scale factor 2, which reflows like browser zoom and still yields a 1440 x 900 screenshot. It is not the browser's zoom control. Error states at 200% and text-only resize were not checked.
- **The verdicts are one reviewer's.** Whether a focus ring that is visible but pale passes 2.4.7 (judged pass) and fails 1.4.11 (judged fail) is a judgement. The contrast ratios are computed from CSS values, not sampled from pixels; the ring ratio blends the box-shadow over a white page.
- **Keyboard screenshots show no pointer.** The helper refuses a screenshot without the pointer overlay and case label, and both are in the DOM, but in a keyboard-only run the pointer was never moved, so it sits off screen. The pointer is visible in the screenshots that used the mouse.
- **The scan does not fail on violations.** `axe-scan.a11y.spec.ts` records all four groups and asserts only that the scan ran. The audit's output is the triage, not a pass or a fail of the file. The reference's template, which does assert, is for a regression suite.
- **Raw files are trimmed.** `passes` and `inapplicable` are kept as rule IDs, with node counts for passes. `violations` and `incomplete` are in full.
- **One date, one observation.** Every value was seen once on 2026-10-18 on a public service that can change.
- **Not edited afterwards.** The audit, specs and evidence are as produced, apart from fixes made during the run (a screenshot that caught a focus ring half drawn and a zoom capture that showed the wrong part of the page were corrected by changing the helper and the spec, then rerun in full).
