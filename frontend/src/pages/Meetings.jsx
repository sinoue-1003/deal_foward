import { useState } from 'react'
import { Calendar, Clock, User, Video, CheckCircle, XCircle, AlertCircle } from 'lucide-react'
import { format, parseISO, isToday, isTomorrow, isPast } from 'date-fns'
import { ja } from 'date-fns/locale'

const MOCK_MEETINGS = [
  {
    id: 1, name: '山田 花子', company: 'Salesforce Japan', email: 'hanako.yamada@salesforce.com',
    rep: '田中 太郎', scheduled_at: '2026-03-15T14:00:00', duration: 30,
    status: 'confirmed', type: 'demo', source: 'AI会話 #42', notes: '競合はHubspot。予算は年間500万円。',
  },
  {
    id: 2, name: '鈴木 一郎', company: 'ソフトバンク株式会社', email: 'ichiro.suzuki@softbank.co.jp',
    rep: '佐藤 次郎', scheduled_at: '2026-03-15T16:30:00', duration: 30,
    status: 'confirmed', type: 'demo', source: 'AI会話 #39', notes: '100名以上のチームでの導入を検討。',
  },
  {
    id: 3, name: '高橋 誠', company: 'NTTデータ株式会社', email: 'makoto.takahashi@nttdata.co.jp',
    rep: '田中 太郎', scheduled_at: '2026-03-16T10:00:00', duration: 45,
    status: 'confirmed', type: 'discovery', source: 'AI会話 #45', notes: 'エンタープライズプランに関心あり。',
  },
  {
    id: 4, name: '中村 美咲', company: 'パナソニック株式会社', email: 'misaki.nakamura@panasonic.co.jp',
    rep: '山本 花子', scheduled_at: '2026-03-16T14:30:00', duration: 30,
    status: 'pending', type: 'demo', source: 'AI会話 #41', notes: '',
  },
  {
    id: 5, name: '伊藤 健一', company: 'トヨタ自動車', email: 'kenichi.ito@toyota.co.jp',
    rep: '佐藤 次郎', scheduled_at: '2026-03-17T11:00:00', duration: 60,
    status: 'confirmed', type: 'technical', source: 'AI会話 #38', notes: 'API連携について技術的な質問多数。',
  },
  {
    id: 6, name: '渡辺 直樹', company: 'KDDI株式会社', email: 'naoki.watanabe@kddi.co.jp',
    rep: '田中 太郎', scheduled_at: '2026-03-14T15:00:00', duration: 30,
    status: 'completed', type: 'demo', source: 'AI会話 #35', notes: 'デモ好評。提案書送付済み。',
  },
  {
    id: 7, name: '小林 翔', company: '富士通株式会社', email: 'sho.kobayashi@fujitsu.co.jp',
    rep: '山本 花子', scheduled_at: '2026-03-13T13:00:00', duration: 30,
    status: 'cancelled', type: 'demo', source: 'AI会話 #33', notes: '担当者変更のため延期。',
  },
  {
    id: 8, name: '加藤 純子', company: '三菱電機株式会社', email: 'junko.kato@mitsubishi.co.jp',
    rep: '田中 太郎', scheduled_at: '2026-03-18T10:30:00', duration: 45,
    status: 'confirmed', type: 'discovery', source: 'AI会話 #47', notes: '新規事業部門での導入。',
  },
]

const STATUS_CONFIG = {
  confirmed: { label: '確定', className: 'bg-green-100 text-green-700', icon: CheckCircle, iconColor: 'text-green-500' },
  pending: { label: '保留中', className: 'bg-amber-100 text-amber-700', icon: AlertCircle, iconColor: 'text-amber-500' },
  completed: { label: '完了', className: 'bg-gray-100 text-gray-600', icon: CheckCircle, iconColor: 'text-gray-400' },
  cancelled: { label: 'キャンセル', className: 'bg-red-100 text-red-700', icon: XCircle, iconColor: 'text-red-500' },
}

const TYPE_CONFIG = {
  demo: { label: '製品デモ', className: 'bg-brand-100 text-brand-700' },
  discovery: { label: 'ディスカバリー', className: 'bg-purple-100 text-purple-700' },
  technical: { label: '技術確認', className: 'bg-orange-100 text-orange-700' },
}

function getDateLabel(dateStr) {
  const date = parseISO(dateStr)
  if (isToday(date)) return '今日'
  if (isTomorrow(date)) return '明日'
  return format(date, 'M月d日(E)', { locale: ja })
}

