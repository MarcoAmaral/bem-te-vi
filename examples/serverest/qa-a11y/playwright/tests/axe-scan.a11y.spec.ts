import { test, expect } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";
import { mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { click } from "../support/evidence";

// Step 2 of the qa-a11y skill: one axe-core scan per page, state and viewport. The scan records
// all four result groups to a11y/raw/. It does not assert on `violations`: the audit's output is
// the triage in a11y/audit.md, not a pass or fail of this file.
// Read-only: the only requests sent are GETs and an empty form submit, which the API rejects
// with 400 (nothing is created).

const RAW_DIR = join(__dirname, "..", "..", "a11y", "raw");
const TAGS = ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"];

type Scan = {
  id: string;
  path: string;
  viewport: { width: number; height: number };
  submit?: string;
};

const WIDE = { width: 1440, height: 900 };
const NARROW = { width: 390, height: 844 };
const ZOOM200 = { width: 720, height: 450 }; // 1440 CSS px at 200% zoom

const writes: string[] = [];

test.beforeEach(async ({ page }) => {
  page.on("response", (r) => {
    if (r.request().method() !== "GET")
      writes.push(`${r.request().method()} ${r.url()} -> ${r.status()}`);
  });
});

test.afterAll(() => {
  mkdirSync(RAW_DIR, { recursive: true });
  writeFileSync(
    join(RAW_DIR, "axe-scan-writes.json"),
    JSON.stringify({ nonGetRequestsSent: writes }, null, 2),
  );
  // read-only guarantee: every write the pages attempted was rejected
  expect(writes.filter((w) => / -> 2\d\d$/.test(w))).toEqual([]);
});

const scans: Scan[] = [
  { id: "login-default-1440", path: "/login", viewport: WIDE },
  { id: "login-error-1440", path: "/login", viewport: WIDE, submit: "entrar" },
  { id: "signup-default-1440", path: "/cadastrarusuarios", viewport: WIDE },
  {
    id: "signup-error-1440",
    path: "/cadastrarusuarios",
    viewport: WIDE,
    submit: "cadastrar",
  },
  { id: "login-default-390", path: "/login", viewport: NARROW },
  { id: "signup-default-390", path: "/cadastrarusuarios", viewport: NARROW },
  { id: "login-default-zoom200", path: "/login", viewport: ZOOM200 },
  {
    id: "signup-default-zoom200",
    path: "/cadastrarusuarios",
    viewport: ZOOM200,
  },
];

for (const scan of scans) {
  test(`axe scan ${scan.id} @a11y`, async ({ page }) => {
    // Arrange
    await page.setViewportSize(scan.viewport);
    await page.goto(scan.path); // goto-ok: the page itself is the audit target
    await expect(page.getByRole("heading").first()).toBeVisible();
    if (scan.submit) {
      await click(page, page.getByTestId(scan.submit));
      await expect(page.getByRole("alert").first()).toBeVisible();
    }

    // Act
    const results = await new AxeBuilder({ page }).withTags(TAGS).analyze();

    // Assert: the scan ran and every group is on record
    expect(results.passes.length).toBeGreaterThan(0);
    mkdirSync(RAW_DIR, { recursive: true });
    writeFileSync(
      join(RAW_DIR, `${scan.id}.json`),
      JSON.stringify(
        {
          id: scan.id,
          url: results.url,
          timestamp: results.timestamp,
          testEngine: results.testEngine,
          tags: TAGS,
          viewport: scan.viewport,
          violations: results.violations,
          incomplete: results.incomplete,
          passes: results.passes.map((r) => ({
            id: r.id,
            nodes: r.nodes.length,
          })),
          inapplicable: results.inapplicable.map((r) => r.id),
        },
        null,
        2,
      ),
    );
  });
}
