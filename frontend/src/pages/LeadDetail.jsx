import { useParams, Link } from 'react-router-dom'
import { ArrowLeft, MessageSquare, Mail, User, Building, ChevronRight, Brain, Target } from 'lucide-react'
import { useApi, api } from '../hooks/useApi'
import LoadingSpinner from '../components/LoadingSpinner'
import { format, parseISO } from 'date-fns'
import { ja } from 'date-fns/locale'
import { useState } from 'react'

function fmtMoney(v) {
  return new Intl.NumberFormat('ja-JP', { style: 'currency', currency: 'JPY', maximumFractionDigits: 0 }).format(v)
}

function fmt(s) {
  const m = Math.floor(s / 60)
  return m >= 60 ? `${Math.floor(m / 60)}時間${m % 60}分` : `${m}分`
}

const STAGES = ['prospect', 'qualify', 'demo', 'proposal', 'negotiation', 'closed_won', 'closed_lost']
const STAGE_LABELS = {
  prospect: '新規リード',
  qualify: 'コンタクト済',
  demo: '資格確認済',
  proposal: 'デモ予約済',
  negotiation: '交渉中',
  closed_won: '成約',
  closed_lost: '失注',
}
const STAGE_COLORS = {
  prospect: 'bg-gray-100 text-gray-600',
  qualify: 'bg-blue-100 text-blue-700',
  demo: 'bg-purple-100 text-purple-700',
  proposal: 'bg-green-100 text-green-700',
  negotiation: 'bg-amber-100 text-amber-700',
  closed_won: 'bg-emerald-100 text-emerald-700',
  closed_lost: 'bg-red-100 text-red-700',
}

function sentimentToScore(sentiment) {
  if (sentiment === 'positive') return 82
  if (sentiment === 'negative') return 35
  return 61
}

// Mock AI-generated company intelligence
const MOCK_INTEL = {
  industry: 'SaaS / エンタープライズソフトウェア',
  size: '500-1000名',
  revenue: '約50億円',
  techStack: ['Salesforce', 'Slack', 'AWS', 'Zendesk'],
  painPoints: ['営業プロセスの非効率', 'リード対応の遅延', 'コンバージョン率の低下'],
  buyingSignals: ['料金ページを3回訪問', 'デモ申込ページを閲覧', '競合比較ページを確認'],
}

