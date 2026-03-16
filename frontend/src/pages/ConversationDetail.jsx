import { useParams, Link } from 'react-router-dom'
import { ArrowLeft, Cpu, ChevronRight, Bot, User, Calendar, Tag, Lightbulb } from 'lucide-react'
import { useApi, api } from '../hooks/useApi'
import LoadingSpinner from '../components/LoadingSpinner'
import { format, parseISO } from 'date-fns'
import { ja } from 'date-fns/locale'
import { useState } from 'react'

function fmt(s) {
  const m = Math.floor(s / 60)
  return m >= 60 ? `${Math.floor(m / 60)}時間${m % 60}分` : `${m}分`
}

function sentimentToScore(sentiment) {
  if (sentiment === 'positive') return 82
  if (sentiment === 'negative') return 35
  return 61
}

function ScoreBadge({ score }) {
  const config = score >= 80
    ? { label: 'ホット', className: 'bg-red-100 text-red-700' }
    : score >= 60
    ? { label: 'ウォーム', className: 'bg-amber-100 text-amber-700' }
    : { label: 'クール', className: 'bg-blue-100 text-blue-700' }
  return (
    <span className={`badge ${config.className}`}>{config.label} ({score})</span>
  )
}

// Parse transcript into message bubbles
function parseTranscript(transcript) {
  if (!transcript) return []
  const lines = transcript.split('\n').filter(l => l.trim())
  const messages = []
  let currentRole = null
  let currentText = []

  for (const line of lines) {
    const botMatch = line.match(/^(AI|Bot|Breakout|システム|担当AI)[:：]\s*(.+)/)
    const userMatch = line.match(/^(訪問者|ユーザー|顧客|見込み客|お客様)[:：]\s*(.+)/)
    if (botMatch) {
      if (currentRole && currentText.length) messages.push({ role: currentRole, text: currentText.join(' ') })
      currentRole = 'bot'
      currentText = [botMatch[2]]
    } else if (userMatch) {
      if (currentRole && currentText.length) messages.push({ role: currentRole, text: currentText.join(' ') })
      currentRole = 'user'
      currentText = [userMatch[2]]
    } else if (currentRole) {
      currentText.push(line)
    } else {
      // Default: alternate bot/user
      messages.push({ role: messages.length % 2 === 0 ? 'bot' : 'user', text: line })
    }
  }
  if (currentRole && currentText.length) messages.push({ role: currentRole, text: currentText.join(' ') })
  return messages
}

