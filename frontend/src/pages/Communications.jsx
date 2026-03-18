import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { useApi } from '../hooks/useApi'
import { api } from '../hooks/useApi'
import LoadingSpinner from '../components/LoadingSpinner'
import ChannelBadge from '../components/ChannelBadge'
import { Mail } from 'lucide-react'

const CHANNELS = ['all', 'slack', 'teams', 'zoom', 'google_meet', 'salesforce', 'hubspot']

const INTEGRATION_INFO = {
  slack:       { name: 'Slack',            desc: 'チームの会話を解析' },
  teams:       { name: 'Microsoft Teams',  desc: '商談コミュニケーション分析' },
  zoom:        { name: 'Zoom',             desc: '商談録画の文字起こし・分析' },
  google_meet: { name: 'Google Meet',      desc: 'ミーティング録画解析' },
  salesforce:  { name: 'Salesforce',       desc: 'CRM データ同期' },
  hubspot:     { name: 'HubSpot',          desc: 'マーケティング・CRM連携' },
  gmail:       { name: 'Gmail',            desc: 'メール履歴からContacts・会社をインポート' },
}

const SENTIMENT_CONFIG = {
  positive: { label: 'ポジティブ', cls: 'bg-green-100 text-green-700' },
  neutral:  { label: 'ニュートラル', cls: 'bg-gray-100 text-gray-600' },
  negative: { label: 'ネガティブ',  cls: 'bg-red-100 text-red-600' },
}

