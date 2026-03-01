import { useState } from 'react'
import { Link } from 'react-router-dom'
import { Phone, Plus, Search, Upload } from 'lucide-react'
import { useApi, api } from '../hooks/useApi'
import SentimentBadge from '../components/SentimentBadge'
import LoadingSpinner from '../components/LoadingSpinner'
import { format, parseISO } from 'date-fns'
import { ja } from 'date-fns/locale'

function fmt(seconds) {
  const m = Math.floor(seconds / 60)
  return m >= 60 ? `${Math.floor(m / 60)}時間${m % 60}分` : `${m}分`
}

export default function Calls() {
  const { data: calls, loading, refetch } = useApi('/calls/')
  const [search, setSearch] = useState('')
  const [showForm, setShowForm] = useState(false)
  const [form, setForm] = useState({ title: '', transcript: '', rep_name: '', prospect_name: '' })

  const filtered = (calls || []).filter(c =>
    c.title.toLowerCase().includes(search.toLowerCase()) ||
    c.participants?.some(p => p.name.toLowerCase().includes(search.toLowerCase()))
  )

  async function handleCreate(e) {
    e.preventDefault()
    await api.post('/calls/', {
      title: form.title,
      participants: [
        { name: form.rep_name, role: 'rep' },
        { name: form.prospect_name, role: 'prospect' },
      ],
      transcript: form.transcript || null,
    })
    setShowForm(false)
    setForm({ title: '', transcript: '', rep_name: '', prospect_name: '' })
    refetch()
  }

  if (loading) return <LoadingSpinner />

  return (
    <div className="p-8 max-w-6xl mx-auto">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">通話</h1>
          <p className="text-gray-500 text-sm mt-1">{calls?.length || 0}件の通話記録</p>
        </div>
        <button onClick={() => setShowForm(true)} className="btn-primary flex items-center gap-2">
          <Plus size={16} /> 新規通話
        </button>
      </div>

      {/* Search */}
      <div className="relative mb-6">
        <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
        <input
          value={search}
          onChange={e => setSearch(e.target.value)}
          placeholder="通話を検索..."
          className="w-full pl-10 pr-4 py-2.5 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
        />
      </div>

      {/* New call form */}
      {showForm && (
        <div className="card mb-6 border-brand-200">
          <h3 className="font-semibold mb-4">新規通話の登録</h3>
          <form onSubmit={handleCreate} className="space-y-3">
            <input required value={form.title} onChange={e => setForm({ ...form, title: e.target.value })}
              placeholder="通話タイトル" className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500" />
            <div className="grid grid-cols-2 gap-3">
              <input value={form.rep_name} onChange={e => setForm({ ...form, rep_name: e.target.value })}
                placeholder="担当者名" className="border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500" />
              <input value={form.prospect_name} onChange={e => setForm({ ...form, prospect_name: e.target.value })}
                placeholder="顧客名" className="border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500" />
            </div>
            <textarea value={form.transcript} onChange={e => setForm({ ...form, transcript: e.target.value })}
              placeholder="トランスクリプト（任意）— 貼り付けるとAIが自動分析します"
              rows={5} className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500 resize-none" />
            <div className="flex gap-2">
              <button type="submit" className="btn-primary">保存</button>
              <button type="button" onClick={() => setShowForm(false)} className="btn-secondary">キャンセル</button>
            </div>
          </form>
        </div>
      )}

      {/* Call list */}
      <div className="card p-0 overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50 border-b border-gray-100">
            <tr>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">通話</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">参加者</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">日時</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">時間</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">感情</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-50">
            {filtered.map(call => (
              <tr key={call.id} className="hover:bg-gray-50 transition-colors">
                <td className="px-6 py-4">
                  <Link to={`/calls/${call.id}`} className="font-medium text-sm text-gray-900 hover:text-brand-600">
                    {call.title}
                  </Link>
                  {call.keywords?.length > 0 && (
                    <div className="flex gap-1 mt-1 flex-wrap">
                      {call.keywords.slice(0, 3).map(k => (
                        <span key={k} className="text-xs bg-gray-100 text-gray-500 px-1.5 py-0.5 rounded">{k}</span>
                      ))}
                    </div>
                  )}
                </td>
                <td className="px-6 py-4 text-sm text-gray-500">
                  {call.participants?.map(p => p.name).join(', ')}
                </td>
                <td className="px-6 py-4 text-sm text-gray-500">
                  {call.date ? format(parseISO(call.date), 'M月d日 HH:mm', { locale: ja }) : '-'}
                </td>
                <td className="px-6 py-4 text-sm text-gray-500">{fmt(call.duration_seconds)}</td>
                <td className="px-6 py-4">
                  {call.sentiment ? <SentimentBadge sentiment={call.sentiment} /> : <span className="text-gray-300 text-sm">-</span>}
                </td>
              </tr>
            ))}
            {filtered.length === 0 && (
              <tr><td colSpan={5} className="px-6 py-12 text-center text-gray-400 text-sm">通話が見つかりません</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}
