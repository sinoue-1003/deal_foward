import { useApi } from '../hooks/useApi'
import LoadingSpinner from '../components/LoadingSpinner'
import StatCard from '../components/StatCard'
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  Cell
} from 'recharts'
import { BookOpen, TrendingUp, Radio, Bot } from 'lucide-react'

const STAGE_LABELS = {
  prospect: 'プロスペクト', qualify: '資格審査', demo: 'デモ',
  proposal: '提案', negotiation: '交渉', closed_won: '受注', closed_lost: '失注',
}

const STAGE_COLORS = {
  prospect: '#94a3b8', qualify: '#60a5fa', demo: '#a78bfa',
  proposal: '#fbbf24', negotiation: '#f97316', closed_won: '#34d399', closed_lost: '#f87171',
}

export default function Analytics() {
  const { data: overview, loading: l1 } = useApi('/api/dashboard/overview')
  const { data: pipeline, loading: l2 } = useApi('/api/dashboard/pipeline')

  if (l1 || l2) return <LoadingSpinner />

  const stageData = (pipeline?.by_stage || []).map((s) => ({
    ...s,
    name: STAGE_LABELS[s.stage] || s.stage,
    color: STAGE_COLORS[s.stage] || '#94a3b8',
  }))

  const wonDeals = pipeline?.by_stage?.find((s) => s.stage === 'closed_won')
  const lostDeals = pipeline?.by_stage?.find((s) => s.stage === 'closed_lost')
  const totalClosed = (wonDeals?.count || 0) + (lostDeals?.count || 0)
  const winRate = totalClosed > 0 ? Math.round(((wonDeals?.count || 0) / totalClosed) * 100) : 0

  return (
    <div className="p-6 space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">アナリティクス</h1>

      {/* KPI */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          label="パイプライン総額"
          value={`¥${((overview?.pipeline_value || 0) / 10000).toLocaleString()}万`}
          icon={TrendingUp} color="brand"
        />
        <StatCard
          label="受注率"
          value={`${winRate}%`}
          icon={BookOpen} color="green"
          sub={`${wonDeals?.count || 0}/${totalClosed} 件`}
        />
        <StatCard
          label="アクティブプレイブック"
          value={overview?.active_playbooks || 0}
          icon={BookOpen} color="purple"
        />
        <StatCard
          label="総通信分析数"
          value={overview?.analyzed_communications || 0}
          icon={Radio} color="amber"
        />
      </div>

      <div className="grid grid-cols-2 gap-6">
        {/* Pipeline by stage */}
        <div className="card">
          <h2 className="text-sm font-semibold text-gray-700 mb-4">ステージ別パイプライン (金額)</h2>
          <ResponsiveContainer width="100%" height={220}>
            <BarChart data={stageData} margin={{ top: 4, right: 4, bottom: 20, left: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
              <XAxis dataKey="name" tick={{ fontSize: 10 }} angle={-30} textAnchor="end" />
              <YAxis tick={{ fontSize: 10 }} tickFormatter={(v) => `${(v / 10000).toFixed(0)}万`} />
              <Tooltip formatter={(v) => `¥${Number(v).toLocaleString()}`} />
              <Bar dataKey="total_amount" radius={[4, 4, 0, 0]}>
                {stageData.map((s, i) => <Cell key={i} fill={s.color} />)}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Stage by deal count */}
        <div className="card">
          <h2 className="text-sm font-semibold text-gray-700 mb-4">ステージ別商談数</h2>
          <ResponsiveContainer width="100%" height={220}>
            <BarChart data={stageData} layout="vertical" margin={{ top: 4, right: 20, bottom: 4, left: 50 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
              <XAxis type="number" tick={{ fontSize: 10 }} />
              <YAxis dataKey="name" type="category" tick={{ fontSize: 10 }} />
              <Tooltip />
              <Bar dataKey="count" radius={[0, 4, 4, 0]}>
                {stageData.map((s, i) => <Cell key={i} fill={s.color} />)}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Active playbooks table */}
      <div className="card">
        <h2 className="text-sm font-semibold text-gray-700 mb-4 flex items-center gap-2">
          <Bot size={14} className="text-brand-500" />
          アクティブプレイブック状況
        </h2>
        {pipeline?.active_playbooks?.length ? (
          <div className="space-y-2">
            {pipeline.active_playbooks.map((pb) => {
              const total = (pb.steps || []).length
              const done = (pb.steps || []).filter((s) => s.status === 'completed').length
              const pct = total > 0 ? Math.round((done / total) * 100) : 0
              return (
                <div key={pb.id} className="flex items-center gap-4 p-3 bg-gray-50 rounded-lg">
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-gray-800">{pb.title}</p>
                    {pb.company_name && <p className="text-xs text-gray-500">{pb.company_name}</p>}
                  </div>
                  <div className="w-32 flex items-center gap-2">
                    <div className="flex-1 bg-gray-200 rounded-full h-2">
                      <div className="bg-brand-500 h-2 rounded-full" style={{ width: `${pct}%` }} />
                    </div>
                    <span className="text-xs text-gray-500">{pct}%</span>
                  </div>
                </div>
              )
            })}
          </div>
        ) : (
          <p className="text-sm text-gray-400">アクティブなプレイブックなし</p>
        )}
      </div>
    </div>
  )
}