export default function LeadDetail() {
  const { id } = useParams()
  const { data: lead, loading, refetch } = useApi(`/leads/${id}`)
  const [editing, setEditing] = useState(false)
  const [form, setForm] = useState(null)

  function startEdit() {
    setForm({ stage: lead.stage, amount: lead.amount, probability: lead.probability, notes: lead.notes || '' })
    setEditing(true)
  }

  async function saveEdit(e) {
    e.preventDefault()
    await api.patch(`/leads/${id}`, form)
    setEditing(false)
    refetch()
  }

  if (loading) return <LoadingSpinner />
  if (!lead) return <div className="p-8 text-gray-500">リードが見つかりません</div>

  const stageColor = STAGE_COLORS[lead.stage] || 'bg-gray-100 text-gray-600'

  return (
    <div className="p-8 max-w-5xl mx-auto">
      <Link to="/leads" className="flex items-center gap-1 text-gray-400 hover:text-gray-700 text-sm mb-6">
        <ArrowLeft size={14} /> リード一覧に戻る
      </Link>

      <div className="flex items-start justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">{lead.name}</h1>
          <p className="text-gray-500 text-sm mt-1 flex items-center gap-1.5">
            <Building size={13} /> {lead.company}
          </p>
        </div>
        <div className="flex items-center gap-3">
          <span className={`badge ${stageColor}`}>{STAGE_LABELS[lead.stage] || lead.stage}</span>
          <button onClick={startEdit} className="btn-secondary text-sm">編集</button>
        </div>
      </div>

      <div className="grid grid-cols-3 gap-6">
        <div className="col-span-2 space-y-5">
          {/* Edit form */}
          {editing && form && (
            <div className="card border-brand-200">
              <h3 className="font-semibold mb-4">リード情報の編集</h3>
              <form onSubmit={saveEdit} className="space-y-3">
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="text-xs text-gray-500 mb-1 block">ステージ</label>
                    <select value={form.stage} onChange={e => setForm({ ...form, stage: e.target.value })}
                      className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500 bg-white">
                      {STAGES.map(s => <option key={s} value={s}>{STAGE_LABELS[s]}</option>)}
                    </select>
                  </div>
                  <div>
                    <label className="text-xs text-gray-500 mb-1 block">想定契約額 (円)</label>
                    <input type="number" value={form.amount} onChange={e => setForm({ ...form, amount: parseFloat(e.target.value) })}
                      className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500" />
                  </div>
                </div>
                <div>
                  <label className="text-xs text-gray-500 mb-1 block">リードスコア ({form.probability})</label>
                  <input type="range" min={0} max={100} value={form.probability}
                    onChange={e => setForm({ ...form, probability: parseInt(e.target.value) })}
                    className="w-full" />
                </div>
                <div>
                  <label className="text-xs text-gray-500 mb-1 block">メモ</label>
                  <textarea value={form.notes} onChange={e => setForm({ ...form, notes: e.target.value })}
                    rows={3} className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500 resize-none" />
                </div>
                <div className="flex gap-2">
                  <button type="submit" className="btn-primary">保存</button>
                  <button type="button" onClick={() => setEditing(false)} className="btn-secondary">キャンセル</button>
                </div>
              </form>
            </div>
          )}

          {/* Stage progress */}
          <div className="card">
            <h3 className="font-semibold mb-4 text-sm text-gray-700">リードステージ</h3>
            <div className="flex items-center gap-1">
              {STAGES.slice(0, -1).map((s, i) => {
                const currentIdx = STAGES.indexOf(lead.stage)
                const isActive = i === currentIdx
                const isDone = i < currentIdx && lead.stage !== 'closed_lost'
                return (
                  <div key={s} className="flex items-center flex-1">
                    <div className={`flex-1 text-center py-1.5 px-2 rounded text-xs font-medium transition-colors ${
                      isActive ? 'bg-brand-600 text-white' :
                      isDone ? 'bg-brand-100 text-brand-700' :
                      'bg-gray-100 text-gray-400'
                    }`}>
                      {STAGE_LABELS[s]}
                    </div>
                    {i < STAGES.length - 2 && <ChevronRight size={12} className="text-gray-300 flex-shrink-0" />}
                  </div>
                )
              })}
            </div>
          </div>

          {/* AI Company Intelligence */}
          <div className="card">
            <h3 className="font-semibold mb-4 text-sm text-gray-700 flex items-center gap-1.5">
              <Brain size={14} className="text-purple-500" /> AI企業インテリジェンス
            </h3>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-xs text-gray-400 mb-1">業界</p>
                <p className="text-sm text-gray-700">{MOCK_INTEL.industry}</p>
              </div>
              <div>
                <p className="text-xs text-gray-400 mb-1">従業員規模</p>
                <p className="text-sm text-gray-700">{MOCK_INTEL.size}</p>
              </div>
              <div>
                <p className="text-xs text-gray-400 mb-1">想定売上</p>
                <p className="text-sm text-gray-700">{MOCK_INTEL.revenue}</p>
              </div>
              <div>
                <p className="text-xs text-gray-400 mb-1">テックスタック</p>
                <div className="flex flex-wrap gap-1">
                  {MOCK_INTEL.techStack.map(t => (
                    <span key={t} className="badge bg-gray-100 text-gray-600">{t}</span>
                  ))}
                </div>
              </div>
            </div>
          </div>

          {/* Buying signals */}
          <div className="card">
            <h3 className="font-semibold mb-4 text-sm text-gray-700 flex items-center gap-1.5">
              <Target size={14} className="text-red-500" /> 購買シグナル
            </h3>
            <ul className="space-y-2">
              {MOCK_INTEL.buyingSignals.map((signal, i) => (
                <li key={i} className="flex items-center gap-2 text-sm">
                  <span className="w-2 h-2 rounded-full bg-red-400 flex-shrink-0" />
                  <span className="text-gray-700">{signal}</span>
                </li>
              ))}
            </ul>
          </div>

          {/* Related conversations */}
          <div className="card">
            <h3 className="font-semibold mb-4 text-sm text-gray-700 flex items-center gap-1.5">
              <MessageSquare size={14} /> 関連AI会話 ({lead.calls?.length || 0}件)
            </h3>
            {lead.calls?.length > 0 ? (
              <div className="space-y-2">
                {lead.calls.map(conv => {
                  const score = sentimentToScore(conv.sentiment)
                  return (
                    <Link key={conv.id} to={`/conversations/${conv.id}`}
                      className="flex items-center justify-between p-3 rounded-lg hover:bg-gray-50 transition-colors group">
                      <div>
                        <p className="text-sm font-medium text-gray-900 group-hover:text-brand-600">{conv.title}</p>
                        <p className="text-xs text-gray-400 mt-0.5">
                          {conv.date ? format(parseISO(conv.date), 'M月d日 HH:mm', { locale: ja }) : '-'} · {fmt(conv.duration_seconds)}
                        </p>
                      </div>
                      <span className="text-sm font-bold text-gray-600">{score}点</span>
                    </Link>
                  )
                })}
              </div>
            ) : (
              <p className="text-gray-400 text-sm">関連するAI会話がありません</p>
            )}
          </div>

          {/* Pain points */}
          <div className="card">
            <h3 className="font-semibold mb-3 text-sm text-gray-700">課題・ペインポイント</h3>
            <ul className="space-y-2">
              {MOCK_INTEL.painPoints.map((pain, i) => (
                <li key={i} className="flex items-start gap-2 text-sm">
                  <ChevronRight size={14} className="text-amber-500 mt-0.5 flex-shrink-0" />
                  <span className="text-gray-700">{pain}</span>
                </li>
              ))}
            </ul>
          </div>

          {/* Notes */}
          {lead.notes && (
            <div className="card">
              <h3 className="font-semibold mb-2 text-sm text-gray-700">メモ</h3>
              <p className="text-sm text-gray-600 leading-relaxed">{lead.notes}</p>
            </div>
          )}
        </div>

        {/* Right sidebar */}
        <div className="space-y-4">
          <div className="card">
            <h3 className="font-semibold mb-3 text-sm text-gray-700">リード情報</h3>
            <dl className="space-y-3">
              <div>
                <dt className="text-xs text-gray-400">想定契約額</dt>
                <dd className="text-lg font-bold text-gray-900">{fmtMoney(lead.amount)}</dd>
              </div>
              <div>
                <dt className="text-xs text-gray-400">リードスコア</dt>
                <dd className="flex items-center gap-2">
                  <div className="flex-1 h-2 bg-gray-100 rounded-full overflow-hidden">
                    <div className="h-full bg-brand-500 rounded-full" style={{ width: `${lead.probability}%` }} />
                  </div>
                  <span className="text-sm font-medium">{lead.probability}</span>
                </dd>
              </div>
              <div>
                <dt className="text-xs text-gray-400">成約予定日</dt>
                <dd className="text-sm text-gray-700">
                  {lead.close_date ? format(parseISO(lead.close_date), 'yyyy年M月d日', { locale: ja }) : '-'}
                </dd>
              </div>
              <div>
                <dt className="text-xs text-gray-400">担当者</dt>
                <dd className="text-sm text-gray-700 flex items-center gap-1">
                  <User size={12} /> {lead.owner}
                </dd>
              </div>
            </dl>
          </div>

          <div className="card">
            <h3 className="font-semibold mb-3 text-sm text-gray-700">顧客担当者</h3>
            <div className="space-y-1">
              <p className="text-sm font-medium text-gray-900">{lead.contact_name || '-'}</p>
              {lead.contact_email && (
                <a href={`mailto:${lead.contact_email}`} className="text-xs text-brand-600 hover:underline flex items-center gap-1">
                  <Mail size={11} /> {lead.contact_email}
                </a>
              )}
            </div>
          </div>

          {lead.competitors?.length > 0 && (
            <div className="card">
              <h3 className="font-semibold mb-3 text-sm text-gray-700">比較競合</h3>
              <div className="flex flex-wrap gap-1.5">
                {lead.competitors.map(c => (
                  <span key={c} className="badge bg-red-50 text-red-700">{c}</span>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
