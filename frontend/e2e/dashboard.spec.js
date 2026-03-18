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
    // StatCard labels are unique — verify all 4 cards rendered after API load
    await expect(page.getByText('アクティブ PB')).toBeVisible({ timeout: 5000 })
    await expect(page.getByText('本日のチャット')).toBeVisible({ timeout: 5000 })
    await expect(page.getByText('解析済み通信')).toBeVisible({ timeout: 5000 })
    await expect(page.getByText('AIレポート (本日)')).toBeVisible({ timeout: 5000 })
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
