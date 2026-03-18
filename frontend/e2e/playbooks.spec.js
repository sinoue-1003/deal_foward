import { test, expect } from '@playwright/test'
import { setupApiMocks, mockPlaybooks } from './helpers/mock-api.js'

test.describe('Playbooks page', () => {
  test.beforeEach(async ({ page }) => {
    await setupApiMocks(page)
    await page.goto('/playbooks')
  })

  test('renders the playbooks page', async ({ page }) => {
    await expect(page).toHaveURL('/playbooks')
  })

  test('displays playbook titles from API', async ({ page }) => {
    await expect(page.getByText(mockPlaybooks[0].title)).toBeVisible({ timeout: 5000 })
    await expect(page.getByText(mockPlaybooks[1].title)).toBeVisible({ timeout: 5000 })
  })

  test('shows playbook status badges', async ({ page }) => {
    await expect(page.getByText(/active/i)).toBeVisible({ timeout: 5000 })
  })

  test('navigates back to dashboard', async ({ page }) => {
    await page.getByRole('link', { name: 'ダッシュボード' }).click()
    await expect(page).toHaveURL('/')
  })
})
