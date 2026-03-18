import { useState, useEffect, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Mail, Building2, User, CheckSquare, Square,
  ChevronDown, ChevronRight, ArrowLeft, Download,
  Sparkles, MessageSquare
} from 'lucide-react'
import { api } from '../hooks/useApi'
import LoadingSpinner from '../components/LoadingSpinner'

const API_BASE = (import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000').replace(/\/$/, '')

export default function GmailImport() {
  const navigate = useNavigate()
  const [loading, setLoading]       = useState(true)
  const [importing, setImporting]   = useState(false)
  const [connected, setConnected]   = useState(false)
  const [domains, setDomains]       = useState([])

  const [selectedDomains, setSelectedDomains]   = useState(new Set())
  const [expandedDomains, setExpandedDomains]   = useState(new Set())
  const [selectedContacts, setSelectedContacts] = useState({})

  // Import options
  const [includeEmails, setIncludeEmails] = useState(true)
  const [analyzeEmails, setAnalyzeEmails] = useState(false)

  const [result, setResult] = useState(null)
  const [toast, setToast]   = useState(null)

  const showToast = useCallback((message, type = 'success') => {
    setToast({ message, type })
    setTimeout(() => setToast(null), 4000)
  }, [])

  useEffect(() => {
    const params = new URLSearchParams(window.location.search)
    if (params.get('connected') === 'true') {
      showToast('Gmailの接続に成功しました')
      window.history.replaceState({}, '', window.location.pathname)
    }

    api.get('/api/gmail/preview')
      .then((data) => {
        setConnected(data.connected)
        const domainList = data.domains || []
        setDomains(domainList)
        const allDomains   = new Set(domainList.map((d) => d.domain))
        const allContacts  = {}
        domainList.forEach((d) => {
          allContacts[d.domain] = new Set(d.contacts.map((c) => c.email))
        })
        setSelectedDomains(allDomains)
        setSelectedContacts(allContacts)
        setExpandedDomains(new Set(domainList.slice(0, 3).map((d) => d.domain)))
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
        const d = domains.find((x) => x.domain === domain)
        if (d) {
          setSelectedContacts((cp) => ({
            ...cp,
            [domain]: new Set(d.contacts.map((c) => c.email))
          }))
        }
      }
      return next
    })
  }

  function toggleContact(domain, email) {
    setSelectedContacts((prev) => {
      const set = new Set(prev[domain] || [])
      set.has(email) ? set.delete(email) : set.add(email)
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
      setSelectedDomains(new Set(domains.map((d) => d.domain)))
      const all = {}
      domains.forEach((d) => { all[d.domain] = new Set(d.contacts.map((c) => c.email)) })
      setSelectedContacts(all)
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
      const data = await api.post('/api/gmail/import', {
        domains:        selected,
        include_emails: includeEmails,
        analyze:        analyzeEmails
      })
      setResult(data)
    } catch {
      showToast('インポートに失敗しました', 'error')
    } finally {
      setImporting(false)
    }
  }

  const totalEmailCount = domains
    .filter((d) => selectedDomains.has(d.domain))
    .reduce((s, d) => s + (d.email_count || 0), 0)

  const totalContacts = domains
    .filter((d) => selectedDomains.has(d.domain))
    .reduce((sum, d) => sum + (selectedContacts[d.domain]?.size || 0), 0)

  const allChecked = domains.length > 0 && selectedDomains.size === domains.length

  if (loading) return <LoadingSpinner />

  // ── Import result screen ────────────────────────────────────────────────────
  if (result) {
    return (
      <div className="p-6 max-w-lg mx-auto space-y-6 mt-10">
        <div className="card text-center space-y-5">
          <div className="text-5xl">✅</div>
          <h2 className="text-xl font-bold text-gray-900">インポート完了</h2>
          <div className="flex justify-center gap-6 flex-wrap">
            <Stat label="新規会社" value={result.companies_created} />
            <Stat label="新規コンタクト" value={result.contacts_created} />
            {result.emails_imported > 0 && (
              <Stat label="メール履歴" value={result.emails_imported} accent />
            )}
            <Stat label="スキップ" value={result.contact_skipped} muted />
          </div>
          {result.emails_imported > 0 && (
            <p className="text-xs text-gray-500">
              メールは「通信・連携」ページで確認できます
            </p>
          )}
          <div className="flex gap-3 pt-2 justify-center flex-wrap">
            <button onClick={() => navigate('/communications')} className="btn-primary px-5">
              通信履歴を確認
            </button>
            <button onClick={() => navigate('/deals')} className="btn-secondary px-5">
              商談を確認
            </button>
            <button
              onClick={() => { setResult(null) }}
              className="text-sm text-gray-400 hover:text-gray-600 px-3"
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
              ? 'Gmailのメール履歴から会社・コンタクト・やり取りを取り込みます'
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

      {/* Import options */}
      <div className="bg-white border border-gray-200 rounded-xl px-5 py-4 space-y-3">
        <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide">取り込みオプション</p>
        <div className="flex flex-wrap gap-6">
          {/* Include emails toggle */}
          <label className="flex items-center gap-3 cursor-pointer select-none">
            <button
              className="flex-shrink-0"
              onClick={() => setIncludeEmails((v) => !v)}
            >
              {includeEmails
                ? <CheckSquare size={18} className="text-brand-600" />
                : <Square size={18} className="text-gray-300" />}
            </button>
            <div>
              <div className="flex items-center gap-1.5">
                <MessageSquare size={14} className="text-brand-500" />
                <span className="text-sm font-medium text-gray-800">メールのやり取りも取り込む</span>
              </div>
              <p className="text-xs text-gray-400 mt-0.5">
                各ドメインとのメール履歴をコミュニケーション記録として保存（最大{20}件/社）
              </p>
            </div>
          </label>

          {/* AI analysis toggle (only when include_emails is on) */}
          <label className={`flex items-center gap-3 cursor-pointer select-none transition-opacity ${includeEmails ? '' : 'opacity-40 pointer-events-none'}`}>
            <button
              className="flex-shrink-0"
              onClick={() => includeEmails && setAnalyzeEmails((v) => !v)}
            >
              {analyzeEmails
                ? <CheckSquare size={18} className="text-purple-600" />
                : <Square size={18} className="text-gray-300" />}
            </button>
            <div>
              <div className="flex items-center gap-1.5">
                <Sparkles size={14} className="text-purple-500" />
                <span className="text-sm font-medium text-gray-800">AIで自動分析する</span>
              </div>
              <p className="text-xs text-gray-400 mt-0.5">
                感情・キーワード・アクション項目をAIが自動抽出（少し時間がかかります）
              </p>
            </div>
          </label>
        </div>
      </div>

      {/* Stats & action bar */}
      <div className="flex items-center gap-5 bg-white border border-gray-200 rounded-xl px-5 py-3 text-sm flex-wrap">
        <span className="text-gray-500">
          <span className="font-semibold text-gray-900">{domains.length}</span> ドメイン
        </span>
        <span className="text-gray-500">
          <span className="font-semibold text-gray-900">
            {domains.reduce((s, d) => s + d.contacts.length, 0)}
          </span> コンタクト
        </span>
        {includeEmails && (
          <span className="text-gray-500">
            <span className="font-semibold text-brand-600">{totalEmailCount}</span> 件のメール対象
          </span>
        )}
        <span className="text-gray-500 flex-1">
          <span className="font-semibold text-brand-600">{selectedDomains.size}</span> 社 /{' '}
          <span className="font-semibold text-brand-600">{totalContacts}</span> 件選択中
        </span>
        <label className="flex items-center gap-2 cursor-pointer select-none">
          <button onClick={() => toggleAll(!allChecked)}>
            {allChecked
              ? <CheckSquare size={16} className="text-brand-600" />
              : <Square size={16} className="text-gray-400" />}
          </button>
          <span className="text-gray-600">すべて選択</span>
        </label>
        <button
          onClick={handleImport}
          disabled={importing || totalContacts === 0}
          className="flex items-center gap-2 bg-brand-600 hover:bg-brand-700 text-white text-sm font-medium px-4 py-1.5 rounded-lg transition-colors disabled:opacity-40"
        >
          <Download size={14} />
          {importing ? 'インポート中...' : `インポート実行`}
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
            const isDomainSelected = selectedDomains.has(d.domain)
            const isExpanded       = expandedDomains.has(d.domain)
            const contactSet       = selectedContacts[d.domain] || new Set()
            const selectedCount    = d.contacts.filter((c) => contactSet.has(c.email)).length

            return (
              <div
                key={d.domain}
                className={`card transition-colors ${isDomainSelected ? 'border-brand-200 bg-brand-50/30' : ''}`}
              >
                {/* Domain header row */}
                <div className="flex items-center gap-3">
                  <button className="flex-shrink-0" onClick={() => toggleDomain(d.domain)}>
                    {isDomainSelected
                      ? <CheckSquare size={18} className="text-brand-600" />
                      : <Square size={18} className="text-gray-300" />}
                  </button>
                  <Building2 size={16} className={isDomainSelected ? 'text-brand-500' : 'text-gray-400'} />
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="font-semibold text-gray-900">{d.company_name}</span>
                      <span className="text-xs text-gray-400">{d.domain}</span>
                    </div>
                  </div>
                  {/* Email count badge */}
                  {includeEmails && d.email_count > 0 && (
                    <span className="flex items-center gap-1 text-xs text-brand-600 bg-brand-50 border border-brand-200 px-2 py-0.5 rounded-full flex-shrink-0">
                      <Mail size={10} />
                      {d.email_count}件
                    </span>
                  )}
                  <span className="text-xs text-gray-500 flex-shrink-0">
                    {selectedCount}/{d.contacts.length}名
                  </span>
                  <button onClick={() => toggleExpand(d.domain)} className="text-gray-400 hover:text-gray-600 flex-shrink-0">
                    {isExpanded ? <ChevronDown size={16} /> : <ChevronRight size={16} />}
                  </button>
                </div>

                {/* Contact list (expanded) */}
                {isExpanded && (
                  <div className="mt-3 pl-9 space-y-2 border-t border-gray-100 pt-3">
                    {d.contacts.map((c) => {
                      const isSelected = contactSet.has(c.email)
                      return (
                        <div key={c.email} className="flex items-center gap-2">
                          <button onClick={() => toggleContact(d.domain, c.email)}>
                            {isSelected
                              ? <CheckSquare size={15} className="text-brand-500" />
                              : <Square size={15} className="text-gray-300" />}
                          </button>
                          <User size={13} className="text-gray-400 flex-shrink-0" />
                          <span className="text-sm text-gray-800">{c.name || '名前なし'}</span>
                          <span className="text-xs text-gray-400">{c.email}</span>
                        </div>
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

function Stat({ label, value, accent, muted }) {
  return (
    <div className="text-center">
      <div className={`text-3xl font-bold ${accent ? 'text-purple-600' : muted ? 'text-gray-400' : 'text-brand-600'}`}>
        {value}
      </div>
      <div className="text-xs text-gray-500 mt-1">{label}</div>
    </div>
  )
}
