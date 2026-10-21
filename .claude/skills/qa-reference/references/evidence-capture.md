---
id: ref-evidence-capture
---
# Evidence Capture Reference

> **Read on demand** | Detail behind the `test-evidence` rule | Part of the `qa-reference` skill

Read this when writing automation that captures screenshots or video, or before handing evidence to a reviewer. The always-on hard rules are the `test-evidence` rule.

---

## 📸 Screenshots Capture the Viewport

A screenshot is the **viewport** at a fixed size, with the subject of the check in view.

- **Never a full scrolled page.** `fullPage: true` produces strips thousands of pixels tall that
  no reviewer can read in a review tool. Scroll the subject into view and capture the viewport.
- **Never an element-only crop.** A locator's own `.screenshot()` removes all surrounding context,
  so the reviewer cannot tell where on the page the subject sits or what else was showing.
- **Fix the size.** Use one viewport size for every capture so evidence is comparable. The
  default is **1440×900**; a team may choose another size, but it must be one stated value, set
  in configuration rather than per test.

<!-- ts-check: skip (fragment: page is the test's fixture) -->

```typescript
// Good: fixed viewport, subject scrolled into view, page-level capture
await page.setViewportSize({ width: 1440, height: 900 });
await page.getByTestId("order-total").scrollIntoViewIfNeeded();
await page.screenshot({ path: "evidence/TC-CART-001-total.png" });

// Bad: a multi-thousand-pixel strip
await page.screenshot({ path: "evidence/cart.png", fullPage: true });

// Bad: no context around the subject
await page.getByTestId("order-total").screenshot({ path: "evidence/total.png" });
```

---

## 🖱️ Make Actions Visible

A frame must show where an action landed and which case it belongs to.

- **Visible pointer**: inject a cursor or click highlight into the page so the reviewer can see
  what was clicked, typed into or hovered.
- **Case label**: render a banner or label that identifies the test case (for example its TC ID)
  in every frame.
- **Refuse to capture without them.** A capture helper must check that the pointer overlay and the
  label are present and fail loudly if not, rather than quietly saving an unlabelled frame. A
  rule that is only written down gets broken; put the check in the helper.

---

## 🎞️ Open the Recording Before Calling It Evidence

Before evidence is called ready, **open every recording**.

1. Extract a review frame from partway through each video (for example at the midpoint with
   `ffmpeg -ss <seconds> -i video.webm -frames:v 1 review.png`).
2. Look at the frame. It must show the right page, the visible pointer and the case label.
3. Only then attach or reference the recording.

A pass in the test runner says the assertions held. It says nothing about whether the recording
is blank, cut short or showing the wrong page.

### Skipped tests leave near-empty recordings

A skipped or aborted test can still write a tiny recording **under the real test's name**. If
that file is copied or converted into the evidence folder, it overwrites the genuine recording.

- Set a minimum size threshold; never convert or copy a recording below it.
- Never let a new recording overwrite an existing evidence file unless it is above the threshold
  and comes from a run that passed.

### Pace recordings

An unpaced automated run finishes in seconds and cannot be watched. Add a short, deliberate pause
after each visible action (for example a few hundred milliseconds, or Playwright's `slowMo`
option) so a person can follow the recording. Pace the recording only; never use pauses to make an
assertion pass (see the no hardcoded sleeps rule in the `code-style-qa` rule).

---

## 🔤 ASCII-Only Evidence File Names

Evidence file names use **ASCII characters only**: letters, digits, `-`, `_` and `.`.

Some documentation and ticketing platforms silently drop uploads whose names contain characters
such as a middle dot (`·`), accents or emoji, so files can no longer be matched to the rows they
belong to. Nothing reports the failure. Name files after the case ID and a short slug, such as
`TC-CART-001-total.png`.

---

## 🛡️ What Can Be Checked Mechanically

This package ships `check-test-evidence.sh` (a Claude Code install puts it in `.claude/hooks/`, the
path the commands below use), which scans Playwright specs and reports,
with file, line and a fix:

- `fullPage: true` screenshots;
- element-level `.screenshot(` calls;
- screenshot or video `path:` values containing non-ASCII characters.

For a suite built on a shared helper library (see "One Shared Helper Library, Scaffolded Runners"
in `/qa-automate`), `--runner-standard` (or `EVIDENCE_RUNNER_STANDARD=1`) adds two more checks.
They are off by default, because plain Playwright `goto` and `click` are correct in a suite without
such a library:

- `page.goto(` without a `goto-ok: <reason>` comment on the same or the preceding line (direct
  navigation hides client-side routing bugs; see "Reach Every Screen Through the Interface" in
  `/qa-automate`);
- a bare `.click(`: a click must go through a project helper, because a bare click teleports and
  the recording shows no pointer path.

The allowed click helper defaults to `click(page, target)`. Name others with
`--click-helper <name>` (repeatable, comma-separated, qualified names such as `ui.click` allowed) or
the `EVIDENCE_CLICK_HELPERS` environment variable:

```bash
.claude/hooks/check-test-evidence.sh --runner-standard --click-helper ui.click playwright/tests
EVIDENCE_RUNNER_STANDARD=1 EVIDENCE_CLICK_HELPERS=ui.click,pointer.click .claude/hooks/check-test-evidence.sh playwright/tests
```

### Probe versus evidence

A **probe** is reconnaissance: finding a selector, watching how a screen behaves, reproducing a
defect. It is never evidence. Mark it with `// evidence-check: probe` as the **first line** of the
file. A probe is exempt from the `goto-ok` and bare-click checks, and it must not capture: the
checker flags `screenshot(` and `shot(` in a probe. To keep a probe's result as evidence, rewrite
it as an evidence spec (helper clicks, reasoned `goto`s) and drop the marker.

It is a line-based heuristic. It cannot check that the pointer overlay is present, that a
recording was opened, that its frame looks right or that a recording is large enough; those remain
the responsibility of the capture helper and the reviewer. Run the checker before declaring
evidence ready; where it is not installed, apply its checks by reading the specs and say that the
checker was not run:

```bash
.claude/hooks/check-test-evidence.sh playwright/tests
```

---

## 🎯 Scope of This Rule

This rule applies to evidence produced in the **target/consuming repository**. The fixed viewport
size is a default, not a requirement; the rest (viewport capture, visible actions, opened
recordings, ASCII-only names, protected recordings) holds regardless of framework.
