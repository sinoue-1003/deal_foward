import { Phone, Briefcase, TrendingUp, Trophy, Clock, Star } from 'lucide-react'
import { useApi } from '../hooks/useApi'
import StatCard from '../components/StatCard'
import SentimentBadge from '../components/SentimentBadge'
import StageBadge from '../components/StageBadge'
import LoadingSpinner from '../components/LoadingSpinner'
import { Link } from 'react-router-dom'
import { format, parseISO } from 'date-fns'
import { ja } from 'date-fns/locale'

function fmt(seconds) {
  const m = Math.floor(seconds / 60)
  return m >= 60 ? `${Math.floor(m / 60)}時間${m % 60}分` : `${m}分`
}

function fmtMoney(v) {
  return new Intl.NumberFormat('ja-JP', { style: 'currency', currency: 'JPY', maximumFractionDigits: 0 }).format(v)
}

export default function Dashboard() {
  const { data: overview, loading: ol } = useApi('/analytics/overview')
  const { data: calls, loading: cl } = useApi('/calls/?limit=5')
  const { data: deals, loading: dl } = useApi('/deals/?limit=5')

  if (ol || cl || dl) return <LoadingSpinner />

  return (
    <div className="p-8 max-w-7xl mx-auto">
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900">ダッシュボード</h1>
        <p className="text-gray-500 text-sm mt-1">営業活動の概要</p>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        <StatCard
          label="パイプライン総額"
          value={fmtMoney(overview?.deals.pipeline_value || 0)}
          sub={`${overview?.deals.open || 0}件のオープン商談`}
          icon={TrendingUp}
          color="brand"
        />
        <StatCard
          label="成約額"
          value={fmtMoney(overview?.deals.won_value || 0)}
          sub={`成約率 ${overview?.deals.win_rate || 0}%`}
          icon={Trophy}
          color="green"
        />
        <StatCard
          label="通話数 (30日)"
          value={overview?.calls.recent_30d || 0}
          sub={`全通話 ${overview?.calls.total || 0}件`}
          icon={Phone}
          color="purple"
        />
        <StatCard
          label="平均通話時間"
          value={fmt(overview?.calls.avg_duration_seconds || 0)}
          sub="1通話あたり"
          icon={Clock}
          color="amber"
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Recent Calls */}
        <div className="card">
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-semibold text-gray-900 flex items-center gap-2">
              <Phone size={16} className="text-brand-600" /> 最近の通話
            </h2>
            <Link to="/calls" className="text-brand-600 text-sm hover:underline">すべて表示</Link>
          </div>
          <div className="space-y-3">
            {calls?.map(call => (
              <Link key={call.id} to={`/calls/${call.id}`}
                className="flex items-start justify-between p-3 rounded-lg hover:bg-gray-50 transition-colors group">
                <div className="flex-1 min-w-0">
                  <p className="font-medium text-sm text-gray-900 group-hover:text-brand-600 truncate">{call.title}</p>
                  <p className="text-xs text-gray-400 mt-0.5">
                    {call.date ? format(parseISO(call.date), 'M月d日 HH:mm', { locale: ja }) : '-'} · {fmt(call.duration_seconds)}
                  </p>
                </div>
                <div className="ml-3 flex-shrink-0">
                  {call.sentiment && <SentimentBadge sentiment={call.sentiment} />}
                </div>
              </Link>
            ))}
            {!calls?.length && <p className="text-gray-400 text-sm text-center py-4">通話がありません</p>}
          </div>
        </div>

        {/* Recent Deals */}
        <div className="card">
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-semibold text-gray-900 flex items-center gap-2">
              <Briefcase size={16} className="text-brand-600" /> 最近のディール
            </h2>
            <Link to="/deals" className="text-brand-600 text-sm hover:underline">すべて表示</Link>
          </div>
          <div className="space-y-3">
            {deals?.map(deal => (
              <Link key={deal.id} to={`/deals/${deal.id}`}
                className="flex items-start justify-between p-3 rounded-lg hover:bg-gray-50 transition-colors group">
                <div className="flex-1 min-w-0">
                  <p className="font-medium text-sm text-gray-900 group-hover:text-brand-600 truncate">{deal.name}</p>
                  <p className="text-xs text-gray-400 mt-0.5 truncate">{deal.company} · {deal.owner}</p>
                </div>
                <div className="ml-3 flex-shrink-0 text-right">
                  <p className="text-sm font-semibold text-gray-900">{fmtMoney(deal.amount)}</p>
                  <div className="mt-0.5"><StageBadge stage={deal.stage} /></div>
                </div>
              </Link>
            ))}
            {!deals?.length && <p className="text-gray-400 text-sm text-center py-4">ディールがありません</p>}
          </div>
        </div>
      </div>

      {/* Sentiment overview */}
      {overview?.sentiment && (
        <div className="card mt-6">
          <h2 className="font-semibold text-gray-900 mb-4 flex items-center gap-2">
            <Star size={16} className="text-brand-600" /> 通話感情分析
          </h2>
          <div className="flex gap-6">
            {[
              { key: 'positive', label: 'ポジティブ', color: 'bg-green-500' },
              { key: 'neutral', label: 'ニュートラル', color: 'bg-gray-400' },
              { key: 'negative', label: 'ネガティブ', color: 'bg-red-500' },
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
