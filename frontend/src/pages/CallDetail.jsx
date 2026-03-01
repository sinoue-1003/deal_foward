import { useParams, Link } from 'react-router-dom'
import { ArrowLeft, Cpu, Users, Clock, ChevronRight } from 'lucide-react'
import { useApi, api } from '../hooks/useApi'
import SentimentBadge from '../components/SentimentBadge'
import LoadingSpinner from '../components/LoadingSpinner'
import { format, parseISO } from 'date-fns'
import { ja } from 'date-fns/locale'
import { useState } from 'react'

function fmt(s) {
  const m = Math.floor(s / 60)
  return m >= 60 ? `${Math.floor(m / 60)}時間${m % 60}分` : `${m}分`
}

export default function CallDetail() {
  const { id } = useParams()
  const { data: call, loading, refetch } = useApi(`/calls/${id}`)
  const [analyzing, setAnalyzing] = useState(false)

  async function runAnalysis() {
    setAnalyzing(true)
    try {
      await api.post(`/calls/${id}/analyze`, {})
      refetch()
    } finally {
      setAnalyzing(false)
    }
  }

  if (loading) return <LoadingSpinner />
  if (!call) return <div className="p-8 text-gray-500">通話が見つかりません</div>

  const rep = call.participants?.find(p => p.role === 'rep')
  const prospect = call.participants?.find(p => p.role === 'prospect')

  return (
    <div className="p-8 max-w-5xl mx-auto">
      <Link to="/calls" className="flex items-center gap-1 text-gray-400 hover:text-gray-700 text-sm mb-6">
        <ArrowLeft size={14} /> 通話一覧に戻る
      </Link>

      <div className="flex items-start justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">{call.title}</h1>
          <p className="text-gray-500 text-sm mt-1">
            {call.date ? format(parseISO(call.date), 'yyyy年M月d日 HH:mm', { locale: ja }) : '-'}
            {' · '}{fmt(call.duration_seconds)}
          </p>
        </div>
        <div className="flex items-center gap-3">
          {call.sentiment && <SentimentBadge sentiment={call.sentiment} />}
          {call.transcript && (
            <button onClick={runAnalysis} disabled={analyzing}
              className="btn-secondary flex items-center gap-2 text-sm">
              <Cpu size={14} /> {analyzing ? '分析中...' : 'AI再分析'}
            </button>
          )}
        </div>
      </div>

      <div className="grid grid-cols-3 gap-6">
        {/* Left: Analysis */}
        <div className="col-span-2 space-y-5">
          {/* Summary */}
          {call.summary && (
            <div className="card">
              <h3 className="font-semibold mb-2 text-sm text-gray-700">通話サマリー</h3>
              <p className="text-sm text-gray-600 leading-relaxed">{call.summary}</p>
            </div>
          )}

          {/* Next Steps */}
          {call.next_steps?.length > 0 && (
            <div className="card">
              <h3 className="font-semibold mb-3 text-sm text-gray-700">ネクストステップ</h3>
              <ul className="space-y-2">
                {call.next_steps.map((step, i) => (
                  <li key={i} className="flex items-start gap-2 text-sm">
                    <ChevronRight size={14} className="text-brand-500 mt-0.5 flex-shrink-0" />
                    <span className="text-gray-700">{step}</span>
                  </li>
                ))}
              </ul>
            </div>
          )}

          {/* Transcript */}
          {call.transcript && (
            <div className="card">
              <h3 className="font-semibold mb-3 text-sm text-gray-700">トランスクリプト</h3>
              <div className="bg-gray-50 rounded-lg p-4 max-h-96 overflow-y-auto">
                <pre className="text-sm text-gray-700 whitespace-pre-wrap font-sans leading-relaxed">
                  {call.transcript}
                </pre>
              </div>
            </div>
          )}

          {!call.transcript && (
            <div className="card border-dashed border-2 border-gray-200 flex flex-col items-center justify-center py-12 text-center">
              <p className="text-gray-400 text-sm">トランスクリプトがありません</p>
              <p className="text-gray-300 text-xs mt-1">音声ファイルをアップロードするか、手動でテキストを追加してください</p>
            </div>
          )}
        </div>

        {/* Right: Metadata */}
        <div className="space-y-4">
          {/* Participants */}
          <div className="card">
            <h3 className="font-semibold mb-3 text-sm text-gray-700 flex items-center gap-1.5">
              <Users size={14} /> 参加者
            </h3>
            <div className="space-y-2">
              {call.participants?.map(p => (
                <div key={p.name} className="flex items-center gap-2">
                  <div className="w-7 h-7 rounded-full bg-brand-100 text-brand-700 flex items-center justify-center text-xs font-bold">
                    {p.name?.[0]}
                  </div>
                  <div>
                    <p className="text-sm font-medium">{p.name}</p>
                    <p className="text-xs text-gray-400">{p.role === 'rep' ? '営業担当' : '顧客'}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Talk ratio */}
          {call.talk_ratio && (
            <div className="card">
              <h3 className="font-semibold mb-3 text-sm text-gray-700 flex items-center gap-1.5">
                <Clock size={14} /> 発話比率
              </h3>
              <div className="space-y-2">
                {[
                  { label: rep?.name || '担当者', value: call.talk_ratio.rep, color: 'bg-brand-500' },
                  { label: prospect?.name || '顧客', value: call.talk_ratio.prospect, color: 'bg-green-500' },
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

          {/* Keywords */}
          {call.keywords?.length > 0 && (
            <div className="card">
              <h3 className="font-semibold mb-3 text-sm text-gray-700">キーワード</h3>
              <div className="flex flex-wrap gap-1.5">
                {call.keywords.map(k => (
                  <span key={k} className="badge bg-brand-50 text-brand-700">{k}</span>
                ))}
              </div>
            </div>
          )}

          {/* Deal link */}
          {call.deal_id && (
            <div className="card">
              <h3 className="font-semibold mb-2 text-sm text-gray-700">関連ディール</h3>
              <Link to={`/deals/${call.deal_id}`} className="text-brand-600 hover:underline text-sm flex items-center gap-1">
                ディール #{call.deal_id} を表示 <ChevronRight size={14} />
              </Link>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
