import { useEffect, useState, useCallback } from 'react'
import { Link } from 'react-router-dom'
import { Bot, CheckCircle, Clock, AlertTriangle, XCircle, Loader, ChevronRight } from 'lucide-react'
import { api } from '../hooks/useApi'

const AGENT_API_KEY = import.meta.env.VITE_AGENT_API_KEY || ''

const STATUS_CONFIG = {
  analyzing:        { label: '分析中',     color: 'text-blue-600',   bg: 'bg-blue-50',   icon: Loader,        spin: true  },
  executing:        { label: '実行中',     color: 'text-brand-600',  bg: 'bg-brand-50',  icon: Loader,        spin: true  },
  waiting_approval: { label: '承認待ち',   color: 'text-amber-600',  bg: 'bg-amber-50',  icon: AlertTriangle, spin: false },
  reporting:        { label: '報告中',     color: 'text-purple-600', bg: 'bg-purple-50', icon: Loader,        spin: true  },
  completed:        { label: '完了',       color: 'text-green-600',  bg: 'bg-green-50',  icon: CheckCircle,   spin: false },
  failed:           { label: 'エラー',     color: 'text-red-600',    bg: 'bg-red-50',    icon: XCircle,       spin: false },
}

function StatusBadge({ status }) {
  const cfg = STATUS_CONFIG[status] || { label: status, color: 'text-gray-600', bg: 'bg-gray-100', icon: Clock, spin: false }
  const Icon = cfg.icon
  return (
    <span className={`inline-flex items-center gap-1 text-xs font-medium px-2 py-0.5 rounded-full ${cfg.bg} ${cfg.color}`}>
      <Icon size={11} className={cfg.spin ? 'animate-spin' : ''} />
      {cfg.label}
    </span>
  )
}

export default function AgentRunPanel() {
  const [runs, setRuns]         = useState([])
  const [loading, setLoading]   = useState(true)
  const [actionLoading, setActionLoading] = useState(null)

  const fetchRuns = useCallback(async () => {
    try {
      const data = await fetch('/api/agent/runs', {
        headers: { 'X-Agent-Api-Key': AGENT_API_KEY, 'Content-Type': 'application/json' }
      }).then(r => r.ok ? r.json() : [])
      setRuns(data.slice(0, 10))
    } catch (_) {
      // silently fail — panel is optional
    } finally {
      setLoading(false)
    }
  }, [])

  // Poll every 5s while any run is active
  useEffect(() => {
    fetchRuns()
    const hasActive = runs.some(r => !['completed', 'failed'].includes(r.status))
    if (!hasActive && runs.length > 0) return
    const id = setInterval(fetchRuns, 5000)
    return () => clearInterval(id)
  }, [fetchRuns, runs.map(r => r.status).join(',')])

  const handleApproval = async (runId, approved) => {
    setActionLoading(runId)
    try {
      await fetch(`/api/agent/runs/${runId}/${approved ? 'approve' : 'reject'}`, {
        method:  'POST',
        headers: { 'X-Agent-Api-Key': AGENT_API_KEY, 'Content-Type': 'application/json' },
        body:    JSON.stringify({ approved })
      })
      await fetchRuns()
    } catch (_) {}
    finally { setActionLoading(null) }
  }

  const pendingApproval = runs.find(r => r.status === 'waiting_approval')
  const activeRuns      = runs.filter(r => !['completed', 'failed'].includes(r.status))

  if (loading) return null

  return (
    <div className="card space-y-3">
      <div className="flex items-center justify-between">
        <h2 className="text-sm font-semibold text-gray-700 flex items-center gap-2">
          <Bot size={16} className="text-brand-500" />
          AIエージェント
        </h2>
        <Link to="/agent" className="text-xs text-brand-600 hover:underline flex items-center gap-0.5">
          詳細 <ChevronRight size={12} />
        </Link>
      </div>

      {/* Pending approval callout */}
      {pendingApproval && (
        <div className="border border-amber-200 rounded-lg p-3 bg-amber-50 space-y-2">
          <div className="flex items-start gap-2">
            <AlertTriangle size={14} className="text-amber-500 mt-0.5 flex-shrink-0" />
            <div className="flex-1 min-w-0">
              <p className="text-xs font-semibold text-amber-800">人間の承認が必要です</p>
              <p className="text-xs text-amber-700 mt-0.5 break-words">
                {pendingApproval.pending_approval?.action_description}
              </p>
              {pendingApproval.pending_approval?.proposed_message && (
                <p className="text-xs text-amber-600 mt-1 bg-amber-100 rounded p-1.5 font-mono break-words">
                  {pendingApproval.pending_approval.proposed_message}
                </p>
              )}
            </div>
          </div>
          <div className="flex gap-2">
            <button
              onClick={() => handleApproval(pendingApproval.id, true)}
              disabled={actionLoading === pendingApproval.id}
              className="flex-1 text-xs bg-green-600 hover:bg-green-700 text-white py-1.5 rounded font-medium disabled:opacity-50"
            >
              承認する
            </button>
            <button
              onClick={() => handleApproval(pendingApproval.id, false)}
              disabled={actionLoading === pendingApproval.id}
              className="flex-1 text-xs bg-gray-200 hover:bg-gray-300 text-gray-700 py-1.5 rounded font-medium disabled:opacity-50"
            >
              却下する
            </button>
          </div>
        </div>
      )}

      {/* Active runs summary */}
      {activeRuns.length > 0 && !pendingApproval && (
        <div className="flex items-center gap-2 text-xs text-gray-600">
          <Loader size={12} className="animate-spin text-brand-500" />
          {activeRuns.length}件のエージェントが実行中
        </div>
      )}

      {/* Recent runs list */}
      {runs.length === 0 ? (
        <p className="text-xs text-gray-400">エージェントの実行履歴がありません</p>
      ) : (
        <div className="space-y-1.5">
          {runs.slice(0, 4).map(run => (
            <div key={run.id} className="flex items-center justify-between gap-2">
              <div className="flex-1 min-w-0">
                <p className="text-xs text-gray-700 truncate">{run.company_name || '（会社未指定）'}</p>
                {run.playbook_title && (
                  <p className="text-xs text-gray-400 truncate">{run.playbook_title}</p>
                )}
              </div>
              <StatusBadge status={run.status} />
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
