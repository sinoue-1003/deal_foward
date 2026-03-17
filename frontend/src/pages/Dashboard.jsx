import { BookOpen, MessageSquare, Radio, Bot, Briefcase, TrendingUp, CheckCircle, AlertCircle } from 'lucide-react'
import { Link } from 'react-router-dom'
import { useApi } from '../hooks/useApi'
import StatCard from '../components/StatCard'
import LoadingSpinner from '../components/LoadingSpinner'
import IntentBadge from '../components/IntentBadge'
import AgentRunPanel from '../components/AgentRunPanel'

const INTEGRATION_TYPES = [
  { key: 'slack',       label: 'Slack' },
  { key: 'teams',       label: 'Teams' },
  { key: 'zoom',        label: 'Zoom' },
  { key: 'google_meet', label: 'Google Meet' },
  { key: 'salesforce',  label: 'Salesforce' },
  { key: 'hubspot',     label: 'HubSpot' },
]

export default function Dashboard() {
  const { data: overview, loading: l1 } = useApi('/api/dashboard/overview')
  const { data: activity, loading: l2 } = useApi('/api/dashboard/agent_activity')
  const { data: pipeline, loading: l3 } = useApi('/api/dashboard/pipeline')
  const { data: playbooks, loading: l4 } = useApi('/api/playbooks?status=active')
  const { data: sessions, loading: l5 } = useApi('/api/chatbot/sessions?limit=5')
  const { data: integrations, loading: l6 } = useApi('/api/integrations')

  if (l1 || l2 || l3 || l4 || l5 || l6) return <LoadingSpinner />

  return (
    <div className="p-6 space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">ダッシュボード</h1>
        <p className="text-gray-500 text-sm mt-1">AIエージェントと営業活動の概要</p>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard label="アクティブ PB" value={overview?.active_playbooks ?? 0} icon={BookOpen} color="brand" sub="実行中のプレイブック" />
        <StatCard label="本日のチャット" value={overview?.today_chat_sessions ?? 0} icon={MessageSquare} color="green" sub={`合計 ${overview?.total_chat_sessions ?? 0} 件`} />
        <StatCard label="解析済み通信" value={overview?.analyzed_communications ?? 0} icon={Radio} color="purple" sub={`全 ${overview?.total_communications ?? 0} 件`} />
        <StatCard label="AIレポート (本日)" value={overview?.agent_reports_today ?? 0} icon={Bot} color="amber" sub={`累計 ${overview?.total_agent_reports ?? 0} 件`} />
      </div>

      <div className="grid grid-cols-3 gap-6">
        {/* Agent Activity Feed */}
        <div className="col-span-2 space-y-4">
          <div className="card">
            <h2 className="text-sm font-semibold text-gray-700 mb-3 flex items-center gap-2">
              <Bot size={16} className="text-brand-500" />
              AIエージェント活動ログ
            </h2>
            {activity?.length ? (
              <div className="space-y-2">
                {activity.slice(0, 5).map((r) => (
                  <div key={r.id} className="flex items-start gap-3 p-2 rounded-lg hover:bg-gray-50">
                    <CheckCircle size={14} className="text-green-500 mt-0.5 flex-shrink-0" />
                    <div className="flex-1 min-w-0">
                      <p className="text-sm text-gray-800">{r.action_taken}</p>
                      {r.company_name && <p className="text-xs text-gray-500">{r.company_name}</p>}
                    </div>
                    <span className="text-xs text-gray-400 flex-shrink-0">
                      {new Date(r.created_at).toLocaleTimeString('ja-JP', { hour: '2-digit', minute: '2-digit' })}
                    </span>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-sm text-gray-400">まだ活動ログがありません</p>
            )}
          </div>

          {/* Active Playbooks */}
          <div className="card">
            <h2 className="text-sm font-semibold text-gray-700 mb-3 flex items-center gap-2">
              <BookOpen size={16} className="text-brand-500" />
              アクティブなプレイブック
            </h2>
            {playbooks?.length ? (
              <div className="space-y-3">
                {playbooks.slice(0, 4).map((pb) => {
                  const total = pb.total_steps || 0
                  const done = pb.completed_steps || 0
                  const pct = total > 0 ? Math.round((done / total) * 100) : 0
                  return (
                    <Link key={pb.id} to={`/playbooks/${pb.id}`} className="block p-3 border border-gray-100 rounded-lg hover:border-brand-300 transition-colors">
                      <div className="flex items-center justify-between mb-1">
                        <span className="text-sm font-medium text-gray-800 truncate">{pb.title}</span>
                        <span className="text-xs text-gray-500">{done}/{total}</span>
                      </div>
                      {pb.company_name && <p className="text-xs text-gray-500 mb-2">{pb.company_name}</p>}
                      <div className="w-full bg-gray-100 rounded-full h-1.5">
                        <div className="bg-brand-500 h-1.5 rounded-full" style={{ width: `${pct}%` }} />
                      </div>
                      {pb.status_summary?.next_action && (
                        <p className="text-xs text-brand-600 mt-1.5">
                          次のアクション: {pb.status_summary.next_action.description || pb.status_summary.next_action.action_type}
                        </p>
                      )}
                    </Link>
                  )
                })}
              </div>
            ) : (
              <p className="text-sm text-gray-400">アクティブなプレイブックはありません</p>
            )}
          </div>
        </div>

        {/* Right column */}
        <div className="space-y-4">
          {/* Agent Run Panel */}
          <AgentRunPanel />

          {/* Integration Status */}
          <div className="card">
            <h2 className="text-sm font-semibold text-gray-700 mb-3">連携ステータス</h2>
            <div className="space-y-2">
              {INTEGRATION_TYPES.map((it) => {
                const intg = integrations?.find((i) => i.integration_type === it.key)
                const connected = intg?.status === 'connected'
                return (
                  <div key={it.key} className="flex items-center justify-between">
                    <span className="text-xs text-gray-600">{it.label}</span>
                    <span className={`text-xs px-1.5 py-0.5 rounded ${connected ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
                      {connected ? '接続済' : '未接続'}
                    </span>
                  </div>
                )
              })}
            </div>
            <Link to="/communications" className="text-xs text-brand-600 hover:underline mt-3 block">
              連携管理 →
            </Link>
          </div>

          {/* High-intent sessions */}
          <div className="card">
            <h2 className="text-sm font-semibold text-gray-700 mb-3">高インテントチャット</h2>
            {sessions?.filter((s) => s.intent_score >= 60).length ? (
              <div className="space-y-2">
                {sessions.filter((s) => s.intent_score >= 60).slice(0, 3).map((s) => (
                  <Link key={s.id} to={`/chatbot/${s.id}`} className="block p-2 rounded-lg hover:bg-gray-50">
                    <div className="flex items-center justify-between">
                      <span className="text-sm text-gray-800 truncate">{s.company_name || '匿名'}</span>
                      <IntentBadge score={s.intent_score} />
                    </div>
                    <p className="text-xs text-gray-400 mt-0.5">{s.message_count} メッセージ</p>
                  </Link>
                ))}
              </div>
            ) : (
              <p className="text-sm text-gray-400">高インテントセッションなし</p>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
