import { useState } from 'react'
import { Link } from 'react-router-dom'
import { Plus, Search } from 'lucide-react'
import { useApi, api } from '../hooks/useApi'
import LoadingSpinner from '../components/LoadingSpinner'

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

function probabilityToScore(probability) {
  if (probability >= 80) return { label: 'ホット', className: 'bg-red-100 text-red-700' }
  if (probability >= 60) return { label: 'ウォーム', className: 'bg-amber-100 text-amber-700' }
  if (probability >= 40) return { label: 'クール', className: 'bg-blue-100 text-blue-700' }
  return { label: 'コールド', className: 'bg-gray-100 text-gray-600' }
}

export default function Leads() {
  const { data: leads, loading, refetch } = useApi('/leads/')
  const [search, setSearch] = useState('')
  const [stageFilter, setStageFilter] = useState('')
  const [showForm, setShowForm] = useState(false)
  const [form, setForm] = useState({
    name: '', company: '', stage: 'prospect', amount: '', probability: 10, owner: '', contact_name: '', contact_email: '',
  })

  const filtered = (leads || []).filter(d => {
    const q = search.toLowerCase()
    const matchSearch = d.name.toLowerCase().includes(q) || d.company.toLowerCase().includes(q) || d.owner.toLowerCase().includes(q)
    const matchStage = !stageFilter || d.stage === stageFilter
    return matchSearch && matchStage
  })

  async function handleCreate(e) {
    e.preventDefault()
    await api.post('/leads/', { ...form, amount: parseFloat(form.amount) || 0 })
    setShowForm(false)
    refetch()
  }

  if (loading) return <LoadingSpinner />

  return (
    <div className="p-8 max-w-7xl mx-auto">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">リード</h1>
          <p className="text-gray-500 text-sm mt-1">{leads?.length || 0}件のリード</p>
        </div>
        <button onClick={() => setShowForm(true)} className="btn-primary flex items-center gap-2">
          <Plus size={16} /> 新規リード
        </button>
      </div>

      {/* Filters */}
      <div className="flex gap-3 mb-6">
        <div className="relative flex-1 max-w-sm">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          <input value={search} onChange={e => setSearch(e.target.value)}
            placeholder="リードを検索..." className="w-full pl-10 pr-4 py-2.5 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500" />
        </div>
        <select value={stageFilter} onChange={e => setStageFilter(e.target.value)}
          className="border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500 bg-white">
          <option value="">全ステージ</option>
          {STAGES.map(s => <option key={s} value={s}>{STAGE_LABELS[s]}</option>)}
        </select>
      </div>

      {/* New lead form */}
      {showForm && (
        <div className="card mb-6 border-brand-200">
          <h3 className="font-semibold mb-4">新規リードの登録</h3>
          <form onSubmit={handleCreate} className="space-y-3">
            <div className="grid grid-cols-2 gap-3">
              <input required value={form.name} onChange={e => setForm({ ...form, name: e.target.value })}
                placeholder="リード名" className="border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500" />
              <input required value={form.company} onChange={e => setForm({ ...form, company: e.target.value })}
                placeholder="企業名" className="border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500" />
            </div>
            <div className="grid grid-cols-3 gap-3">
              <select value={form.stage} onChange={e => setForm({ ...form, stage: e.target.value })}
                className="border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500 bg-white">
                {STAGES.map(s => <option key={s} value={s}>{STAGE_LABELS[s]}</option>)}
              </select>
              <input type="number" value={form.amount} onChange={e => setForm({ ...form, amount: e.target.value })}
                placeholder="想定契約額 (円)" className="border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500" />
              <input required value={form.owner} onChange={e => setForm({ ...form, owner: e.target.value })}
                placeholder="担当者" className="border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500" />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <input value={form.contact_name} onChange={e => setForm({ ...form, contact_name: e.target.value })}
                placeholder="担当者名 (顧客)" className="border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500" />
              <input type="email" value={form.contact_email} onChange={e => setForm({ ...form, contact_email: e.target.value })}
                placeholder="メールアドレス" className="border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500" />
            </div>
            <div className="flex gap-2">
              <button type="submit" className="btn-primary">保存</button>
              <button type="button" onClick={() => setShowForm(false)} className="btn-secondary">キャンセル</button>
            </div>
          </form>
        </div>
      )}

      {/* Lead table */}
      <div className="card p-0 overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50 border-b border-gray-100">
            <tr>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">リード</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">ステージ</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">スコア</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">想定契約額</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">担当者</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-50">
            {filtered.map(lead => {
              const scoreCfg = probabilityToScore(lead.probability)
              const stageColor = STAGE_COLORS[lead.stage] || 'bg-gray-100 text-gray-600'
              return (
                <tr key={lead.id} className="hover:bg-gray-50 transition-colors">
                  <td className="px-6 py-4">
                    <Link to={`/leads/${lead.id}`} className="font-medium text-sm text-gray-900 hover:text-brand-600">
                      {lead.name}
                    </Link>
                    <p className="text-xs text-gray-400 mt-0.5">{lead.company}</p>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`badge ${stageColor}`}>{STAGE_LABELS[lead.stage] || lead.stage}</span>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2">
                      <span className="text-sm font-bold text-gray-900">{lead.probability}</span>
                      <span className={`badge ${scoreCfg.className}`}>{scoreCfg.label}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4 text-sm font-semibold text-gray-900">
                    {new Intl.NumberFormat('ja-JP', { style: 'currency', currency: 'JPY', maximumFractionDigits: 0 }).format(lead.amount)}
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-500">{lead.owner}</td>
                </tr>
              )
            })}
            {filtered.length === 0 && (
              <tr><td colSpan={5} className="px-6 py-12 text-center text-gray-400 text-sm">リードが見つかりません</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}
