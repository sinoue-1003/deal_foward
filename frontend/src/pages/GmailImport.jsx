import { useState, useEffect, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { Mail, Building2, User, CheckSquare, Square, ChevronDown, ChevronRight, ArrowLeft, Download } from 'lucide-react'
import { api } from '../hooks/useApi'
import LoadingSpinner from '../components/LoadingSpinner'

const API_BASE = (import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000').replace(/\/$/, '')

export default function GmailImport() {
  const navigate = useNavigate()
  const [loading, setLoading]         = useState(true)
  const [importing, setImporting]     = useState(false)
  const [connected, setConnected]     = useState(false)
  const [domains, setDomains]         = useState([])
  // selectedDomains: Set of domain strings
  const [selectedDomains, setSelectedDomains]     = useState(new Set())
  // expandedDomains: Set of domain strings
  const [expandedDomains, setExpandedDomains]     = useState(new Set())
  // selectedContacts: { [domain]: Set<email> }
  const [selectedContacts, setSelectedContacts]   = useState({})
  const [result, setResult]           = useState(null)  // import result
  const [toast, setToast]             = useState(null)

  // Show toast and auto-dismiss
  const showToast = useCallback((message, type = 'success') => {
    setToast({ message, type })
    setTimeout(() => setToast(null), 4000)
  }, [])

  // Load preview on mount
  useEffect(() => {
    const params = new URLSearchParams(window.location.search)
    if (params.get('connected') === 'true') {
      showToast('Gmailの接続に成功しました')
      window.history.replaceState({}, '', window.location.pathname)
    }

    api.get('/api/gmail/preview')
      .then((data) => {
        setConnected(data.connected)
        setDomains(data.domains || [])
        // Default: select all domains and all contacts
        const allDomains = new Set((data.domains || []).map((d) => d.domain))
        const allContacts = {}
        ;(data.domains || []).forEach((d) => {
          allContacts[d.domain] = new Set(d.contacts.map((c) => c.email))
        })
        setSelectedDomains(allDomains)
        setSelectedContacts(allContacts)
        // Expand first 3 domains by default
        setExpandedDomains(new Set((data.domains || []).slice(0, 3).map((d) => d.domain)))
      })
      .catch(() => showToast('プレビューの取得に失敗しました', 'error'))
      .finally(() => setLoading(false))
  }, [showToast])

  function toggleDomain(domain) {
    setSelectedDomains((prev) => {
      const next = new Set(prev)
      if (next.has(domain)) {
        next.delete(domain)
      } else {
        next.add(domain)
        // Also select all contacts when domain is checked
        const domainData = domains.find((d) => d.domain === domain)
        if (domainData) {
          setSelectedContacts((cp) => ({
            ...cp,
            [domain]: new Set(domainData.contacts.map((c) => c.email))
          }))
        }
      }
      return next
    })
  }

  function toggleContact(domain, email) {
    setSelectedContacts((prev) => {
      const set = new Set(prev[domain] || [])
      if (set.has(email)) {
        set.delete(email)
      } else {
        set.add(email)
      }
      return { ...prev, [domain]: set }
    })
  }

  function toggleExpand(domain) {
    setExpandedDomains((prev) => {
      const next = new Set(prev)
      next.has(domain) ? next.delete(domain) : next.add(domain)
      return next
    })
  }

  function toggleAll(checked) {
    if (checked) {
      const allDomains = new Set(domains.map((d) => d.domain))
      const allContacts = {}
      domains.forEach((d) => {
        allContacts[d.domain] = new Set(d.contacts.map((c) => c.email))
      })
      setSelectedDomains(allDomains)
      setSelectedContacts(allContacts)
    } else {
      setSelectedDomains(new Set())
      setSelectedContacts({})
    }
  }

  async function handleImport() {
    const selected = domains
      .filter((d) => selectedDomains.has(d.domain))
      .map((d) => ({
        domain:       d.domain,
        company_name: d.company_name,
        contacts:     d.contacts.filter((c) =>
          (selectedContacts[d.domain] || new Set()).has(c.email)
        )
      }))
      .filter((d) => d.contacts.length > 0)

    if (selected.length === 0) {
      showToast('インポートする項目を選択してください', 'error')
      return
    }

    setImporting(true)
    try {
      const data = await api.post('/api/gmail/import', { domains: selected })
      setResult(data)
    } catch {
      showToast('インポートに失敗しました', 'error')
    } finally {
      setImporting(false)
    }
  }

  const totalSelected = domains
    .filter((d) => selectedDomains.has(d.domain))
    .reduce((sum, d) => sum + (selectedContacts[d.domain]?.size || 0), 0)

  const allChecked = domains.length > 0 && selectedDomains.size === domains.length

  if (loading) return <LoadingSpinner />

  // ── Import result screen ───────────────────────────────────────────────────
  if (result) {
    return (
      <div className="p-6 max-w-lg mx-auto space-y-6 mt-12">
        <div className="card text-center space-y-4">
          <div className="text-4xl">✅</div>
          <h2 className="text-xl font-bold text-gray-900">インポート完了</h2>
          <div className="flex justify-center gap-8 pt-2">
            <Stat label="新規会社" value={result.companies_created} />
            <Stat label="新規コンタクト" value={result.contacts_created} />
            <Stat label="スキップ" value={result.skipped} />
          </div>
          <div className="flex gap-3 pt-4 justify-center">
            <button
              onClick={() => navigate('/deals')}
              className="btn-primary px-6"
            >
              商談を確認
            </button>
            <button
              onClick={() => { setResult(null); setSelectedDomains(new Set()); setSelectedContacts({}) }}
              className="btn-secondary px-6"
            >
              続けてインポート
            </button>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="p-6 space-y-5">
      {/* Toast */}
      {toast && (
        <div className={`fixed top-4 right-4 z-50 px-4 py-3 rounded-lg shadow-lg text-sm font-medium ${
          toast.type === 'success' ? 'bg-green-600 text-white' : 'bg-red-600 text-white'
        }`}>
          {toast.message}
        </div>
      )}

      {/* Header */}
      <div className="flex items-center gap-3">
        <button onClick={() => navigate('/communications')} className="text-gray-400 hover:text-gray-700">
          <ArrowLeft size={20} />
        </button>
        <Mail size={22} className="text-red-500" />
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Gmailからインポート</h1>
          <p className="text-sm text-gray-500">
            {connected
              ? 'Gmailのメール履歴から会社とコンタクトを取り込みます'
              : 'デモデータを表示中 — Gmailを接続するとメール履歴から取り込めます'}
          </p>
        </div>
        {!connected && (
          <button
            onClick={() => { window.location.href = `${API_BASE}/api/oauth/gmail/authorize` }}
            className="ml-auto bg-red-600 hover:bg-red-700 text-white text-sm font-medium px-4 py-2 rounded-lg transition-colors"
          >
            Gmailを接続する
          </button>
        )}
      </div>

      {/* Stats bar */}
      <div className="flex items-center gap-6 bg-white border border-gray-200 rounded-xl px-5 py-3 text-sm">
        <span className="text-gray-500">
          <span className="font-semibold text-gray-900">{domains.length}</span> ドメイン
        </span>
        <span className="text-gray-500">
          <span className="font-semibold text-gray-900">
            {domains.reduce((s, d) => s + d.contacts.length, 0)}
          </span> コンタクト
        </span>
        <span className="text-gray-500 flex-1">
          <span className="font-semibold text-brand-600">{selectedDomains.size}</span> 社 /{' '}
          <span className="font-semibold text-brand-600">{totalSelected}</span> 件選択中
        </span>
        <label className="flex items-center gap-2 cursor-pointer select-none">
          {allChecked
            ? <CheckSquare size={16} className="text-brand-600" onClick={() => toggleAll(false)} />
            : <Square size={16} className="text-gray-400" onClick={() => toggleAll(true)} />}
          <span className="text-gray-600">すべて選択</span>
        </label>
        <button
          onClick={handleImport}
          disabled={importing || totalSelected === 0}
          className="flex items-center gap-2 bg-brand-600 hover:bg-brand-700 text-white text-sm font-medium px-4 py-1.5 rounded-lg transition-colors disabled:opacity-40"
        >
          <Download size={14} />
          {importing ? 'インポート中...' : `${totalSelected}件をインポート`}
        </button>
      </div>

      {/* Domain list */}
      {domains.length === 0 ? (
        <div className="card text-center py-12 text-gray-400">
          インポート可能なデータが見つかりませんでした
        </div>
      ) : (
        <div className="space-y-2">
          {domains.map((d) => {
            const isDomainSelected  = selectedDomains.has(d.domain)
            const isExpanded        = expandedDomains.has(d.domain)
            const contactSet        = selectedContacts[d.domain] || new Set()
            const selectedCount     = d.contacts.filter((c) => contactSet.has(c.email)).length

            return (
              <div
                key={d.domain}
                className={`card transition-colors ${isDomainSelected ? 'border-brand-200 bg-brand-50/30' : ''}`}
              >
                {/* Domain header */}
                <div className="flex items-center gap-3">
                  <button
                    className="flex-shrink-0"
                    onClick={() => toggleDomain(d.domain)}
                    aria-label="select domain"
                  >
                    {isDomainSelected
                      ? <CheckSquare size={18} className="text-brand-600" />
                      : <Square size={18} className="text-gray-300" />}
                  </button>

                  <Building2 size={16} className={isDomainSelected ? 'text-brand-500' : 'text-gray-400'} />

                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="font-semibold text-gray-900">{d.company_name}</span>
                      <span className="text-xs text-gray-400">{d.domain}</span>
                    </div>
                  </div>

                  <span className="text-xs text-gray-500 flex-shrink-0">
                    {selectedCount}/{d.contacts.length} 件
                  </span>

                  <button
                    onClick={() => toggleExpand(d.domain)}
                    className="text-gray-400 hover:text-gray-600 flex-shrink-0"
                  >
                    {isExpanded
                      ? <ChevronDown size={16} />
                      : <ChevronRight size={16} />}
                  </button>
                </div>

                {/* Contact list (expanded) */}
                {isExpanded && (
                  <div className="mt-3 pl-9 space-y-2 border-t border-gray-100 pt-3">
                    {d.contacts.map((c) => {
                      const isSelected = contactSet.has(c.email)
                      return (
                        <label key={c.email} className="flex items-center gap-2 cursor-pointer select-none group">
                          <button onClick={() => toggleContact(d.domain, c.email)}>
                            {isSelected
                              ? <CheckSquare size={15} className="text-brand-500" />
                              : <Square size={15} className="text-gray-300" />}
                          </button>
                          <User size={13} className="text-gray-400 flex-shrink-0" />
                          <span className="text-sm text-gray-800">{c.name || '名前なし'}</span>
                          <span className="text-xs text-gray-400">{c.email}</span>
                        </label>
                      )
                    })}
                  </div>
                )}
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}

function Stat({ label, value }) {
  return (
    <div className="text-center">
      <div className="text-3xl font-bold text-brand-600">{value}</div>
      <div className="text-xs text-gray-500 mt-1">{label}</div>
    </div>
  )
}
