import { chromium } from "@playwright/test";
const b = await chromium.launch(); const p = await b.newPage();
await p.goto("http://localhost:8889/");
await p.getByPlaceholder("What needs to be done?").fill("  trims spaces  ");
await p.getByPlaceholder("What needs to be done?").press("Enter");
const l = p.getByRole("listitem").filter({ hasNot: p.getByRole("link") }).first();
console.log("textContent:", JSON.stringify(await l.textContent()), "innerText:", JSON.stringify(await l.innerText()));
await b.close();
