import { BrowserRouter, Routes, Route, NavLink } from 'react-router-dom'
import { LayoutDashboard, Globe, MessageSquare, Users, Calendar, BarChart2, Zap } from 'lucide-react'
import Dashboard from './pages/Dashboard'
import Visitors from './pages/Visitors'
import Conversations from './pages/Conversations'
import ConversationDetail from './pages/ConversationDetail'
import Leads from './pages/Leads'
import LeadDetail from './pages/LeadDetail'
import Meetings from './pages/Meetings'
import Analytics from './pages/Analytics'

const navItems = [
  { to: '/', icon: LayoutDashboard, label: 'ダッシュボード' },
  { to: '/visitors', icon: Globe, label: '訪問者' },
  { to: '/conversations', icon: MessageSquare, label: 'AI会話' },
  { to: '/leads', icon: Users, label: 'リード' },
  { to: '/meetings', icon: Calendar, label: 'ミーティング' },
  { to: '/analytics', icon: BarChart2, label: '分析' },
]

export default function App() {
  return (
    <BrowserRouter>
      <div className="flex h-screen overflow-hidden">
        {/* Sidebar */}
        <aside className="w-56 bg-gray-900 flex flex-col flex-shrink-0">
          <div className="flex items-center gap-2 px-5 py-5 border-b border-gray-700">
            <Zap className="text-brand-500" size={22} />
            <span className="text-white font-bold text-lg tracking-tight">DealForward</span>
          </div>
          <nav className="flex-1 py-4 px-3 space-y-1">
            {navItems.map(({ to, icon: Icon, label }) => (
              <NavLink
                key={to}
                to={to}
                end={to === '/'}
                className={({ isActive }) =>
                  `flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors ${
                    isActive
                      ? 'bg-brand-600 text-white'
                      : 'text-gray-400 hover:bg-gray-800 hover:text-white'
                  }`
                }
              >
                <Icon size={18} />
                {label}
              </NavLink>
            ))}
          </nav>
          <div className="px-5 py-4 border-t border-gray-700">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-full bg-brand-600 flex items-center justify-center text-white text-sm font-bold">田</div>
              <div>
                <p className="text-white text-sm font-medium">田中 太郎</p>
                <p className="text-gray-400 text-xs">営業マネージャー</p>
              </div>
            </div>
          </div>
        </aside>

        {/* Main content */}
        <main className="flex-1 overflow-auto">
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/visitors" element={<Visitors />} />
            <Route path="/conversations" element={<Conversations />} />
            <Route path="/conversations/:id" element={<ConversationDetail />} />
            <Route path="/leads" element={<Leads />} />
            <Route path="/leads/:id" element={<LeadDetail />} />
            <Route path="/meetings" element={<Meetings />} />
            <Route path="/analytics" element={<Analytics />} />
          </Routes>
        </main>
      </div>
    </BrowserRouter>
  )
}
