import { useState } from 'react'
import { Link } from 'react-router-dom'
import { MessageSquare, Search } from 'lucide-react'
import { useApi } from '../hooks/useApi'
import LoadingSpinner from '../components/LoadingSpinner'
import { format, parseISO } from 'date-fns'
import { ja } from 'date-fns/locale'

function fmt(seconds) {
  const m = Math.floor(seconds / 60)
  return m >= 60 ? `${Math.floor(m / 60)}時間${m % 60}分` : `${m}分`
}

function sentimentToScore(sentiment) {
  if (sentiment === 'positive') return 82
  if (sentiment === 'negative') return 35
  return 61
}

const SCORE_CONFIG = (score) => {
  if (score >= 80) return { label: 'ホット', className: 'bg-red-100 text-red-700' }
  if (score >= 60) return { label: 'ウォーム', className: 'bg-amber-100 text-amber-700' }
  if (score >= 40) return { label: 'クール', className: 'bg-blue-100 text-blue-700' }
  return { label: 'コールド', className: 'bg-gray-100 text-gray-600' }
}

const STATUS_CONFIG = {
  booked: { label: 'ミーティング予約済', className: 'bg-green-100 text-green-700' },
  qualified: { label: 'リード化済', className: 'bg-purple-100 text-purple-700' },
  ended: { label: '終了', className: 'bg-gray-100 text-gray-500' },
  active: { label: 'アクティブ', className: 'bg-brand-100 text-brand-700' },
}

function convStatus(conv) {
  if (conv.next_steps?.length > 0) return 'booked'
  if (conv.sentiment === 'positive') return 'qualified'
  if (conv.sentiment === 'negative') return 'ended'
  return 'ended'
}

export default function Conversations() {
  const { data: conversations, loading } = useApi('/conversations/')
  const [search, setSearch] = useState('')
  const [scoreFilter, setScoreFilter] = useState('')

  const filtered = (conversations || []).filter(c => {
    const q = search.toLowerCase()
    const matchSearch = c.title.toLowerCase().includes(q) ||
      c.participants?.some(p => p.name.toLowerCase().includes(q))
    const score = sentimentToScore(c.sentiment)
    const matchScore = !scoreFilter ||
      (scoreFilter === 'hot' && score >= 80) ||
      (scoreFilter === 'warm' && score >= 60 && score < 80) ||
      (scoreFilter === 'cool' && score < 60)
    return matchSearch && matchScore
  })

  if (loading) return <LoadingSpinner />

  return (
    <div className="p-8 max-w-6xl mx-auto">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">AI会話</h1>
          <p className="text-gray-500 text-sm mt-1">{conversations?.length || 0}件のAI会話セッション</p>
        </div>
      </div>

      {/* Filters */}
      <div className="flex gap-3 mb-6">
        <div className="relative flex-1 max-w-sm">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          <input
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder="会話・訪問者を検索..."
            className="w-full pl-10 pr-4 py-2.5 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
          />
        </div>
        <select value={scoreFilter} onChange={e => setScoreFilter(e.target.value)}
          className="border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500 bg-white">
          <option value="">全スコア</option>
          <option value="hot">ホット (80+)</option>
          <option value="warm">ウォーム (60-79)</option>
          <option value="cool">クール (40-59)</option>
        </select>
      </div>

      {/* Conversation table */}
      <div className="card p-0 overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50 border-b border-gray-100">
            <tr>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">会話</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">訪問者</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">日時</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">時間</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">リードスコア</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">ステータス</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-50">
            {filtered.map(conv => {
              const score = sentimentToScore(conv.sentiment)
              const scoreCfg = SCORE_CONFIG(score)
              const status = convStatus(conv)
              const statusCfg = STATUS_CONFIG[status]
              return (
                <tr key={conv.id} className="hover:bg-gray-50 transition-colors">
                  <td className="px-6 py-4">
                    <Link to={`/conversations/${conv.id}`} className="font-medium text-sm text-gray-900 hover:text-brand-600 flex items-center gap-2">
                      <MessageSquare size={14} className="text-brand-400 flex-shrink-0" />
                      {conv.title}
                    </Link>
                    {conv.keywords?.length > 0 && (
                      <div className="flex gap-1 mt-1 flex-wrap">
                        {conv.keywords.slice(0, 3).map(k => (
                          <span key={k} className="text-xs bg-gray-100 text-gray-500 px-1.5 py-0.5 rounded">{k}</span>
                        ))}
                      </div>
                    )}
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-500">
                    {conv.participants?.map(p => p.name).join(', ')}
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-500">
                    {conv.date ? format(parseISO(conv.date), 'M月d日 HH:mm', { locale: ja }) : '-'}
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-500">{fmt(conv.duration_seconds)}</td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2">
                      <span className="text-sm font-bold text-gray-900">{score}</span>
                      <span className={`badge ${scoreCfg.className}`}>{scoreCfg.label}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`badge ${statusCfg.className}`}>{statusCfg.label}</span>
                  </td>
                </tr>
              )
            })}
            {filtered.length === 0 && (
              <tr><td colSpan={6} className="px-6 py-12 text-center text-gray-400 text-sm">AI会話が見つかりません</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}
