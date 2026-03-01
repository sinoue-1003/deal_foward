const stages = {
  prospect: { label: '見込み客', className: 'bg-gray-100 text-gray-600' },
  qualify: { label: '資格確認', className: 'bg-blue-100 text-blue-700' },
  demo: { label: 'デモ', className: 'bg-purple-100 text-purple-700' },
  proposal: { label: '提案', className: 'bg-amber-100 text-amber-700' },
  negotiation: { label: '交渉', className: 'bg-orange-100 text-orange-700' },
  closed_won: { label: '成約', className: 'bg-green-100 text-green-700' },
  closed_lost: { label: '失注', className: 'bg-red-100 text-red-700' },
}

export default function StageBadge({ stage }) {
  const { label, className } = stages[stage] || { label: stage, className: 'bg-gray-100 text-gray-600' }
  return <span className={`badge ${className}`}>{label}</span>
}
