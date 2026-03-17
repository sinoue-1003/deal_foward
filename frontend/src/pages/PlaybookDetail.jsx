import { useParams } from 'react-router-dom'
import { useState } from 'react'
import { Bot, Play, Info, Clock, Pause, RotateCcw, User } from 'lucide-react'
import { useApi } from '../hooks/useApi'
import { api } from '../hooks/useApi'
import LoadingSpinner from '../components/LoadingSpinner'
import PlaybookStepItem from '../components/PlaybookStepItem'

const STATUS_CONFIG = {
  active:    { label: 'アクティブ', cls: 'bg-green-100 text-green-700' },
  paused:    { label: '一時停止',   cls: 'bg-amber-100 text-amber-700' },
  completed: { label: '完了',       cls: 'bg-gray-100 text-gray-600' },
}

export default function PlaybookDetail() {
  const { id } = useParams()
  const { data: pb, loading, refetch } = useApi(`/api/playbooks/${id}`)
  const [executing, setExecuting] = useState(false)
  const [toggling, setToggling] = useState(false)

  if (loading) return <LoadingSpinner />
  if (!pb) return <div className="p-6 text-gray-500">プレイブックが見つかりません</div>

  const st = STATUS_CONFIG[pb.status] || STATUS_CONFIG.active
  const total = (pb.steps || []).length
  const done = (pb.steps || []).filter((s) => s.status === 'completed').length
  const pct = total > 0 ? Math.round((done / total) * 100) : 0
  const summary = pb.status_summary || {}

  async function executeNextStep() {
    setExecuting(true)
    try {
      await api.post(`/api/playbooks/${id}/execute`, {})
      refetch()
    } finally {
      setExecuting(false)
    }
  }

  async function skipStep(stepIndex) {
    setExecuting(true)
    try {
      await api.post(`/api/playbooks/${id}/execute`, { step_index: stepIndex, skip: true })
      refetch()
    } finally {
      setExecuting(false)
    }
  }

  async function togglePause() {
    setToggling(true)
    try {
      const newStatus = pb.status === 'active' ? 'paused' : 'active'
      await api.patch(`/api/playbooks/${id}`, { status: newStatus })
      refetch()
    } finally {
      setToggling(false)
    }
  }

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <div className="flex items-center gap-2 flex-wrap">
            <h1 className="text-2xl font-bold text-gray-900">{pb.title}</h1>
            <span className={`text-sm px-2 py-0.5 rounded ${st.cls}`}>{st.label}</span>
            {pb.created_by === 'ai_agent' && (
              <span className="text-sm bg-purple-50 text-purple-600 px-2 py-0.5 rounded flex items-center gap-1">
                <Bot size={12} /> AIエージェント生成
              </span>
            )}
          </div>
          {pb.company?.name && <p className="text-gray-500 text-sm mt-1">{pb.company.name}</p>}
        </div>
        <div className="flex items-center gap-2">
          {pb.status === 'active' && summary.next_action && (
            <button
              onClick={executeNextStep}
              disabled={executing || toggling}
              className="flex items-center gap-2 px-4 py-2 bg-brand-600 text-white text-sm font-medium rounded-lg hover:bg-brand-700 disabled:opacity-50"
            >
              <Play size={14} />
              {executing ? '実行中...' : '次のステップを実行'}
            </button>
          )}
          {pb.status === 'active' && (
            <button
              onClick={togglePause}
              disabled={toggling || executing}
              className="flex items-center gap-2 px-4 py-2 bg-amber-100 text-amber-700 text-sm font-medium rounded-lg hover:bg-amber-200 disabled:opacity-50"
            >
              <Pause size={14} />
              {toggling ? '処理中...' : '一時停止'}
            </button>
          )}
          {pb.status === 'paused' && (
            <button
              onClick={togglePause}
              disabled={toggling}
              className="flex items-center gap-2 px-4 py-2 bg-green-100 text-green-700 text-sm font-medium rounded-lg hover:bg-green-200 disabled:opacity-50"
            >
              <RotateCcw size={14} />
              {toggling ? '処理中...' : '再開'}
            </button>
          )}
        </div>
      </div>

      <div className="grid grid-cols-3 gap-6">
        {/* Main: Steps + Situation */}
        <div className="col-span-2 space-y-4">
          {/* Shared AI+Human Status Panel */}
          <div className="card border-l-4 border-l-brand-500">
            <h2 className="text-sm font-semibold text-gray-700 mb-2 flex items-center gap-2">
              <Info size={14} className="text-brand-500" />
              現在の状況 (AIと人間の共有コンテキスト)
            </h2>
            <p className="text-sm text-gray-700">{pb.situation_summary || pb.objective || '状況情報なし'}</p>
            <div className="mt-3 flex items-center gap-4 text-xs text-gray-500">
              <span>進捗: {summary.progress || `${done}/${total}ステップ完了`}</span>
              {summary.next_action && (
                <span className="text-brand-600">
                  次: {summary.next_action.description || summary.next_action.action_type}
                </span>
              )}
            </div>
          </div>

          {/* Progress bar */}
          <div className="card">
            <div className="flex justify-between text-xs text-gray-500 mb-2">
              <span>全体進捗</span>
              <span>{done}/{total} ({pct}%)</span>
            </div>
            <div className="w-full bg-gray-100 rounded-full h-3">
              <div className="bg-brand-500 h-3 rounded-full transition-all" style={{ width: `${pct}%` }} />
            </div>
          </div>

          {/* Steps */}
          <div className="space-y-2">
            <h2 className="text-sm font-semibold text-gray-700">実行ステップ</h2>
            {(pb.steps || []).map((step, i) => (
              <PlaybookStepItem
                key={i}
                step={step}
                index={i}
                isCurrent={i === pb.current_step && pb.status === 'active'}
                canSkip={pb.status === 'active' && !executing}
                onSkip={() => skipStep(i)}
                playbookCreatedAt={pb.created_at}
              />
            ))}
          </div>
        </div>

        {/* Sidebar */}
        <div className="space-y-4">
          <div className="card">
            <h2 className="text-sm font-semibold text-gray-700 mb-3">目標</h2>
            <p className="text-sm text-gray-700">{pb.objective || '目標未設定'}</p>
          </div>

          {pb.contact && (
            <div className="card">
              <h2 className="text-sm font-semibold text-gray-700 mb-2">担当者</h2>
              <p className="text-sm text-gray-800">{pb.contact.name}</p>
              {pb.contact.role && <p className="text-xs text-gray-500">{pb.contact.role}</p>}
            </div>
          )}

          <div className="card">
            <h2 className="text-sm font-semibold text-gray-700 mb-3 flex items-center gap-2">
              <Clock size={14} /> 実行ログ
            </h2>
            {pb.executions?.length ? (
              <div className="space-y-2 max-h-64 overflow-y-auto">
                {pb.executions.map((ex) => {
                  const isAI = ex.executed_by === 'ai_agent'
                  return (
                    <div
                      key={ex.id}
                      className={`text-xs text-gray-600 border-l-2 pl-2 ${isAI ? 'border-purple-300' : 'border-gray-200'}`}
                    >
                      <p className="font-medium flex items-center gap-1">
                        {isAI
                          ? <Bot size={10} className="text-purple-500" />
                          : <User size={10} className="text-gray-400" />
                        }
                        Step {ex.step_index + 1}: {ex.status}
                      </p>
                      {ex.result && <p className="text-gray-500 mt-0.5">{ex.result}</p>}
                      <p className="text-gray-400 mt-0.5">
                        {isAI ? 'AIエージェント' : '人間'} · {ex.executed_at ? new Date(ex.executed_at).toLocaleString('ja-JP') : ''}
                      </p>
                    </div>
                  )
                })}
              </div>
            ) : (
              <p className="text-xs text-gray-400">実行ログなし</p>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