// Must point directly to Rails backend (not Vite proxy) because window.location.href
// redirects need to follow the OAuth chain through the browser's address bar.
const API_BASE = (import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000').replace(/\/$/, '')

export default function Communications() {
  const navigate = useNavigate()
  const [channel, setChannel] = useState('all')
  const { data: comms, loading: l1 } = useApi(
    channel === 'all' ? '/api/communications' : `/api/communications?channel=${channel}`
  )
  const { data: integrations, loading: l2, refetch: refetchIntg } = useApi('/api/integrations')
  const [disconnecting, setDisconnecting] = useState(null)
  const [toast, setToast] = useState(null)  // { message, type: 'success' | 'error' }

  // Detect OAuth callback result in query string (?connected=slack or ?oauth_error=...)
  useEffect(() => {
    const params = new URLSearchParams(window.location.search)
    const connected = params.get('connected')
    const oauthError = params.get('oauth_error')

    if (connected) {
      const info = INTEGRATION_INFO[connected]
      setToast({ message: `${info?.name || connected} の接続に成功しました`, type: 'success' })
      window.history.replaceState({}, '', window.location.pathname)
      refetchIntg()
    } else if (oauthError) {
      setToast({ message: `接続に失敗しました: ${decodeURIComponent(oauthError)}`, type: 'error' })
      window.history.replaceState({}, '', window.location.pathname)
    }
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  // Auto-dismiss toast after 4 seconds
  useEffect(() => {
    if (!toast) return
    const timer = setTimeout(() => setToast(null), 4000)
    return () => clearTimeout(timer)
  }, [toast])

  async function handleDisconnect(intg) {
    setDisconnecting(intg.integration_type)
    try {
      await api.delete(`/api/integrations/${intg.id}/disconnect`)
      refetchIntg()
    } catch {
      setToast({ message: '接続解除に失敗しました', type: 'error' })
    } finally {
      setDisconnecting(null)
    }
  }

  function handleConnect(intg) {
    // OAuth flow: navigate the browser directly to the Rails authorize endpoint.
    // This triggers a redirect chain: Rails → OAuth provider → callback → frontend.
    window.location.href = `${API_BASE}/api/oauth/${intg.integration_type}/authorize`
  }

  if (l1 || l2) return <LoadingSpinner />

  return (
    <div className="p-6 space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">通信・連携</h1>

      {/* Toast notification */}
      {toast && (
        <div className={`fixed top-4 right-4 z-50 px-4 py-3 rounded-lg shadow-lg text-sm font-medium ${
          toast.type === 'success' ? 'bg-green-600 text-white' : 'bg-red-600 text-white'
        }`}>
          {toast.message}
        </div>
      )}

      {/* Gmail import CTA */}
      <div className="flex items-center gap-4 bg-red-50 border border-red-200 rounded-xl px-5 py-4">
        <Mail size={24} className="text-red-500 flex-shrink-0" />
        <div className="flex-1">
          <p className="text-sm font-semibold text-gray-900">GmailからContacts・会社をインポート</p>
          <p className="text-xs text-gray-500 mt-0.5">メール履歴のドメインから会社とコンタクトを自動登録できます</p>
        </div>
        <button
          onClick={() => navigate('/gmail-import')}
          className="flex-shrink-0 bg-red-600 hover:bg-red-700 text-white text-sm font-medium px-4 py-2 rounded-lg transition-colors"
        >
          インポートを開始
        </button>
      </div>

      {/* Integration management */}
      <div className="card">
        <h2 className="text-sm font-semibold text-gray-700 mb-4">API連携管理</h2>
        <div className="grid grid-cols-3 gap-3">
          {(integrations || []).map((intg) => {
            const info = INTEGRATION_INFO[intg.integration_type]
            const connected = intg.status === 'connected'
            const busy = disconnecting === intg.integration_type
            return (
              <div key={intg.id} className={`p-3 border rounded-lg ${connected ? 'border-green-200 bg-green-50' : 'border-gray-200'}`}>
                <div className="flex items-center justify-between mb-1">
                  <span className="text-sm font-medium text-gray-800">{info?.name || intg.integration_type}</span>
                  <span className={`text-xs px-1.5 py-0.5 rounded ${connected ? 'bg-green-200 text-green-800' : 'bg-gray-100 text-gray-500'}`}>
                    {connected ? '接続済' : '未接続'}
                  </span>
                </div>
                <p className="text-xs text-gray-500 mb-2">{info?.desc}</p>
                {intg.last_synced_at && (
                  <p className="text-xs text-gray-400 mb-2">
                    最終同期: {new Date(intg.last_synced_at).toLocaleString('ja-JP')}
                  </p>
                )}
                <button
                  onClick={() => connected ? handleDisconnect(intg) : handleConnect(intg)}
                  disabled={busy}
                  className={`w-full text-xs py-1 rounded font-medium transition-colors ${
                    connected
                      ? 'border border-red-200 text-red-600 hover:bg-red-50'
                      : 'bg-brand-600 text-white hover:bg-brand-700'
                  } disabled:opacity-50`}
                >
                  {busy ? '処理中...' : connected ? '接続解除' : '接続する'}
                </button>
              </div>
            )
          })}
        </div>
      </div>

      {/* Channel filter tabs */}
      <div className="flex gap-2 flex-wrap">
        {CHANNELS.map((ch) => (
          <button
            key={ch}
            onClick={() => setChannel(ch)}
            className={`text-xs px-3 py-1.5 rounded-lg font-medium transition-colors ${
              channel === ch ? 'bg-brand-600 text-white' : 'bg-white border border-gray-200 text-gray-600 hover:bg-gray-50'
            }`}
          >
            {ch === 'all' ? 'すべて' : ch}
          </button>
        ))}
      </div>

      {/* Communication list */}
      <div className="space-y-3">
        {(comms || []).length === 0 ? (
          <div className="card text-center py-8 text-gray-400">通信データがありません</div>
        ) : (
          (comms || []).map((c) => {
            const sent = SENTIMENT_CONFIG[c.sentiment]
            return (
              <div key={c.id} className="card">
                <div className="flex items-start gap-3">
                  <ChannelBadge channel={c.channel} />
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      {c.company_name && <span className="text-sm font-medium text-gray-800">{c.company_name}</span>}
                      {c.contact_name && <span className="text-xs text-gray-500">{c.contact_name}</span>}
                      {sent && (
                        <span className={`text-xs px-2 py-0.5 rounded ${sent.cls}`}>{sent.label}</span>
                      )}
                    </div>
                    {c.summary && <p className="text-sm text-gray-700 mt-1">{c.summary}</p>}
                    {(c.keywords || []).length > 0 && (
                      <div className="flex gap-1 flex-wrap mt-2">
                        {c.keywords.slice(0, 5).map((k, i) => (
                          <span key={i} className="text-xs bg-gray-100 text-gray-600 px-2 py-0.5 rounded">{k}</span>
                        ))}
                      </div>
                    )}
                  </div>
                  <span className="text-xs text-gray-400 flex-shrink-0">
                    {c.recorded_at ? new Date(c.recorded_at).toLocaleDateString('ja-JP') : ''}
                  </span>
                </div>
              </div>
            )
          })
        )}
      </div>
    </div>
  )
}
