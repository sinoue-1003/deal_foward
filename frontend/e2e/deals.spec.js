import { test, expect } from '@playwright/test'
import { setupApiMocks, mockDeals } from './helpers/mock-api.js'

test.describe('Deals page', () => {
  test.beforeEach(async ({ page }) => {
    await setupApiMocks(page)
    await page.goto('/deals')
  })

  test('renders the deals page', async ({ page }) => {
    await expect(page).toHaveURL('/deals')
  })

  test('displays deal titles from API', async ({ page }) => {
    await expect(page.getByText(mockDeals[0].title)).toBeVisible({ timeout: 5000 })
    await expect(page.getByText(mockDeals[1].title)).toBeVisible({ timeout: 5000 })
  })

  test('displays company names', async ({ page }) => {
    await expect(page.getByText(mockDeals[0].company_name)).toBeVisible({ timeout: 5000 })
  })

  test('shows deal stages', async ({ page }) => {
    // StageBadge renders Japanese labels: prospect → "見込み客"
    // Scope to the table body to avoid matching the hidden <option> in the filter <select>
    const tableBody = page.locator('tbody')
    await expect(tableBody.getByText('見込み客')).toBeVisible({ timeout: 5000 })
  })

  test('has a link back to dashboard', async ({ page }) => {
    await page.getByRole('link', { name: 'ダッシュボード' }).click()
    await expect(page).toHaveURL('/')
  })
})
