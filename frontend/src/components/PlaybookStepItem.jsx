import { CheckCircle, Circle, Loader, XCircle, SkipForward, Bot, User, MessageCircle } from 'lucide-react'
import ChannelBadge from './ChannelBadge'

const STATUS_ICON = {
  completed:   <CheckCircle  className="text-green-500 w-5 h-5" />,
  in_progress: <Loader       className="text-blue-500 w-5 h-5 animate-spin" />,
  failed:      <XCircle      className="text-red-500 w-5 h-5" />,
  skipped:     <SkipForward  className="text-gray-400 w-5 h-5" />,
  pending:     <Circle       className="text-gray-300 w-5 h-5" />,
}

const EXECUTOR_CONFIG = {
  ai:       { label: 'AI実行',     cls: 'bg-purple-50 text-purple-600',  icon: <Bot size={10} /> },
  human:    { label: '担当者',     cls: 'bg-gray-100 text-gray-600',     icon: <User size={10} /> },
  customer: { label: '顧客対応待ち', cls: 'bg-blue-50 text-blue-600',   icon: <MessageCircle size={10} /> },
}

const ACTION_LABELS = {
  send_slack_message:  'Slackメッセージ送信',
  schedule_meeting:    'ミーティング設定',
  send_email:          'メール送信',
  update_crm:          'CRM更新',
  create_followup_task:'フォローアップタスク作成',
  send_proposal:       '提案書送付',
  request_demo:        'デモ依頼',
  share_case_study:    '事例共有',
  follow_up_call:      'フォローコール',
}

function formatDeadline(playbookCreatedAt, dueInHours) {
  if (!playbookCreatedAt || !dueInHours) return null
  const deadline = new Date(new Date(playbookCreatedAt).getTime() + dueInHours * 3600000)
  const now = new Date()
  const diffMs = deadline - now
  const isPast = diffMs < 0
  const isUrgent = !isPast && diffMs < 24 * 3600000

  const formatted = deadline.toLocaleString('ja-JP', {
    month: 'numeric', day: 'numeric', hour: '2-digit', minute: '2-digit'
  })

  return { formatted, isPast, isUrgent }
}

export default function PlaybookStepItem({ step, index, isCurrent, canSkip, onSkip, playbookCreatedAt }) {
  const icon = STATUS_ICON[step.status] || STATUS_ICON.pending
  const deadline = step.status === 'pending' ? formatDeadline(playbookCreatedAt, step.due_in_hours) : null
  const executor = EXECUTOR_CONFIG[step.executor_type]

  return (
    <div className={`flex gap-4 p-4 rounded-lg border transition-colors ${
      isCurrent ? 'border-brand-400 bg-brand-50' : 'border-gray-100 bg-white'
    }`}>
      <div className="flex-shrink-0 mt-0.5">{icon}</div>
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2 flex-wrap">
          <span className="text-xs text-gray-400 font-mono">Step {step.step || index + 1}</span>
          <span className="text-sm font-medium text-gray-800">
            {ACTION_LABELS[step.action_type] || step.action_type}
          </span>
          {executor && (
            <span className={`text-xs px-2 py-0.5 rounded-full flex items-center gap-1 ${executor.cls}`}>
              {executor.icon} {executor.label}
            </span>
          )}
          {step.channel && <ChannelBadge channel={step.channel} />}
          {isCurrent && (
            <span className="text-xs bg-brand-100 text-brand-700 px-2 py-0.5 rounded-full font-medium">
              現在のステップ
            </span>
          )}
          {canSkip && step.status === 'pending' && step.executor_type !== 'customer' && (
            <button
              onClick={onSkip}
              className="ml-auto text-xs text-gray-400 hover:text-amber-600 flex items-center gap-1 px-2 py-0.5 rounded hover:bg-amber-50 transition-colors"
            >
              <SkipForward size={12} /> スキップ
            </button>
          )}
        </div>
        {step.target && (
          <p className="text-xs text-gray-500 mt-1">対象: {step.target}</p>
        )}
        {step.template && (
          <p className="text-sm text-gray-600 mt-1">{step.template}</p>
        )}
        {step.result && (
          <p className="text-xs text-green-600 mt-1 bg-green-50 px-2 py-1 rounded">結果: {step.result}</p>
        )}
        {deadline && (
          <p className={`text-xs mt-1 ${
            deadline.isPast ? 'text-red-500' : deadline.isUrgent ? 'text-amber-500' : 'text-gray-400'
          }`}>
            期限: {deadline.formatted}{deadline.isPast ? ' (期限超過)' : ''}
          </p>
        )}
      </div>
    </div>
  )
}
