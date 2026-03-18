/**
 * Mock API responses for E2E tests.
 * Intercepts /api/* requests and returns fixture data so tests
 * run without a live backend.
 */

export const mockDashboardOverview = {
  active_playbooks: 3,
  today_chat_sessions: 5,
  total_chat_sessions: 42,
  analyzed_communications: 18,
  total_communications: 30,
  agent_reports_today: 2,
  total_agent_reports: 15,
  pipeline_value: 1500000,
  active_deals: 8,
  integrations_connected: 3,
}

export const mockDeals = [
  {
    id: 'deal-1',
    title: 'Enterprise Software Deal',
    stage: 'prospect',
    amount: 500000,
    probability: 60,
    company_name: 'Acme Corp',
    contacts: [],
    created_at: new Date().toISOString(),
  },
  {
    id: 'deal-2',
    title: 'SaaS Platform License',
    stage: 'qualify',
    amount: 250000,
    probability: 40,
    company_name: 'Globex Corp',
    contacts: [],
    created_at: new Date().toISOString(),
  },
]

export const mockPlaybooks = [
  {
    id: 'pb-1',
    title: 'Enterprise Onboarding Playbook',
    status: 'active',
    objective: 'Close enterprise deal',
    created_by: 'ai_agent',
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  },
  {
    id: 'pb-2',
    title: 'Follow-up Campaign',
    status: 'paused',
    objective: 'Re-engage cold leads',
    created_by: 'ai_agent',
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  },
]

/**
 * Set up all common API mocks for a page.
 * Call this in beforeEach or at the start of each test.
 */
export async function setupApiMocks(page) {
  await page.route('/api/dashboard/overview', (route) =>
    route.fulfill({ json: mockDashboardOverview })
  )

  await page.route('/api/dashboard/agent_activity', (route) =>
    route.fulfill({
      json: { recent_runs: [], total_runs: 0, success_rate: 0 },
    })
  )

  await page.route('/api/dashboard/pipeline', (route) =>
    route.fulfill({
      json: {
        stages: [
          { stage: 'prospect', count: 3, value: 300000 },
          { stage: 'qualify', count: 2, value: 200000 },
        ],
      },
    })
  )

  await page.route('/api/deals', (route) =>
    route.fulfill({ json: mockDeals })
  )

  await page.route('/api/deals/**', (route) =>
    route.fulfill({ json: mockDeals[0] })
  )

  await page.route('/api/playbooks', (route) =>
    route.fulfill({ json: mockPlaybooks })
  )

  await page.route('/api/playbooks/**', (route) =>
    route.fulfill({ json: mockPlaybooks[0] })
  )

  await page.route('/api/chatbot/sessions', (route) =>
    route.fulfill({ json: [] })
  )

  await page.route('/api/communications', (route) =>
    route.fulfill({ json: [] })
  )

  await page.route('/api/integrations', (route) =>
    route.fulfill({ json: [] })
  )

  await page.route('/api/agent/runs', (route) =>
    route.fulfill({ json: [] })
  )
}
