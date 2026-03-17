import { MessageSquare, TrendingUp, ChevronRight } from 'lucide-react'
import { Link } from 'react-router-dom'
import { useApi } from '../hooks/useApi'
import LoadingSpinner from '../components/LoadingSpinner'
import IntentBadge from '../components/IntentBadge'

const STATUS_LABEL = {
  active:    { label: '会話中',   cls: 'bg-green-100 text-green-700' },
  ended:     { label: '終了',     cls: 'bg-gray-100 text-gray-500' },
  converted: { label: 'コンバート済', cls: 'bg-brand-100 text-brand-700' },
}

export default function Chatbot() {
  const { data: sessions, loading } = useApi('/api/chatbot/sessions?limit=50')

  if (loading) return <LoadingSpinner />

  const hot = (sessions || []).filter((s) => s.intent_score >= 70)
  const all = sessions || []

  return (
    <div className="p-6 space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">チャットbot</h1>

      {/* Summary */}
      <div className="grid grid-cols-3 gap-4">
        <div className="card text-center">
          <p className="text-2xl font-bold text-gray-900">{all.length}</p>
          <p className="text-sm text-gray-500 mt-1">総セッション数</p>
        </div>
        <div className="card text-center">
          <p className="text-2xl font-bold text-red-600">{hot.length}</p>
          <p className="text-sm text-gray-500 mt-1">高インテント (70+)</p>
        </div>
        <div className="card text-center">
          <p className="text-2xl font-bold text-green-600">
            {all.filter((s) => s.status === 'converted').length}
          </p>
          <p className="text-sm text-gray-500 mt-1">コンバート済</p>
        </div>
      </div>

      {/* Session list */}
      <div className="card overflow-hidden p-0">
        <div className="px-4 py-3 border-b border-gray-100">
          <h2 className="text-sm font-semibold text-gray-700">セッション一覧</h2>
        </div>
        <div className="divide-y divide-gray-50">
          {all.length === 0 && (
            <p className="text-sm text-gray-400 p-4">セッションがありません</p>
          )}
          {all.map((s) => {
            const st = STATUS_LABEL[s.status] || STATUS_LABEL.ended
            return (
              <Link key={s.id} to={`/chatbot/${s.id}`} className="flex items-center gap-4 px-4 py-3 hover:bg-gray-50 transition-colors">
                <div className="w-8 h-8 rounded-full bg-gray-100 flex items-center justify-center text-gray-600 flex-shrink-0">
                  <MessageSquare size={14} />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-gray-800 truncate">
                    {s.company_name || s.contact_name || 'Anonymous'}
                  </p>
                  <p className="text-xs text-gray-400">{s.message_count} メッセージ</p>
                </div>
                <div className="flex items-center gap-2">
                  <IntentBadge score={s.intent_score} />
                  <span className={`text-xs px-2 py-0.5 rounded ${st.cls}`}>{st.label}</span>
                  <ChevronRight size={14} className="text-gray-400" />
                </div>
              </Link>
            )
          })}
        </div>
      </div>
    </div>
  )
}
