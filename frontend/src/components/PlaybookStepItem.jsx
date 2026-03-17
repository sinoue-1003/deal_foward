import { CheckCircle, Circle, Loader, XCircle, SkipForward } from 'lucide-react'
import ChannelBadge from './ChannelBadge'

const STATUS_ICON = {
  completed:   <CheckCircle  className="text-green-500 w-5 h-5" />,
  in_progress: <Loader       className="text-blue-500 w-5 h-5 animate-spin" />,
  failed:      <XCircle      className="text-red-500 w-5 h-5" />,
  skipped:     <SkipForward  className="text-gray-400 w-5 h-5" />,
  pending:     <Circle       className="text-gray-300 w-5 h-5" />,
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

export default function PlaybookStepItem({ step, index, isCurrent }) {
  const icon = STATUS_ICON[step.status] || STATUS_ICON.pending

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
          {step.channel && <ChannelBadge channel={step.channel} />}
          {isCurrent && (
            <span className="text-xs bg-brand-100 text-brand-700 px-2 py-0.5 rounded-full font-medium">
              現在のステップ
            </span>
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
        {step.due_in_hours && step.status === 'pending' && (
          <p className="text-xs text-gray-400 mt-1">期限: {step.due_in_hours}時間以内</p>
        )}
      </div>
    </div>
  )
}
