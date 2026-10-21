import { defineConfig, devices } from '@playwright/test'

// Migration target for cypress/e2e/app.cy.js (see migration/).
// The Cypress suite is untouched and keeps running in CI until migration/decommission.md says go.
export default defineConfig({
  testDir: './playwright/tests',
  outputDir: './playwright/test-results',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  // Retries are for CI noise seen after the fact, never a fix. Locally a flaky test must fail.
  retries: process.env.CI ? 1 : 0,
  reporter: process.env.CI
    ? [['list'], ['html', { outputFolder: 'playwright/report', open: 'never' }]]
    : 'list',
  use: {
    // Same origin as cypress.config.ts `baseUrl`.
    baseURL: 'http://localhost:8888',
    trace: 'on-first-retry',
  },
  projects: [
    {
      name: 'chromium',
      // One fixed viewport for every run and every capture (.claude/rules/test-evidence.md).
      use: { ...devices['Desktop Chrome'], viewport: { width: 1440, height: 900 } },
    },
  ],
  // Serves the already-built app (`npm run build` first), as `npm start` does for Cypress.
  webServer: {
    command: 'npm run serve',
    url: 'http://localhost:8888',
    reuseExistingServer: !process.env.CI,
  },
})
