import { defineConfig } from "@playwright/test";

// One stated viewport for every capture (test-evidence rule). The narrow viewport and the
// 200% zoom equivalent are set inside the specs that need them, then restored.
export default defineConfig({
  testDir: "./playwright/tests",
  outputDir: "./playwright/test-reports/artifacts",
  timeout: 60_000,
  retries: 0,
  workers: 1,
  reporter: [["list"]],
  use: {
    baseURL: "https://front.serverest.dev",
    viewport: { width: 1440, height: 900 },
  },
  projects: [{ name: "chromium", use: { browserName: "chromium" } }],
});
