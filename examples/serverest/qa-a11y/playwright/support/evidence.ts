import type { Locator, Page } from "@playwright/test";
import { mkdirSync } from "node:fs";
import { join } from "node:path";

export const EVIDENCE_DIR = join(__dirname, "..", "..", "a11y", "evidence");

const OVERLAY_ID = "qa-evidence-overlay";

// Injects a visible pointer and a case-label banner into the page. Called again after every
// navigation, because a new document loses the overlay.
export async function showOverlay(
  page: Page,
  caseLabel: string,
): Promise<void> {
  await page.evaluate(
    ({ id, label }) => {
      if (document.getElementById(id)) {
        (document.getElementById(id) as HTMLElement).dataset.label = label;
        document.getElementById(`${id}-banner`)!.textContent = label;
        return;
      }
      const root = document.createElement("div");
      root.id = id;
      root.dataset.label = label;
      root.style.cssText =
        "position:fixed;inset:0;pointer-events:none;z-index:2147483647";
      const banner = document.createElement("div");
      banner.id = `${id}-banner`;
      banner.textContent = label;
      banner.style.cssText =
        "position:fixed;right:8px;bottom:8px;background:#111;color:#fff;font:14px monospace;padding:4px 8px;border-radius:4px";
      const pointer = document.createElement("div");
      pointer.id = `${id}-pointer`;
      pointer.style.cssText =
        "position:fixed;left:-50px;top:-50px;width:18px;height:18px;border:3px solid #e11d48;border-radius:50%;background:rgba(225,29,72,.25);transform:translate(-50%,-50%)";
      root.append(banner, pointer);
      document.documentElement.appendChild(root);
      document.addEventListener("mousemove", (e) => {
        pointer.style.left = `${e.clientX}px`;
        pointer.style.top = `${e.clientY}px`;
      });
    },
    { id: OVERLAY_ID, label: caseLabel },
  );
}

// Moves the pointer to the target in steps, so the overlay shows the path, then clicks.
export async function click(page: Page, target: Locator): Promise<void> {
  await target.scrollIntoViewIfNeeded();
  const box = await target.boundingBox();
  if (!box) throw new Error("click: target has no box");
  await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2, {
    steps: 12,
  });
  await page.mouse.down();
  await page.mouse.up();
}

// Saves a viewport screenshot. Refuses when the overlay or the label is missing, or the name
// is not plain ASCII.
export async function shot(page: Page, name: string): Promise<string> {
  if (!/^[A-Za-z0-9._-]+\.png$/.test(name))
    throw new Error(`shot: file name must be ASCII: ${name}`);
  const ok = await page.evaluate(
    (id) =>
      !!document.getElementById(`${id}-pointer`) &&
      !!document.getElementById(`${id}-banner`)?.textContent,
    OVERLAY_ID,
  );
  if (!ok)
    throw new Error(
      "shot: pointer overlay or case label missing; call showOverlay first",
    );
  // A CSS transition (a focus ring fading in) must have finished, or the frame shows it half drawn.
  await page.evaluate(() =>
    Promise.all(document.getAnimations().map((a) => a.finished)),
  );
  mkdirSync(EVIDENCE_DIR, { recursive: true });
  const path = join(EVIDENCE_DIR, name);
  await page.screenshot({ path });
  return path;
}
