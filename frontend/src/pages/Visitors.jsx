import { useState, useEffect } from 'react'
import { Globe, Eye, Clock, TrendingUp, MessageSquare, RefreshCw } from 'lucide-react'

const MOCK_VISITORS = [
  { id: 1, company: 'Salesforce Japan', location: '東京都', pages: 8, time: 720, score: 94, status: 'active', current_page: '料金プランページ', source: 'Google広告' },
  { id: 2, company: 'NTTデータ株式会社', location: '東京都', pages: 5, time: 480, score: 91, status: 'chatting', current_page: 'デモ申込ページ', source: '有機検索' },
  { id: 3, company: 'トヨタ自動車', location: '愛知県', pages: 6, time: 540, score: 87, status: 'active', current_page: '機能詳細ページ', source: 'LinkedIn' },
  { id: 4, company: 'ソフトバンク株式会社', location: '東京都', pages: 3, time: 180, score: 72, status: 'active', current_page: 'トップページ', source: '有機検索' },
  { id: 5, company: '株式会社リクルート', location: '東京都', pages: 4, time: 360, score: 68, status: 'active', current_page: '導入事例ページ', source: '参照リンク' },
  { id: 6, company: 'KDDI株式会社', location: '東京都', pages: 2, time: 120, score: 55, status: 'left', current_page: 'トップページ', source: 'メール' },
  { id: 7, company: 'パナソニック株式会社', location: '大阪府', pages: 7, time: 600, score: 83, status: 'qualified', current_page: '統合ページ', source: 'Google広告' },
  { id: 8, company: '富士通株式会社', location: '東京都', pages: 3, time: 240, score: 61, status: 'active', current_page: 'ブログ記事', source: '有機検索' },
  { id: 9, company: '株式会社NEC', location: '東京都', pages: 5, time: 420, score: 79, status: 'chatting', current_page: 'セキュリティページ', source: 'LinkedIn' },
  { id: 10, company: 'キヤノン株式会社', location: '東京都', pages: 2, time: 90, score: 42, status: 'left', current_page: '採用ページ', source: '有機検索' },
  { id: 11, company: '本田技研工業', location: '埼玉県', pages: 4, time: 300, score: 74, status: 'active', current_page: '機能詳細ページ', source: 'Twitter' },
  { id: 12, company: '三菱電機株式会社', location: '東京都', pages: 6, time: 500, score: 88, status: 'active', current_page: '料金プランページ', source: 'Google広告' },
]

const STATUS_CONFIG = {
  active: { label: 'アクティブ', className: 'bg-green-100 text-green-700' },
  chatting: { label: 'AI会話中', className: 'bg-brand-100 text-brand-700' },
  qualified: { label: 'リード化済', className: 'bg-purple-100 text-purple-700' },
  left: { label: '離脱', className: 'bg-gray-100 text-gray-500' },
}

function ScoreBar({ score }) {
  const color = score >= 80 ? 'bg-red-500' : score >= 60 ? 'bg-amber-400' : score >= 40 ? 'bg-blue-400' : 'bg-gray-300'
  const label = score >= 80 ? 'ホット' : score >= 60 ? 'ウォーム' : score >= 40 ? 'クール' : 'コールド'
  const textColor = score >= 80 ? 'text-red-700' : score >= 60 ? 'text-amber-700' : score >= 40 ? 'text-blue-700' : 'text-gray-500'
  return (
    <div className="flex items-center gap-2">
      <div className="w-20 h-2 bg-gray-100 rounded-full overflow-hidden">
        <div className={`h-full ${color} rounded-full`} style={{ width: `${score}%` }} />
      </div>
      <span className={`text-xs font-medium ${textColor}`}>{score}</span>
    </div>
  )
}

function fmtTime(seconds) {
  const m = Math.floor(seconds / 60)
  return m >= 60 ? `${Math.floor(m / 60)}時間${m % 60}分` : `${m}分`
}

