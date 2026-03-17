import { useEffect, useState, useCallback } from 'react'
import { Bot, Play, CheckCircle, XCircle, AlertTriangle, Clock, Loader, RefreshCw } from 'lucide-react'
import { useApi, api } from '../hooks/useApi'

const AGENT_API_KEY = import.meta.env.VITE_AGENT_API_KEY || ''

const agentFetch = (path, options = {}) =>
  fetch(path, {
    headers: { 'X-Agent-Api-Key': AGENT_API_KEY, 'Content-Type': 'application/json', ...options.headers },
    ...options,
  }).then(r => r.ok ? r.json() : Promise.reject(new Error(`API ${r.status}`)))

const STATUS_CONFIG = {
  analyzing:        { label: '分析中',   color: 'text-blue-600',   bg: 'bg-blue-100'   },
  executing:        { label: '実行中',   color: 'text-brand-600',  bg: 'bg-brand-100'  },
  waiting_approval: { label: '承認待ち', color: 'text-amber-600',  bg: 'bg-amber-100'  },
  reporting:        { label: '報告中',   color: 'text-purple-600', bg: 'bg-purple-100' },
  completed:        { label: '完了',     color: 'text-green-600',  bg: 'bg-green-100'  },
  failed:           { label: 'エラー',   color: 'text-red-600',    bg: 'bg-red-100'    },
}

function StatusBadge({ status }) {
  const cfg = STATUS_CONFIG[status] || { label: status, color: 'text-gray-600', bg: 'bg-gray-100' }
  const isSpinning = ['analyzing', 'executing', 'reporting'].includes(status)
  return (
    <span className={`inline-flex items-center gap-1.5 text-xs font-medium px-2.5 py-1 rounded-full ${cfg.bg} ${cfg.color}`}>
      {isSpinning ? <Loader size={11} className="animate-spin" /> : <Clock size={11} />}
      {cfg.label}
    </span>
  )
}