export default function ConversationDetail() {
  const { id } = useParams()
  const { data: conv, loading, refetch } = useApi(`/conversations/${id}`)
  const [analyzing, setAnalyzing] = useState(false)

  async function runAnalysis() {
    setAnalyzing(true)
    try {
      await api.post(`/conversations/${id}/analyze`, {})
      refetch()
    } finally {
      setAnalyzing(false)
    }
  }

  if (loading) return <LoadingSpinner />
  if (!conv) return <div className="p-8 text-gray-500">会話が見つかりません</div>

  const score = sentimentToScore(conv.sentiment)
  const messages = parseTranscript(conv.transcript)
  const rep = conv.participants?.find(p => p.role === 'rep')
  const prospect = conv.participants?.find(p => p.role === 'prospect')

  return (
    <div className="p-8 max-w-5xl mx-auto">
      <Link to="/conversations" className="flex items-center gap-1 text-gray-400 hover:text-gray-700 text-sm mb-6">
        <ArrowLeft size={14} /> AI会話一覧に戻る
      </Link>

      <div className="flex items-start justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">{conv.title}</h1>
          <p className="text-gray-500 text-sm mt-1">
            {conv.date ? format(parseISO(conv.date), 'yyyy年M月d日 HH:mm', { locale: ja }) : '-'}
            {' · '}{fmt(conv.duration_seconds)}
          </p>
        </div>
        <div className="flex items-center gap-3">
          <ScoreBadge score={score} />
          {conv.transcript && (
            <button onClick={runAnalysis} disabled={analyzing}
              className="btn-secondary flex items-center gap-2 text-sm">
              <Cpu size={14} /> {analyzing ? '分析中...' : 'AI再分析'}
            </button>
          )}
        </div>
      </div>

      <div className="grid grid-cols-3 gap-6">
        {/* Left: Chat transcript */}
        <div className="col-span-2 space-y-5">
          {/* Summary */}
          {conv.summary && (
            <div className="card">
              <h3 className="font-semibold mb-2 text-sm text-gray-700 flex items-center gap-1.5">
                <Lightbulb size={14} className="text-amber-500" /> AI会話サマリー
              </h3>
              <p className="text-sm text-gray-600 leading-relaxed">{conv.summary}</p>
            </div>
          )}

          {/* Chat messages */}
          {messages.length > 0 ? (
            <div className="card">
              <h3 className="font-semibold mb-4 text-sm text-gray-700">会話ログ</h3>
              <div className="space-y-4 max-h-96 overflow-y-auto pr-2">
                {messages.map((msg, i) => (
                  <div key={i} className={`flex gap-3 ${msg.role === 'bot' ? '' : 'flex-row-reverse'}`}>
                    <div className={`w-7 h-7 rounded-full flex items-center justify-center flex-shrink-0 ${
                      msg.role === 'bot' ? 'bg-brand-100 text-brand-700' : 'bg-gray-100 text-gray-600'
                    }`}>
                      {msg.role === 'bot' ? <Bot size={14} /> : <User size={14} />}
                    </div>
                    <div className={`max-w-xs lg:max-w-sm xl:max-w-md rounded-2xl px-4 py-2.5 text-sm leading-relaxed ${
                      msg.role === 'bot'
                        ? 'bg-brand-50 text-gray-800 rounded-tl-sm'
                        : 'bg-gray-100 text-gray-800 rounded-tr-sm'
                    }`}>
                      {msg.text}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          ) : conv.transcript ? (
            <div className="card">
              <h3 className="font-semibold mb-3 text-sm text-gray-700">会話ログ</h3>
              <div className="bg-gray-50 rounded-lg p-4 max-h-96 overflow-y-auto">
                <pre className="text-sm text-gray-700 whitespace-pre-wrap font-sans leading-relaxed">
                  {conv.transcript}
                </pre>
              </div>
            </div>
          ) : (
            <div className="card border-dashed border-2 border-gray-200 flex flex-col items-center justify-center py-12 text-center">
              <p className="text-gray-400 text-sm">会話ログがありません</p>
            </div>
          )}

          {/* Next Steps */}
          {conv.next_steps?.length > 0 && (
            <div className="card">
              <h3 className="font-semibold mb-3 text-sm text-gray-700">ネクストアクション</h3>
              <ul className="space-y-2">
                {conv.next_steps.map((step, i) => (
                  <li key={i} className="flex items-start gap-2 text-sm">
                    <ChevronRight size={14} className="text-brand-500 mt-0.5 flex-shrink-0" />
                    <span className="text-gray-700">{step}</span>
                  </li>
                ))}
              </ul>
            </div>
          )}
        </div>

        {/* Right: Analysis sidebar */}
        <div className="space-y-4">
          {/* Lead score */}
          <div className="card">
            <h3 className="font-semibold mb-3 text-sm text-gray-700">リードスコア</h3>
            <div className="text-center">
              <div className={`text-5xl font-bold mb-2 ${score >= 80 ? 'text-red-600' : score >= 60 ? 'text-amber-600' : 'text-blue-600'}`}>
                {score}
              </div>
              <ScoreBadge score={score} />
              <div className="mt-3 h-2 bg-gray-100 rounded-full overflow-hidden">
                <div className={`h-full rounded-full ${score >= 80 ? 'bg-red-500' : score >= 60 ? 'bg-amber-400' : 'bg-blue-400'}`}
                  style={{ width: `${score}%` }} />
              </div>
            </div>
          </div>

          {/* Participants */}
          <div className="card">
            <h3 className="font-semibold mb-3 text-sm text-gray-700">参加者</h3>
            <div className="space-y-2">
              {conv.participants?.map(p => (
                <div key={p.name} className="flex items-center gap-2">
                  <div className="w-7 h-7 rounded-full bg-brand-100 text-brand-700 flex items-center justify-center text-xs font-bold">
                    {p.name?.[0]}
                  </div>
                  <div>
                    <p className="text-sm font-medium">{p.name}</p>
                    <p className="text-xs text-gray-400">{p.role === 'rep' ? 'AI担当' : '訪問者'}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Talk ratio */}
          {conv.talk_ratio && (
            <div className="card">
              <h3 className="font-semibold mb-3 text-sm text-gray-700">発話比率</h3>
              <div className="space-y-2">
                {[
                  { label: 'AI担当', value: conv.talk_ratio.rep, color: 'bg-brand-500' },
                  { label: '訪問者', value: conv.talk_ratio.prospect, color: 'bg-green-500' },
                ].map(({ label, value, color }) => (
                  <div key={label}>
                    <div className="flex justify-between text-xs mb-1">
                      <span className="text-gray-600">{label}</span>
                      <span className="font-medium">{value}%</span>
                    </div>
                    <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
                      <div className={`h-full ${color} rounded-full`} style={{ width: `${value}%` }} />
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Intent signals (keywords) */}
          {conv.keywords?.length > 0 && (
            <div className="card">
              <h3 className="font-semibold mb-3 text-sm text-gray-700 flex items-center gap-1.5">
                <Tag size={14} /> インテントシグナル
              </h3>
              <div className="flex flex-wrap gap-1.5">
                {conv.keywords.map(k => (
                  <span key={k} className="badge bg-brand-50 text-brand-700">{k}</span>
                ))}
              </div>
            </div>
          )}

          {/* Lead link */}
          {conv.deal_id && (
            <div className="card">
              <h3 className="font-semibold mb-2 text-sm text-gray-700">関連リード</h3>
              <Link to={`/leads/${conv.deal_id}`} className="text-brand-600 hover:underline text-sm flex items-center gap-1">
                <Calendar size={14} /> リード #{conv.deal_id} を表示
              </Link>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
