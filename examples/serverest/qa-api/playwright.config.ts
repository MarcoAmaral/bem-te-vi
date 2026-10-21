import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./playwright/tests",
  outputDir: "./playwright/test-reports/artifacts",
  timeout: 30_000,
  retries: 0,
  workers: 1,
  reporter: [["list"]],
  use: {
    baseURL: process.env.BASE_URL || "https://serverest.dev",
    extraHTTPHeaders: { "Content-Type": "application/json" },
  },
  projects: [{ name: "api" }],
});
