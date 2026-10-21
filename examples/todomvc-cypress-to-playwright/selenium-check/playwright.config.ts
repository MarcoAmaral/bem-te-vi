import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./playwright-tests",
  fullyParallel: true,
  retries: 0,
  reporter: "list",
  use: {
    baseURL: "http://localhost:8889",
    viewport: { width: 1440, height: 900 },
    trace: "on-first-retry",
  },
});
