const config = {
  positive: { label: 'ポジティブ', className: 'bg-green-100 text-green-700' },
  neutral: { label: 'ニュートラル', className: 'bg-gray-100 text-gray-600' },
  negative: { label: 'ネガティブ', className: 'bg-red-100 text-red-700' },
}

export default function SentimentBadge({ sentiment }) {
  const { label, className } = config[sentiment] || config.neutral
  return <span className={`badge ${className}`}>{label}</span>
}