export default function AgentControl() {
  const [runs, setRuns]             = useState([])
  const [loadingRuns, setLoadingRuns] = useState(true)
  const [companies, setCompanies]   = useState([])
  const [playbooks, setPlaybooks]   = useState([])
  const [form, setForm]             = useState({ company_id: '', playbook_id: '', trigger: 'manual' })
  const [launching, setLaunching]   = useState(false)
  const [actionLoading, setActionLoading] = useState(null)
  const [error, setError]           = useState(null)

  const fetchRuns = useCallback(async () => {
    try {
      const data = await agentFetch('/api/agent/runs')
      setRuns(data)
    } catch (_) {}
    finally { setLoadingRuns(false) }
  }, [])

  useEffect(() => {
    fetchRuns()
    api.get('/api/deals').then(d => {
      const unique = {}
      d?.forEach(deal => { if (deal.company_id) unique[deal.company_id] = deal.company_name })
      setCompanies(Object.entries(unique).map(([id, name]) => ({ id, name })))
    }).catch(() => {})
    api.get('/api/playbooks?status=active').then(setPlaybooks).catch(() => {})
  }, [])

  // Poll while active runs exist
  useEffect(() => {
    const hasActive = runs.some(r => !['completed', 'failed'].includes(r.status))
    if (!hasActive) return
    const id = setInterval(fetchRuns, 5000)
    return () => clearInterval(id)
  }, [runs.map(r => r.status + r.id).join(',')])

  const handleLaunch = async (e) => {
    e.preventDefault()
    if (!form.company_id) { setError('会社を選択してください'); return }
    setLaunching(true)
    setError(null)
    try {
      const run = await agentFetch('/api/agent/run', {
        method: 'POST',
        body: JSON.stringify(form)
      })
      setRuns(prev => [run, ...prev])
    } catch (err) {
      setError('エージェントの起動に失敗しました: ' + err.message)
    } finally {
      setLaunching(false)
    }
  }

  const handleApproval = async (runId, approved, comment = '') => {
    setActionLoading(runId + (approved ? '_approve' : '_reject'))
    try {
      const endpoint = approved ? 'approve' : 'reject'
      const updated = await agentFetch(`/api/agent/runs/${runId}/${endpoint}`, {
        method: 'POST',
        body: JSON.stringify({ approved, comment })
      })
      setRuns(prev => prev.map(r => r.id === runId ? updated : r))
    } catch (err) {
      setError('承認処理に失敗しました: ' + err.message)
    } finally {
      setActionLoading(null)
    }
  }

  const pendingRuns   = runs.filter(r => r.status === 'waiting_approval')
  const activeRuns    = runs.filter(r => ['analyzing', 'executing', 'reporting'].includes(r.status))
  const terminalRuns  = runs.filter(r => ['completed', 'failed'].includes(r.status))

  return (
    <div className="p-6 space-y-6 max-w-5xl">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
            <Bot className="text-brand-500" size={26} />
            AIエージェント制御
          </h1>
          <p className="text-gray-500 text-sm mt-1">エージェントの起動・監視・承認</p>
        </div>
        <button onClick={fetchRuns} className="p-2 text-gray-400 hover:text-gray-700 rounded-lg hover:bg-gray-100">
          <RefreshCw size={16} />
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 text-sm px-4 py-3 rounded-lg flex items-start gap-2">
          <XCircle size={16} className="mt-0.5 flex-shrink-0" />
          {error}
          <button onClick={() => setError(null)} className="ml-auto text-red-400 hover:text-red-600">✕</button>
        </div>
      )}

      <div className="grid grid-cols-3 gap-6">
        {/* Launch panel */}
        <div className="col-span-1">
          <div className="card">
            <h2 className="text-sm font-semibold text-gray-700 mb-4 flex items-center gap-2">
              <Play size={14} className="text-brand-500" />
              エージェント起動
            </h2>
            <form onSubmit={handleLaunch} className="space-y-3">
              <div>
                <label className="text-xs text-gray-600 block mb-1">会社 <span className="text-red-500">*</span></label>
                <select
                  value={form.company_id}
                  onChange={e => setForm(f => ({ ...f, company_id: e.target.value }))}
                  className="w-full text-sm border border-gray-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-400"
                >
                  <option value="">選択してください</option>
                  {companies.map(c => (
                    <option key={c.id} value={c.id}>{c.name}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="text-xs text-gray-600 block mb-1">プレイブック（任意）</label>
                <select
                  value={form.playbook_id}
                  onChange={e => setForm(f => ({ ...f, playbook_id: e.target.value }))}
                  className="w-full text-sm border border-gray-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-400"
                >
                  <option value="">指定なし</option>
                  {playbooks?.map(pb => (
                    <option key={pb.id} value={pb.id}>{pb.title}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="text-xs text-gray-600 block mb-1">トリガー</label>
                <select
                  value={form.trigger}
                  onChange={e => setForm(f => ({ ...f, trigger: e.target.value }))}
                  className="w-full text-sm border border-gray-200 rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-400"
                >
                  <option value="manual">手動</option>
                  <option value="high_intent">高インテント</option>
                  <option value="scheduled">スケジュール</option>
                </select>
              </div>

              <button
                type="submit"
                disabled={launching}
                className="w-full bg-brand-600 hover:bg-brand-700 text-white text-sm font-medium py-2.5 rounded-lg flex items-center justify-center gap-2 disabled:opacity-50"
              >
                {launching ? <Loader size={14} className="animate-spin" /> : <Play size={14} />}
                {launching ? '起動中...' : 'エージェント起動'}
              </button>
            </form>
          </div>
        </div>

        {/* Runs column */}
        <div className="col-span-2 space-y-4">
          {/* Pending approvals */}
          {pendingRuns.length > 0 && (
            <div className="space-y-3">
              <h2 className="text-sm font-semibold text-amber-700 flex items-center gap-2">
                <AlertTriangle size={14} />
                承認待ち ({pendingRuns.length})
              </h2>
              {pendingRuns.map(run => (
                <div key={run.id} className="border border-amber-300 rounded-xl p-4 bg-amber-50 space-y-3">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm font-medium text-gray-900">{run.company_name || '（会社未指定）'}</p>
                      {run.playbook_title && <p className="text-xs text-gray-500">{run.playbook_title}</p>}
                    </div>
                    <StatusBadge status={run.status} />
                  </div>

                  {run.pending_approval && (
                    <div className="space-y-2">
                      <p className="text-sm text-amber-900 font-medium">
                        {run.pending_approval.action_description}
                      </p>
                      {run.pending_approval.urgency && (
                        <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${
                          run.pending_approval.urgency === 'high' ? 'bg-red-100 text-red-700' :
                          run.pending_approval.urgency === 'medium' ? 'bg-amber-100 text-amber-700' :
                          'bg-gray-100 text-gray-600'
                        }`}>
                          緊急度: {run.pending_approval.urgency}
                        </span>
                      )}
                      {run.pending_approval.proposed_message && (
                        <div className="bg-white border border-amber-200 rounded-lg p-3">
                          <p className="text-xs text-gray-500 mb-1">送信予定メッセージ:</p>
                          <p className="text-sm text-gray-800 whitespace-pre-wrap">{run.pending_approval.proposed_message}</p>
                        </div>
                      )}
                    </div>
                  )}

                  <div className="flex gap-2">
                    <button
                      onClick={() => handleApproval(run.id, true)}
                      disabled={!!actionLoading}
                      className="flex-1 bg-green-600 hover:bg-green-700 text-white text-sm font-medium py-2 rounded-lg flex items-center justify-center gap-1.5 disabled:opacity-50"
                    >
                      <CheckCircle size={14} />
                      承認する
                    </button>
                    <button
                      onClick={() => handleApproval(run.id, false)}
                      disabled={!!actionLoading}
                      className="flex-1 bg-gray-200 hover:bg-gray-300 text-gray-700 text-sm font-medium py-2 rounded-lg flex items-center justify-center gap-1.5 disabled:opacity-50"
                    >
                      <XCircle size={14} />
                      却下する
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* Active runs */}
          {activeRuns.length > 0 && (
            <div className="space-y-2">
              <h2 className="text-sm font-semibold text-gray-700">実行中 ({activeRuns.length})</h2>
              {activeRuns.map(run => (
                <RunRow key={run.id} run={run} />
              ))}
            </div>
          )}

          {/* History */}
          {terminalRuns.length > 0 && (
            <div className="space-y-2">
              <h2 className="text-sm font-semibold text-gray-700 mt-4">実行履歴</h2>
              {terminalRuns.map(run => (
                <RunRow key={run.id} run={run} />
              ))}
            </div>
          )}

          {!loadingRuns && runs.length === 0 && (
            <div className="card text-center py-10 text-gray-400">
              <Bot size={32} className="mx-auto mb-2 text-gray-300" />
              <p className="text-sm">エージェントの実行履歴がありません</p>
              <p className="text-xs mt-1">左のパネルからエージェントを起動してください</p>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

function RunRow({ run }) {
  return (
    <div className="card flex items-center justify-between gap-3 py-3">
      <div className="flex-1 min-w-0">
        <p className="text-sm font-medium text-gray-800 truncate">{run.company_name || '（会社未指定）'}</p>
        <div className="flex items-center gap-2 mt-0.5">
          {run.playbook_title && <span className="text-xs text-gray-500 truncate">{run.playbook_title}</span>}
          <span className="text-xs text-gray-400">{run.tool_calls_count} ツール呼び出し</span>
        </div>
        {run.error_message && <p className="text-xs text-red-600 mt-0.5 truncate">{run.error_message}</p>}
      </div>
      <div className="flex items-center gap-3 flex-shrink-0">
        <StatusBadge status={run.status} />
        <span className="text-xs text-gray-400">
          {new Date(run.created_at).toLocaleString('ja-JP', { month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' })}
        </span>
      </div>
    </div>
  )
}
