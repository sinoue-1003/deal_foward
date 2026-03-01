import { useApi } from '../hooks/useApi'
import LoadingSpinner from '../components/LoadingSpinner'
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, LineChart, Line, Cell } from 'recharts'
import { format, parseISO } from 'date-fns'
import { ja } from 'date-fns/locale'

function fmtMoney(v) {
  if (v >= 1000000) return `¥${(v / 1000000).toFixed(1)}M`
  if (v >= 10000) return `¥${(v / 10000).toFixed(0)}万`
  return `¥${v.toLocaleString()}`
}

const STAGE_COLORS = {
  prospect: '#94a3b8',
  qualify: '#60a5fa',
  demo: '#a78bfa',
  proposal: '#fbbf24',
  negotiation: '#fb923c',
  closed_won: '#34d399',
  closed_lost: '#f87171',
}

export default function Analytics() {
  const { data: overview, loading: ol } = useApi('/analytics/overview')
  const { data: pipeline, loading: pl } = useApi('/analytics/pipeline')
  const { data: trends, loading: tl } = useApi('/analytics/call-trends?days=30')

  if (ol || pl || tl) return <LoadingSpinner />

  const openPipeline = pipeline?.filter(s => !['closed_won', 'closed_lost'].includes(s.stage)) || []

  return (
    <div className="p-8 max-w-7xl mx-auto">
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900">分析</h1>
        <p className="text-gray-500 text-sm mt-1">営業パフォーマンスの詳細分析</p>
      </div>

      {/* KPIs */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        {[
          { label: 'パイプライン総額', value: fmtMoney(overview?.deals.pipeline_value || 0), color: 'text-brand-600' },
          { label: '成約率', value: `${overview?.deals.win_rate || 0}%`, color: 'text-green-600' },
          { label: '総ディール数', value: overview?.deals.total || 0, color: 'text-gray-900' },
          { label: '平均通話時間', value: `${Math.round((overview?.calls.avg_duration_seconds || 0) / 60)}分`, color: 'text-purple-600' },
        ].map(({ label, value, color }) => (
          <div key={label} className="card text-center">
            <p className="text-sm text-gray-500">{label}</p>
            <p className={`text-3xl font-bold mt-1 ${color}`}>{value}</p>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-2 gap-6 mb-6">
        {/* Pipeline by stage */}
        <div className="card">
          <h2 className="font-semibold mb-4 text-gray-900">ステージ別パイプライン</h2>
          <ResponsiveContainer width="100%" height={240}>
            <BarChart data={openPipeline} margin={{ top: 0, right: 0, left: 0, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
              <XAxis dataKey="label" tick={{ fontSize: 11 }} />
              <YAxis tickFormatter={fmtMoney} tick={{ fontSize: 11 }} />
              <Tooltip formatter={(v) => fmtMoney(v)} labelFormatter={l => l} />
              <Bar dataKey="total_amount" radius={[4, 4, 0, 0]}>
                {openPipeline.map(entry => (
                  <Cell key={entry.stage} fill={STAGE_COLORS[entry.stage] || '#94a3b8'} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Deal count by stage */}
        <div className="card">
          <h2 className="font-semibold mb-4 text-gray-900">ステージ別ディール数</h2>
          <div className="space-y-3">
            {pipeline?.map(s => (
              <div key={s.stage} className="flex items-center gap-3">
                <span className="text-sm text-gray-600 w-20 flex-shrink-0">{s.label}</span>
                <div className="flex-1 h-6 bg-gray-100 rounded-md overflow-hidden relative">
                  {s.count > 0 && (
                    <div
                      className="h-full rounded-md flex items-center pl-2"
                      style={{
                        width: `${Math.max(s.count / Math.max(...pipeline.map(x => x.count)) * 100, 5)}%`,
                        backgroundColor: STAGE_COLORS[s.stage] || '#94a3b8',
                      }}
                    >
                      <span className="text-white text-xs font-medium">{s.count}件</span>
                    </div>
                  )}
                  {s.count === 0 && <span className="text-gray-400 text-xs pl-2 leading-6">0件</span>}
                </div>
                <span className="text-sm font-medium text-gray-700 w-20 text-right">{fmtMoney(s.total_amount)}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Call trends */}
      <div className="card mb-6">
        <h2 className="font-semibold mb-4 text-gray-900">通話トレンド (過去30日)</h2>
        <ResponsiveContainer width="100%" height={200}>
          <LineChart data={trends} margin={{ top: 0, right: 0, left: 0, bottom: 0 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
            <XAxis dataKey="date" tick={{ fontSize: 10 }}
              tickFormatter={d => format(parseISO(d), 'M/d', { locale: ja })} />
            <YAxis tick={{ fontSize: 11 }} />
            <Tooltip labelFormatter={d => format(parseISO(d), 'M月d日', { locale: ja })} formatter={v => [`${v}件`, '通話数']} />
            <Line type="monotone" dataKey="count" stroke="#0ea5e9" strokeWidth={2} dot={false} />
          </LineChart>
        </ResponsiveContainer>
      </div>

      {/* Sentiment breakdown */}
      {overview?.sentiment && (
        <div className="card">
          <h2 className="font-semibold mb-4 text-gray-900">感情分析の内訳</h2>
          <div className="grid grid-cols-3 gap-6">
            {[
              { key: 'positive', label: 'ポジティブ', color: 'bg-green-500', textColor: 'text-green-600' },
              { key: 'neutral', label: 'ニュートラル', color: 'bg-gray-400', textColor: 'text-gray-600' },
              { key: 'negative', label: 'ネガティブ', color: 'bg-red-500', textColor: 'text-red-600' },
            ].map(({ key, label, color, textColor }) => {
              const count = overview.sentiment[key] || 0
              const total = Object.values(overview.sentiment).reduce((a, b) => a + b, 0)
              const pct = total > 0 ? Math.round(count / total * 100) : 0
              return (
                <div key={key} className="text-center">
                  <div className={`text-4xl font-bold ${textColor}`}>{pct}%</div>
                  <div className="text-sm text-gray-500 mt-1">{label}</div>
                  <div className="text-xs text-gray-400 mt-0.5">{count}件の通話</div>
                  <div className="h-2 bg-gray-100 rounded-full overflow-hidden mt-3">
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
