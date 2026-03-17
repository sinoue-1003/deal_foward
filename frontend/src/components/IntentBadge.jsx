export default function IntentBadge({ score }) {
  const level = score >= 80 ? 'hot' : score >= 60 ? 'warm' : score >= 40 ? 'cool' : 'cold'
  const config = {
    hot:  { label: 'ホット',   cls: 'bg-red-100 text-red-700' },
    warm: { label: 'ウォーム', cls: 'bg-amber-100 text-amber-700' },
    cool: { label: 'クール',   cls: 'bg-blue-100 text-blue-700' },
    cold: { label: 'コールド', cls: 'bg-gray-100 text-gray-500' },
  }[level]

  return (
    <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded text-xs font-medium ${config.cls}`}>
      {config.label} {score}
    </span>
  )
}
