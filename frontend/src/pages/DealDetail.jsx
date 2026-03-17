import { useParams, Link } from 'react-router-dom'
import { BookOpen, ArrowLeft } from 'lucide-react'
import { useApi } from '../hooks/useApi'
import StageBadge from '../components/StageBadge'
import LoadingSpinner from '../components/LoadingSpinner'

export default function DealDetail() {
  const { id } = useParams()
  const { data: deal, loading } = useApi(`/api/deals/${id}`)

  if (loading) return <LoadingSpinner />
  if (!deal) return <div className="p-6 text-gray-500">商談が見つかりません</div>

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center gap-3">
        <Link to="/deals" className="text-gray-400 hover:text-gray-600"><ArrowLeft size={20} /></Link>
        <div>
          <h1 className="text-2xl font-bold text-gray-900">{deal.title}</h1>
          {deal.company?.name && <p className="text-gray-500 text-sm">{deal.company.name}</p>}
        </div>
        <StageBadge stage={deal.stage} />
      </div>

      <div className="grid grid-cols-3 gap-6">
        <div className="col-span-2 space-y-4">
          {/* Deal info */}
          <div className="card">
            <h2 className="text-sm font-semibold text-gray-700 mb-3">商談詳細</h2>
            <dl className="grid grid-cols-2 gap-3 text-sm">
              <div>
                <dt className="text-gray-500 text-xs">金額</dt>
                <dd className="font-medium">{deal.amount ? `¥${Number(deal.amount).toLocaleString()}` : '—'}</dd>
              </div>
              <div>
                <dt className="text-gray-500 text-xs">確度</dt>
                <dd className="font-medium">{deal.probability || 0}%</dd>
              </div>
              <div>
                <dt className="text-gray-500 text-xs">担当者</dt>
                <dd className="font-medium">{deal.owner || '—'}</dd>
              </div>
              <div>
                <dt className="text-gray-500 text-xs">クローズ予定日</dt>
                <dd className="font-medium">{deal.close_date ? new Date(deal.close_date).toLocaleDateString('ja-JP') : '—'}</dd>
              </div>
            </dl>
            {deal.notes && (
              <div className="mt-3 p-3 bg-gray-50 rounded-lg">
                <p className="text-xs text-gray-500 mb-1">メモ</p>
                <p className="text-sm text-gray-700">{deal.notes}</p>
              </div>
            )}
          </div>

          {/* Linked Playbooks */}
          <div className="card">
            <h2 className="text-sm font-semibold text-gray-700 mb-3 flex items-center gap-2">
              <BookOpen size={14} className="text-brand-500" />
              関連プレイブック
            </h2>
            {deal.playbooks?.length ? (
              <div className="space-y-2">
                {deal.playbooks.map((pb) => {
                  const total = (pb.steps || []).length
                  const done = (pb.steps || []).filter((s) => s.status === 'completed').length
                  return (
                    <Link key={pb.id} to={`/playbooks/${pb.id}`}
                      className="flex items-center justify-between p-3 border border-gray-100 rounded-lg hover:border-brand-300 transition-colors">
                      <div>
                        <p className="text-sm font-medium text-gray-800">{pb.title}</p>
                        <p className="text-xs text-gray-500 mt-0.5">{done}/{total} ステップ完了</p>
                        {pb.status_summary?.next_action && (
                          <p className="text-xs text-brand-600 mt-0.5">
                            次: {pb.status_summary.next_action.description || pb.status_summary.next_action.action_type}
                          </p>
                        )}
                      </div>
                      <span className={`text-xs px-2 py-0.5 rounded ${pb.status === 'active' ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-600'}`}>
                        {pb.status === 'active' ? 'アクティブ' : pb.status}
                      </span>
                    </Link>
                  )
                })}
              </div>
            ) : (
              <p className="text-sm text-gray-400">関連プレイブックなし</p>
            )}
          </div>
        </div>

        {/* Sidebar */}
        <div className="space-y-4">
          {deal.contact && (
            <div className="card">
              <h2 className="text-sm font-semibold text-gray-700 mb-2">担当者</h2>
              <p className="text-sm font-medium text-gray-800">{deal.contact.name}</p>
              {deal.contact.role && <p className="text-xs text-gray-500">{deal.contact.role}</p>}
              {deal.contact.email && <p className="text-xs text-brand-600">{deal.contact.email}</p>}
            </div>
          )}
          {deal.company && (
            <div className="card">
              <h2 className="text-sm font-semibold text-gray-700 mb-2">会社情報</h2>
              <p className="text-sm font-medium text-gray-800">{deal.company.name}</p>
              {deal.company.industry && <p className="text-xs text-gray-500">{deal.company.industry}</p>}
              {deal.company.website && (
                <a href={deal.company.website} target="_blank" rel="noreferrer"
                  className="text-xs text-brand-600 hover:underline">{deal.company.website}</a>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
