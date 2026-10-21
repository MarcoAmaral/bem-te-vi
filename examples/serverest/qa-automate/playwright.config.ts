import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./playwright/tests",
  outputDir: "./playwright/test-reports/artifacts",
  timeout: 30_000,
  retries: 0,
  workers: 2,
  reporter: [
    ["list"],
    ["html", { open: "never", outputFolder: "./playwright/test-reports/html-report" }],
  ],
  use: {
    baseURL: process.env.BASE_URL || "https://serverest.dev",
    extraHTTPHeaders: { "Content-Type": "application/json" },
  },
  projects: [{ name: "api" }],
});
