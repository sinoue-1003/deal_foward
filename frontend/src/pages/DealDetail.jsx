import { useParams, Link } from 'react-router-dom'
import { ArrowLeft, Phone, Mail, User, Building, ChevronRight } from 'lucide-react'
import { useApi, api } from '../hooks/useApi'
import StageBadge from '../components/StageBadge'
import SentimentBadge from '../components/SentimentBadge'
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
  prospect: '見込み客', qualify: '資格確認', demo: 'デモ', proposal: '提案',
  negotiation: '交渉', closed_won: '成約', closed_lost: '失注',
}

export default function DealDetail() {
  const { id } = useParams()
  const { data: deal, loading, refetch } = useApi(`/deals/${id}`)
  const [editing, setEditing] = useState(false)
  const [form, setForm] = useState(null)

  function startEdit() {
    setForm({ stage: deal.stage, amount: deal.amount, probability: deal.probability, notes: deal.notes || '' })
    setEditing(true)
  }

  async function saveEdit(e) {
    e.preventDefault()
    await api.patch(`/deals/${id}`, form)
    setEditing(false)
    refetch()
  }

  if (loading) return <LoadingSpinner />
  if (!deal) return <div className="p-8 text-gray-500">ディールが見つかりません</div>

  return (
    <div className="p-8 max-w-5xl mx-auto">
      <Link to="/deals" className="flex items-center gap-1 text-gray-400 hover:text-gray-700 text-sm mb-6">
        <ArrowLeft size={14} /> ディール一覧に戻る
      </Link>

      <div className="flex items-start justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">{deal.name}</h1>
          <p className="text-gray-500 text-sm mt-1 flex items-center gap-1.5">
            <Building size={13} /> {deal.company}
          </p>
        </div>
        <div className="flex items-center gap-3">
          <StageBadge stage={deal.stage} />
          <button onClick={startEdit} className="btn-secondary text-sm">編集</button>
        </div>
      </div>

      <div className="grid grid-cols-3 gap-6">
        <div className="col-span-2 space-y-5">
          {/* Edit form */}
          {editing && form && (
            <div className="card border-brand-200">
              <h3 className="font-semibold mb-4">ディール情報の編集</h3>
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
                    <label className="text-xs text-gray-500 mb-1 block">金額 (円)</label>
                    <input type="number" value={form.amount} onChange={e => setForm({ ...form, amount: parseFloat(e.target.value) })}
                      className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500" />
                  </div>
                </div>
                <div>
                  <label className="text-xs text-gray-500 mb-1 block">確度 ({form.probability}%)</label>
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
            <h3 className="font-semibold mb-4 text-sm text-gray-700">ステージ進捗</h3>
            <div className="flex items-center gap-1">
              {STAGES.slice(0, -1).map((s, i) => {
                const currentIdx = STAGES.indexOf(deal.stage)
                const isActive = i === currentIdx
                const isDone = i < currentIdx && deal.stage !== 'closed_lost'
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

          {/* Related calls */}
          <div className="card">
            <h3 className="font-semibold mb-4 text-sm text-gray-700 flex items-center gap-1.5">
              <Phone size={14} /> 関連通話 ({deal.calls?.length || 0}件)
            </h3>
            {deal.calls?.length > 0 ? (
              <div className="space-y-2">
                {deal.calls.map(call => (
                  <Link key={call.id} to={`/calls/${call.id}`}
                    className="flex items-center justify-between p-3 rounded-lg hover:bg-gray-50 transition-colors group">
                    <div>
                      <p className="text-sm font-medium text-gray-900 group-hover:text-brand-600">{call.title}</p>
                      <p className="text-xs text-gray-400 mt-0.5">
                        {call.date ? format(parseISO(call.date), 'M月d日 HH:mm', { locale: ja }) : '-'} · {fmt(call.duration_seconds)}
                      </p>
                    </div>
                    {call.sentiment && <SentimentBadge sentiment={call.sentiment} />}
                  </Link>
                ))}
              </div>
            ) : (
              <p className="text-gray-400 text-sm">関連する通話がありません</p>
            )}
          </div>

          {/* Notes */}
          {deal.notes && (
            <div className="card">
              <h3 className="font-semibold mb-2 text-sm text-gray-700">メモ</h3>
              <p className="text-sm text-gray-600 leading-relaxed">{deal.notes}</p>
            </div>
          )}
        </div>

        {/* Right sidebar */}
        <div className="space-y-4">
          <div className="card">
            <h3 className="font-semibold mb-3 text-sm text-gray-700">ディール情報</h3>
            <dl className="space-y-3">
              <div>
                <dt className="text-xs text-gray-400">金額</dt>
                <dd className="text-lg font-bold text-gray-900">{fmtMoney(deal.amount)}</dd>
              </div>
              <div>
                <dt className="text-xs text-gray-400">確度</dt>
                <dd className="flex items-center gap-2">
                  <div className="flex-1 h-2 bg-gray-100 rounded-full overflow-hidden">
                    <div className="h-full bg-brand-500 rounded-full" style={{ width: `${deal.probability}%` }} />
                  </div>
                  <span className="text-sm font-medium">{deal.probability}%</span>
                </dd>
              </div>
              <div>
                <dt className="text-xs text-gray-400">予想成約日</dt>
                <dd className="text-sm text-gray-700">
                  {deal.close_date ? format(parseISO(deal.close_date), 'yyyy年M月d日', { locale: ja }) : '-'}
                </dd>
              </div>
              <div>
                <dt className="text-xs text-gray-400">担当者</dt>
                <dd className="text-sm text-gray-700 flex items-center gap-1">
                  <User size={12} /> {deal.owner}
                </dd>
              </div>
            </dl>
          </div>

          <div className="card">
            <h3 className="font-semibold mb-3 text-sm text-gray-700">顧客担当者</h3>
            <div className="space-y-1">
              <p className="text-sm font-medium text-gray-900">{deal.contact_name || '-'}</p>
              {deal.contact_email && (
                <a href={`mailto:${deal.contact_email}`} className="text-xs text-brand-600 hover:underline flex items-center gap-1">
                  <Mail size={11} /> {deal.contact_email}
                </a>
              )}
            </div>
          </div>

          {deal.competitors?.length > 0 && (
            <div className="card">
              <h3 className="font-semibold mb-3 text-sm text-gray-700">競合他社</h3>
              <div className="flex flex-wrap gap-1.5">
                {deal.competitors.map(c => (
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
