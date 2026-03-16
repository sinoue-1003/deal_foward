import { Globe, MessageSquare, Calendar, TrendingUp, Users, Zap, ArrowRight, AlertCircle } from 'lucide-react'
import { useApi } from '../hooks/useApi'
import StatCard from '../components/StatCard'
import LoadingSpinner from '../components/LoadingSpinner'
import { Link } from 'react-router-dom'
import { format, parseISO } from 'date-fns'
import { ja } from 'date-fns/locale'

const SCORE_LABEL = (score) => {
  if (score >= 80) return { label: 'ホット', className: 'bg-red-100 text-red-700' }
  if (score >= 60) return { label: 'ウォーム', className: 'bg-amber-100 text-amber-700' }
  if (score >= 40) return { label: 'クール', className: 'bg-blue-100 text-blue-700' }
  return { label: 'コールド', className: 'bg-gray-100 text-gray-600' }
}

function sentimentToScore(sentiment) {
  if (sentiment === 'positive') return 82
  if (sentiment === 'negative') return 35
  return 61
}

function fmt(seconds) {
  const m = Math.floor(seconds / 60)
  return m >= 60 ? `${Math.floor(m / 60)}時間${m % 60}分` : `${m}分`
}

const MOCK_ALERTS = [
  { id: 1, company: 'Salesforce Japan', page: '料金プランページ', score: 94, time: '2分前' },
  { id: 2, company: 'トヨタ自動車', page: '機能詳細ページ', score: 87, time: '8分前' },
  { id: 3, company: 'NTTデータ', page: 'デモ申込ページ', score: 91, time: '15分前' },
]

const MOCK_MEETINGS = [
  { id: 1, name: '山田 花子', company: 'Salesforce Japan', time: '14:00', rep: '田中 太郎', status: 'confirmed' },
  { id: 2, name: '鈴木 一郎', company: 'ソフトバンク株式会社', time: '16:30', rep: '佐藤 次郎', status: 'confirmed' },
]