export default function Meetings() {
  const [filter, setFilter] = useState('upcoming')

  const now = new Date()
  const filtered = MOCK_MEETINGS.filter(m => {
    const meetingDate = parseISO(m.scheduled_at)
    if (filter === 'upcoming') return !isPast(meetingDate) && m.status !== 'cancelled'
    if (filter === 'today') return isToday(meetingDate)
    if (filter === 'past') return isPast(meetingDate) || m.status === 'completed' || m.status === 'cancelled'
    return true
  }).sort((a, b) => parseISO(a.scheduled_at) - parseISO(b.scheduled_at))

  const todayCount = MOCK_MEETINGS.filter(m => isToday(parseISO(m.scheduled_at)) && m.status !== 'cancelled').length
  const upcomingCount = MOCK_MEETINGS.filter(m => !isPast(parseISO(m.scheduled_at)) && m.status !== 'cancelled').length
  const totalBooked = MOCK_MEETINGS.filter(m => m.status !== 'cancelled').length

  return (
    <div className="p-8 max-w-6xl mx-auto">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">ミーティング</h1>
          <p className="text-gray-500 text-sm mt-1">AI会話から予約されたミーティング</p>
        </div>
      </div>

      {/* Summary */}
      <div className="grid grid-cols-3 gap-4 mb-6">
        <div className="card flex items-center gap-4">
          <div className="p-2.5 rounded-lg bg-green-50 text-green-600"><Calendar size={20} /></div>
          <div>
            <p className="text-sm text-gray-500">今日の予約</p>
            <p className="text-2xl font-bold text-gray-900">{todayCount}</p>
          </div>
        </div>
        <div className="card flex items-center gap-4">
          <div className="p-2.5 rounded-lg bg-brand-50 text-brand-600"><Clock size={20} /></div>
          <div>
            <p className="text-sm text-gray-500">今後の予約</p>
            <p className="text-2xl font-bold text-gray-900">{upcomingCount}</p>
          </div>
        </div>
        <div className="card flex items-center gap-4">
          <div className="p-2.5 rounded-lg bg-purple-50 text-purple-600"><Video size={20} /></div>
          <div>
            <p className="text-sm text-gray-500">総予約数 (今月)</p>
            <p className="text-2xl font-bold text-gray-900">{totalBooked}</p>
          </div>
        </div>
      </div>

      {/* Filter tabs */}
      <div className="flex gap-2 mb-6">
        {[
          { key: 'upcoming', label: '今後の予約' },
          { key: 'today', label: '今日' },
          { key: 'past', label: '過去' },
          { key: 'all', label: 'すべて' },
        ].map(({ key, label }) => (
          <button key={key} onClick={() => setFilter(key)}
            className={`px-4 py-1.5 rounded-full text-sm font-medium transition-colors ${
              filter === key ? 'bg-brand-600 text-white' : 'bg-white text-gray-600 border border-gray-200 hover:bg-gray-50'
            }`}>
            {label}
          </button>
        ))}
      </div>

      {/* Meeting list */}
      <div className="space-y-4">
        {filtered.length === 0 && (
          <div className="card text-center py-12">
            <p className="text-gray-400">ミーティングがありません</p>
          </div>
        )}
        {filtered.map(meeting => {
          const statusCfg = STATUS_CONFIG[meeting.status]
          const typeCfg = TYPE_CONFIG[meeting.type]
          const StatusIcon = statusCfg.icon
          const isPastMeeting = isPast(parseISO(meeting.scheduled_at))
          return (
            <div key={meeting.id} className={`card ${isPastMeeting ? 'opacity-70' : ''}`}>
              <div className="flex items-start gap-4">
                {/* Time */}
                <div className="text-center flex-shrink-0 w-20">
                  <p className="text-xs text-gray-400 font-medium">{getDateLabel(meeting.scheduled_at)}</p>
                  <p className="text-2xl font-bold text-gray-900">
                    {format(parseISO(meeting.scheduled_at), 'HH:mm')}
                  </p>
                  <p className="text-xs text-gray-400">{meeting.duration}分</p>
                </div>

                {/* Divider */}
                <div className="w-px bg-gray-200 self-stretch flex-shrink-0" />

                {/* Details */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-4">
                    <div>
                      <div className="flex items-center gap-2 mb-1">
                        <h3 className="font-semibold text-gray-900">{meeting.name}</h3>
                        <span className={`badge ${typeCfg.className}`}>{typeCfg.label}</span>
                        <span className={`badge ${statusCfg.className} flex items-center gap-1`}>
                          <StatusIcon size={10} />
                          {statusCfg.label}
                        </span>
                      </div>
                      <p className="text-sm text-gray-600 flex items-center gap-1">
                        <User size={12} /> {meeting.company}
                      </p>
                      <p className="text-xs text-gray-400 mt-0.5 flex items-center gap-1">
                        <Video size={11} /> 担当: {meeting.rep}
                      </p>
                    </div>
                    <div className="text-right flex-shrink-0">
                      <p className="text-xs text-gray-400">流入元</p>
                      <p className="text-xs text-brand-600 font-medium">{meeting.source}</p>
                    </div>
                  </div>
                  {meeting.notes && (
                    <div className="mt-3 p-3 bg-gray-50 rounded-lg">
                      <p className="text-xs text-gray-600">{meeting.notes}</p>
                    </div>
                  )}
                  <div className="mt-3 flex items-center gap-3">
                    <a href={`mailto:${meeting.email}`}
                      className="text-xs text-brand-600 hover:underline flex items-center gap-1">
                      <span>{meeting.email}</span>
                    </a>
                  </div>
                </div>
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}
