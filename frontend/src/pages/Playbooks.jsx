import { useState } from 'react'
import { Link } from 'react-router-dom'
import { BookOpen, ChevronRight, Bot } from 'lucide-react'
import { useApi } from '../hooks/useApi'
import LoadingSpinner from '../components/LoadingSpinner'

const STATUS_CONFIG = {
  active:    { label: 'アクティブ', cls: 'bg-green-100 text-green-700' },
  paused:    { label: '一時停止',   cls: 'bg-amber-100 text-amber-700' },
  completed: { label: '完了',       cls: 'bg-gray-100 text-gray-600' },
}

export default function Playbooks() {
  const [filter, setFilter] = useState('all')
  const { data: playbooks, loading } = useApi('/api/playbooks')

  if (loading) return <LoadingSpinner />

  const filtered = filter === 'all' ? (playbooks || []) : (playbooks || []).filter((p) => p.status === filter)

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">プレイブック</h1>
        <div className="flex gap-2">
          {['all', 'active', 'paused', 'completed'].map((s) => (
            <button
              key={s}
              onClick={() => setFilter(s)}
              className={`text-xs px-3 py-1.5 rounded-lg font-medium transition-colors ${
                filter === s ? 'bg-brand-600 text-white' : 'bg-white border border-gray-200 text-gray-600 hover:bg-gray-50'
              }`}
            >
              {s === 'all' ? 'すべて' : STATUS_CONFIG[s]?.label}
            </button>
          ))}
        </div>
      </div>

      {filtered.length === 0 ? (
        <div className="card text-center py-12 text-gray-400">
          <BookOpen size={40} className="mx-auto mb-3 opacity-40" />
          <p>プレイブックがありません</p>
        </div>
      ) : (
        <div className="grid gap-4">
          {filtered.map((pb) => {
            const total = pb.total_steps || 0
            const done = pb.completed_steps || 0
            const pct = total > 0 ? Math.round((done / total) * 100) : 0
            const st = STATUS_CONFIG[pb.status] || STATUS_CONFIG.active
            const next = pb.status_summary?.next_action

            return (
              <Link key={pb.id} to={`/playbooks/${pb.id}`} className="card hover:border-brand-300 border border-gray-100 transition-colors">
                <div className="flex items-start justify-between">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <h3 className="text-sm font-semibold text-gray-900">{pb.title}</h3>
                      <span className={`text-xs px-2 py-0.5 rounded ${st.cls}`}>{st.label}</span>
                      {pb.created_by === 'ai_agent' && (
                        <span className="text-xs bg-purple-50 text-purple-600 px-2 py-0.5 rounded flex items-center gap-1">
                          <Bot size={10} /> AI生成
                        </span>
                      )}
                    </div>
                    {pb.company_name && <p className="text-xs text-gray-500 mt-0.5">{pb.company_name}</p>}
                    {pb.status_summary?.situation && (
                      <p className="text-xs text-gray-500 mt-1 line-clamp-2">{pb.status_summary.situation}</p>
                    )}
                  </div>
                  <ChevronRight size={16} className="text-gray-400 ml-2 flex-shrink-0" />
                </div>

                <div className="mt-3">
                  <div className="flex justify-between text-xs text-gray-500 mb-1">
                    <span>進捗: {done}/{total} ステップ</span>
                    <span>{pct}%</span>
                  </div>
                  <div className="w-full bg-gray-100 rounded-full h-2">
                    <div className="bg-brand-500 h-2 rounded-full transition-all" style={{ width: `${pct}%` }} />
                  </div>
                </div>

                {next && (
                  <div className="mt-2 text-xs text-brand-600 bg-brand-50 px-2 py-1.5 rounded">
                    次のアクション: {next.description || next.action_type}
                  </div>
                )}
              </Link>
            )
          })}
        </div>
      )}
    </div>
  )
}
