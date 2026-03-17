import { useState } from 'react'
import { Link } from 'react-router-dom'
import { Plus, Search, ChevronRight } from 'lucide-react'
import { useApi, api } from '../hooks/useApi'
import StageBadge from '../components/StageBadge'
import LoadingSpinner from '../components/LoadingSpinner'

const STAGES = ['prospect', 'qualify', 'demo', 'proposal', 'negotiation', 'closed_won', 'closed_lost']

export default function Deals() {
  const { data: deals, loading, refetch } = useApi('/api/deals')
  const [search, setSearch] = useState('')
  const [stage, setStage] = useState('')
  const [showForm, setShowForm] = useState(false)
  const [form, setForm] = useState({ title: '', stage: 'prospect', owner: '', amount: '' })

  if (loading) return <LoadingSpinner />

  const filtered = (deals || []).filter((d) => {
    const matchSearch = !search || d.title?.toLowerCase().includes(search.toLowerCase()) ||
      d.company_name?.toLowerCase().includes(search.toLowerCase())
    const matchStage = !stage || d.stage === stage
    return matchSearch && matchStage
  })

  async function createDeal(e) {
    e.preventDefault()
    await api.post('/api/deals', form)
    setShowForm(false)
    setForm({ title: '', stage: 'prospect', owner: '', amount: '' })
    refetch()
  }

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">商談</h1>
        <button onClick={() => setShowForm(!showForm)} className="btn-primary flex items-center gap-2 text-sm">
          <Plus size={16} /> 新規商談
        </button>
      </div>

      {showForm && (
        <form onSubmit={createDeal} className="card space-y-3">
          <h2 className="text-sm font-semibold text-gray-700">新規商談を追加</h2>
          <div className="grid grid-cols-2 gap-3">
            <input className="input" placeholder="商談名" value={form.title} onChange={(e) => setForm({...form, title: e.target.value})} required />
            <input className="input" placeholder="担当者" value={form.owner} onChange={(e) => setForm({...form, owner: e.target.value})} />
            <select className="input" value={form.stage} onChange={(e) => setForm({...form, stage: e.target.value})}>
              {STAGES.map((s) => <option key={s} value={s}>{s}</option>)}
            </select>
            <input className="input" type="number" placeholder="金額 (円)" value={form.amount} onChange={(e) => setForm({...form, amount: e.target.value})} />
          </div>
          <div className="flex gap-2">
            <button type="submit" className="btn-primary text-sm">作成</button>
            <button type="button" onClick={() => setShowForm(false)} className="btn-secondary text-sm">キャンセル</button>
          </div>
        </form>
      )}

      {/* Filters */}
      <div className="flex gap-3">
        <div className="relative flex-1 max-w-xs">
          <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          <input className="input pl-9 text-sm" placeholder="検索..." value={search} onChange={(e) => setSearch(e.target.value)} />
        </div>
        <select className="input text-sm w-40" value={stage} onChange={(e) => setStage(e.target.value)}>
          <option value="">全ステージ</option>
          {STAGES.map((s) => <option key={s} value={s}>{s}</option>)}
        </select>
      </div>

      {/* Table */}
      <div className="card overflow-hidden p-0">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-gray-100 text-xs text-gray-500">
              <th className="text-left px-4 py-3">商談名</th>
              <th className="text-left px-4 py-3">ステージ</th>
              <th className="text-left px-4 py-3">金額</th>
              <th className="text-left px-4 py-3">確度</th>
              <th className="text-left px-4 py-3">担当</th>
              <th className="px-4 py-3"></th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-50">
            {filtered.length === 0 && (
              <tr><td colSpan={6} className="text-center py-8 text-gray-400">商談がありません</td></tr>
            )}
            {filtered.map((d) => (
              <tr key={d.id} className="hover:bg-gray-50 transition-colors">
                <td className="px-4 py-3">
                  <p className="font-medium text-gray-900">{d.title}</p>
                  {d.company_name && <p className="text-xs text-gray-500">{d.company_name}</p>}
                </td>
                <td className="px-4 py-3"><StageBadge stage={d.stage} /></td>
                <td className="px-4 py-3 text-gray-700">
                  {d.amount ? `¥${Number(d.amount).toLocaleString()}` : '—'}
                </td>
                <td className="px-4 py-3">
                  <div className="flex items-center gap-1">
                    <div className="w-16 bg-gray-100 rounded-full h-1.5">
                      <div className="bg-brand-500 h-1.5 rounded-full" style={{ width: `${d.probability || 0}%` }} />
                    </div>
                    <span className="text-xs text-gray-500">{d.probability || 0}%</span>
                  </div>
                </td>
                <td className="px-4 py-3 text-gray-600">{d.owner || '—'}</td>
                <td className="px-4 py-3">
                  <Link to={`/deals/${d.id}`} className="text-brand-600 hover:text-brand-700">
                    <ChevronRight size={16} />
                  </Link>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
