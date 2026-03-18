import { test, expect } from '@playwright/test'
import { setupApiMocks, mockDashboardOverview } from './helpers/mock-api.js'

test.describe('Dashboard page', () => {
  test.beforeEach(async ({ page }) => {
    await setupApiMocks(page)
    await page.goto('/')
  })

  test('shows the Deal Forward title in sidebar', async ({ page }) => {
    await expect(page.getByText('Deal Forward')).toBeVisible()
  })

  test('shows the dashboard heading', async ({ page }) => {
    await expect(page.getByText('ダッシュボード')).toBeVisible()
  })

  test('displays KPI stats from API', async ({ page }) => {
    // Wait for the API data to load (loading spinner disappears or data appears)
    // The dashboard shows active_playbooks count
    await expect(page.getByText(String(mockDashboardOverview.active_playbooks))).toBeVisible({ timeout: 5000 })
  })

  test('sidebar navigation links are present', async ({ page }) => {
    await expect(page.getByRole('link', { name: 'プレイブック' })).toBeVisible()
    await expect(page.getByRole('link', { name: '商談' })).toBeVisible()
    await expect(page.getByRole('link', { name: 'AIエージェント' })).toBeVisible()
  })

  test('navigates to Deals page from sidebar', async ({ page }) => {
    await page.getByRole('link', { name: '商談' }).click()
    await expect(page).toHaveURL('/deals')
  })

  test('navigates to Playbooks page from sidebar', async ({ page }) => {
    await page.getByRole('link', { name: 'プレイブック' }).click()
    await expect(page).toHaveURL('/playbooks')
  })
})
