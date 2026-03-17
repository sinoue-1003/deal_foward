import { useParams } from 'react-router-dom'
import { Bot, User } from 'lucide-react'
import { useApi } from '../hooks/useApi'
import LoadingSpinner from '../components/LoadingSpinner'
import IntentBadge from '../components/IntentBadge'

export default function ChatbotDetail() {
  const { id } = useParams()
  const { data: session, loading } = useApi(`/api/chatbot/sessions/${id}`)

  if (loading) return <LoadingSpinner />
  if (!session) return <div className="p-6 text-gray-500">セッションが見つかりません</div>

  const messages = session.messages || []

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">
            {session.company?.name || session.contact?.name || 'チャットセッション'}
          </h1>
          <p className="text-gray-500 text-sm mt-1">セッション詳細</p>
        </div>
        <IntentBadge score={session.intent_score} />
      </div>

      <div className="grid grid-cols-3 gap-6">
        {/* Chat messages */}
        <div className="col-span-2 card">
          <h2 className="text-sm font-semibold text-gray-700 mb-4">会話履歴</h2>
          <div className="space-y-3 max-h-[600px] overflow-y-auto">
            {messages.length === 0 && (
              <p className="text-sm text-gray-400">メッセージがありません</p>
            )}
            {messages.map((m, i) => (
              <div key={i} className={`flex gap-3 ${m.role === 'user' ? 'justify-end' : ''}`}>
                {m.role === 'assistant' && (
                  <div className="w-7 h-7 rounded-full bg-brand-100 flex items-center justify-center flex-shrink-0">
                    <Bot size={14} className="text-brand-600" />
                  </div>
                )}
                <div className={`max-w-[75%] px-3 py-2 rounded-xl text-sm ${
                  m.role === 'user'
                    ? 'bg-brand-600 text-white rounded-br-sm'
                    : 'bg-gray-100 text-gray-800 rounded-bl-sm'
                }`}>
                  {m.content}
                </div>
                {m.role === 'user' && (
                  <div className="w-7 h-7 rounded-full bg-gray-200 flex items-center justify-center flex-shrink-0">
                    <User size={14} className="text-gray-600" />
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>

        {/* Sidebar */}
        <div className="space-y-4">
          <div className="card">
            <h2 className="text-sm font-semibold text-gray-700 mb-3">インテントスコア</h2>
            <div className="text-center">
              <p className="text-4xl font-bold text-gray-900">{session.intent_score}</p>
              <IntentBadge score={session.intent_score} />
            </div>
            <div className="mt-3 w-full bg-gray-100 rounded-full h-2">
              <div
                className="h-2 rounded-full bg-gradient-to-r from-blue-400 to-red-500"
                style={{ width: `${session.intent_score}%` }}
              />
            </div>
          </div>

          {session.company && (
            <div className="card">
              <h2 className="text-sm font-semibold text-gray-700 mb-2">会社情報</h2>
              <p className="text-sm text-gray-800">{session.company.name}</p>
              {session.company.industry && <p className="text-xs text-gray-500">{session.company.industry}</p>}
            </div>
          )}

          <div className="card">
            <h2 className="text-sm font-semibold text-gray-700 mb-2">セッション情報</h2>
            <dl className="space-y-1 text-xs">
              <div className="flex justify-between">
                <dt className="text-gray-500">メッセージ数</dt>
                <dd className="text-gray-800">{messages.length}</dd>
              </div>
              <div className="flex justify-between">
                <dt className="text-gray-500">ステータス</dt>
                <dd className="text-gray-800">{session.status}</dd>
              </div>
              <div className="flex justify-between">
                <dt className="text-gray-500">開始時刻</dt>
                <dd className="text-gray-800">
                  {new Date(session.created_at).toLocaleString('ja-JP')}
                </dd>
              </div>
            </dl>
          </div>
        </div>
      </div>
    </div>
  )
}