export default function Dashboard() {
  const { data: overview, loading: ol } = useApi('/analytics/overview')
  const { data: conversations, loading: cl } = useApi('/conversations/?limit=5')

  if (ol || cl) return <LoadingSpinner />

  const totalConversations = overview?.calls?.total || 0
  const recentConversations = overview?.calls?.recent_30d || 0
  const totalLeads = overview?.deals?.open || 0
  const conversionRate = overview?.deals?.win_rate || 0

  return (
    <div className="p-8 max-w-7xl mx-auto">
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900">ダッシュボード</h1>
        <p className="text-gray-500 text-sm mt-1">インバウンドAI営業担当の概要</p>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        <StatCard
          label="アクティブ訪問者"
          value="12"
          sub="現在サイト閲覧中"
          icon={Globe}
          color="brand"
        />
        <StatCard
          label="今日の予約"
          value={MOCK_MEETINGS.length}
          sub="ミーティング予約済み"
          icon={Calendar}
          color="green"
        />
        <StatCard
          label="AI会話数 (30日)"
          value={recentConversations}
          sub={`累計 ${totalConversations}件`}
          icon={MessageSquare}
          color="purple"
        />
        <StatCard
          label="リード転換率"
          value={`${conversionRate}%`}
          sub={`${totalLeads}件のアクティブリード`}
          icon={TrendingUp}
          color="amber"
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">
        {/* High-intent alerts */}
        <div className="card">
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-semibold text-gray-900 flex items-center gap-2">
              <AlertCircle size={16} className="text-red-500" /> 高インテント訪問者
            </h2>
            <Link to="/visitors" className="text-brand-600 text-sm hover:underline">すべて表示</Link>
          </div>
          <div className="space-y-3">
            {MOCK_ALERTS.map(alert => {
              const score = SCORE_LABEL(alert.score)
              return (
                <div key={alert.id} className="flex items-start gap-3 p-3 rounded-lg bg-red-50 border border-red-100">
                  <div className="w-8 h-8 rounded-full bg-red-100 flex items-center justify-center text-red-700 text-xs font-bold flex-shrink-0">
                    {alert.score}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-gray-900">{alert.company}</p>
                    <p className="text-xs text-gray-500 mt-0.5 truncate">{alert.page}</p>
                    <p className="text-xs text-gray-400 mt-0.5">{alert.time}</p>
                  </div>
                  <span className={`badge ${score.className} flex-shrink-0`}>{score.label}</span>
                </div>
              )
            })}
          </div>
        </div>

        {/* Recent conversations */}
        <div className="card">
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-semibold text-gray-900 flex items-center gap-2">
              <MessageSquare size={16} className="text-brand-600" /> 最近のAI会話
            </h2>
            <Link to="/conversations" className="text-brand-600 text-sm hover:underline">すべて表示</Link>
          </div>
          <div className="space-y-3">
            {(conversations || []).map(conv => {
              const score = sentimentToScore(conv.sentiment)
              const scoreBadge = SCORE_LABEL(score)
              return (
                <Link key={conv.id} to={`/conversations/${conv.id}`}
                  className="flex items-start justify-between p-3 rounded-lg hover:bg-gray-50 transition-colors group">
                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-sm text-gray-900 group-hover:text-brand-600 truncate">{conv.title}</p>
                    <p className="text-xs text-gray-400 mt-0.5">
                      {conv.date ? format(parseISO(conv.date), 'M月d日 HH:mm', { locale: ja }) : '-'} · {fmt(conv.duration_seconds)}
                    </p>
                  </div>
                  <span className={`badge ${scoreBadge.className} ml-2 flex-shrink-0`}>{score}</span>
                </Link>
              )
            })}
            {!conversations?.length && <p className="text-gray-400 text-sm text-center py-4">AI会話がありません</p>}
          </div>
        </div>

        {/* Today's meetings */}
        <div className="card">
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-semibold text-gray-900 flex items-center gap-2">
              <Calendar size={16} className="text-green-600" /> 本日のミーティング
            </h2>
            <Link to="/meetings" className="text-brand-600 text-sm hover:underline">すべて表示</Link>
          </div>
          <div className="space-y-3">
            {MOCK_MEETINGS.map(meeting => (
              <div key={meeting.id} className="flex items-start gap-3 p-3 rounded-lg bg-green-50 border border-green-100">
                <div className="text-center flex-shrink-0">
                  <p className="text-lg font-bold text-green-700">{meeting.time}</p>
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-gray-900">{meeting.name}</p>
                  <p className="text-xs text-gray-500 mt-0.5">{meeting.company}</p>
                  <p className="text-xs text-gray-400 mt-0.5">担当: {meeting.rep}</p>
                </div>
                <span className="badge bg-green-100 text-green-700 flex-shrink-0">確定</span>
              </div>
            ))}
            {MOCK_MEETINGS.length === 0 && <p className="text-gray-400 text-sm text-center py-4">予定なし</p>}
          </div>
        </div>
      </div>

      {/* Sentiment / Lead Score Overview */}
      {overview?.sentiment && (
        <div className="card">
          <h2 className="font-semibold text-gray-900 mb-4 flex items-center gap-2">
            <Zap size={16} className="text-brand-600" /> リードスコア分布
          </h2>
          <div className="flex gap-6">
            {[
              { key: 'positive', label: 'ホット (80+)', color: 'bg-red-500' },
              { key: 'neutral', label: 'ウォーム (60-79)', color: 'bg-amber-400' },
              { key: 'negative', label: 'クール (40-59)', color: 'bg-blue-400' },
            ].map(({ key, label, color }) => {
              const count = overview.sentiment[key] || 0
              const total = Object.values(overview.sentiment).reduce((a, b) => a + b, 0)
              const pct = total > 0 ? Math.round(count / total * 100) : 0
              return (
                <div key={key} className="flex-1">
                  <div className="flex items-center justify-between mb-1">
                    <span className="text-sm text-gray-600">{label}</span>
                    <span className="text-sm font-medium">{count}件 ({pct}%)</span>
                  </div>
                  <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
                    <div className={`h-full ${color} rounded-full`} style={{ width: `${pct}%` }} />
                  </div>
                </div>
              )
            })}
          </div>
        </div>
      )}
    </div>
  )
}