export default function Visitors() {
  const [filter, setFilter] = useState('all')
  const [lastUpdated, setLastUpdated] = useState(new Date())
  const [blinking, setBlinking] = useState(false)

  useEffect(() => {
    const timer = setInterval(() => {
      setLastUpdated(new Date())
      setBlinking(true)
      setTimeout(() => setBlinking(false), 500)
    }, 30000)
    return () => clearInterval(timer)
  }, [])

  const filtered = filter === 'all' ? MOCK_VISITORS : MOCK_VISITORS.filter(v => v.status === filter)
  const activeCount = MOCK_VISITORS.filter(v => v.status === 'active' || v.status === 'chatting').length
  const highIntentCount = MOCK_VISITORS.filter(v => v.score >= 80).length
  const chattingCount = MOCK_VISITORS.filter(v => v.status === 'chatting').length

  return (
    <div className="p-8 max-w-7xl mx-auto">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">リアルタイム訪問者</h1>
          <p className="text-gray-500 text-sm mt-1">現在サイトを閲覧している企業</p>
        </div>
        <div className="flex items-center gap-2 text-sm text-gray-400">
          <RefreshCw size={14} className={blinking ? 'text-green-500' : ''} />
          更新: {lastUpdated.toLocaleTimeString('ja-JP', { hour: '2-digit', minute: '2-digit' })}
        </div>
      </div>

      {/* Summary stats */}
      <div className="grid grid-cols-3 gap-4 mb-6">
        <div className="card flex items-center gap-4">
          <div className="p-2.5 rounded-lg bg-green-50 text-green-600">
            <Globe size={20} />
          </div>
          <div>
            <p className="text-sm text-gray-500">アクティブ訪問者</p>
            <p className="text-2xl font-bold text-gray-900">{activeCount}</p>
          </div>
        </div>
        <div className="card flex items-center gap-4">
          <div className="p-2.5 rounded-lg bg-red-50 text-red-600">
            <TrendingUp size={20} />
          </div>
          <div>
            <p className="text-sm text-gray-500">高インテント (80+)</p>
            <p className="text-2xl font-bold text-gray-900">{highIntentCount}</p>
          </div>
        </div>
        <div className="card flex items-center gap-4">
          <div className="p-2.5 rounded-lg bg-brand-50 text-brand-600">
            <MessageSquare size={20} />
          </div>
          <div>
            <p className="text-sm text-gray-500">AI会話中</p>
            <p className="text-2xl font-bold text-gray-900">{chattingCount}</p>
          </div>
        </div>
      </div>

      {/* Filter tabs */}
      <div className="flex gap-2 mb-4">
        {[
          { key: 'all', label: 'すべて' },
          { key: 'active', label: 'アクティブ' },
          { key: 'chatting', label: 'AI会話中' },
          { key: 'qualified', label: 'リード化済' },
          { key: 'left', label: '離脱' },
        ].map(({ key, label }) => (
          <button key={key} onClick={() => setFilter(key)}
            className={`px-4 py-1.5 rounded-full text-sm font-medium transition-colors ${
              filter === key ? 'bg-brand-600 text-white' : 'bg-white text-gray-600 border border-gray-200 hover:bg-gray-50'
            }`}>
            {label}
          </button>
        ))}
      </div>

      {/* Visitor table */}
      <div className="card p-0 overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50 border-b border-gray-100">
            <tr>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">企業</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">現在のページ</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">
                <Eye size={12} className="inline mr-1" />閲覧ページ数
              </th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">
                <Clock size={12} className="inline mr-1" />滞在時間
              </th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">インテントスコア</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">ステータス</th>
              <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">流入元</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-50">
            {filtered.map(visitor => {
              const statusCfg = STATUS_CONFIG[visitor.status]
              return (
                <tr key={visitor.id} className={`transition-colors ${visitor.status === 'left' ? 'opacity-50' : 'hover:bg-gray-50'}`}>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2">
                      {visitor.status !== 'left' && (
                        <span className="w-2 h-2 rounded-full bg-green-400 flex-shrink-0 animate-pulse" />
                      )}
                      {visitor.status === 'left' && (
                        <span className="w-2 h-2 rounded-full bg-gray-300 flex-shrink-0" />
                      )}
                      <div>
                        <p className="text-sm font-medium text-gray-900">{visitor.company}</p>
                        <p className="text-xs text-gray-400">{visitor.location}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-600 max-w-xs truncate">{visitor.current_page}</td>
                  <td className="px-6 py-4 text-sm text-gray-600">{visitor.pages}ページ</td>
                  <td className="px-6 py-4 text-sm text-gray-600">{fmtTime(visitor.time)}</td>
                  <td className="px-6 py-4"><ScoreBar score={visitor.score} /></td>
                  <td className="px-6 py-4">
                    <span className={`badge ${statusCfg.className}`}>{statusCfg.label}</span>
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-500">{visitor.source}</td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>
    </div>
  )
}
