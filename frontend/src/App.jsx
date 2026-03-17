import { BrowserRouter, Routes, Route, NavLink } from 'react-router-dom'
import {
  LayoutDashboard, MessageSquare, BookOpen,
  Radio, BarChart3, Briefcase, Bot
} from 'lucide-react'

import Dashboard from './pages/Dashboard'
import Chatbot from './pages/Chatbot'
import ChatbotDetail from './pages/ChatbotDetail'
import Playbooks from './pages/Playbooks'
import PlaybookDetail from './pages/PlaybookDetail'
import Communications from './pages/Communications'
import Deals from './pages/Deals'
import DealDetail from './pages/DealDetail'
import Analytics from './pages/Analytics'

const navItems = [
  { to: '/',               icon: LayoutDashboard, label: 'ダッシュボード' },
  { to: '/chatbot',        icon: MessageSquare,   label: 'チャットbot' },
  { to: '/playbooks',      icon: BookOpen,        label: 'プレイブック' },
  { to: '/communications', icon: Radio,           label: '通信・連携' },
  { to: '/deals',          icon: Briefcase,       label: '商談' },
  { to: '/analytics',      icon: BarChart3,       label: 'アナリティクス' },
]

export default function App() {
  return (
    <BrowserRouter>
      <div className="flex h-screen overflow-hidden">
        <aside className="w-56 bg-gray-900 flex flex-col flex-shrink-0">
          <div className="flex items-center gap-2 px-5 py-5 border-b border-gray-700">
            <Bot className="text-brand-500" size={22} />
            <span className="text-white font-bold text-lg tracking-tight">Deal Forward</span>
          </div>
          <p className="text-gray-500 text-xs px-5 pb-3">AI営業プラットフォーム</p>
          <nav className="flex-1 py-2 px-3 space-y-1">
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
              <div className="w-8 h-8 rounded-full bg-brand-600 flex items-center justify-center text-white text-sm font-bold">A</div>
              <div>
                <p className="text-white text-sm font-medium">Admin</p>
                <p className="text-gray-400 text-xs">営業マネージャー</p>
              </div>
            </div>
          </div>
        </aside>

        <main className="flex-1 overflow-auto">
          <Routes>
            <Route path="/"                   element={<Dashboard />} />
            <Route path="/chatbot"            element={<Chatbot />} />
            <Route path="/chatbot/:id"        element={<ChatbotDetail />} />
            <Route path="/playbooks"          element={<Playbooks />} />
            <Route path="/playbooks/:id"      element={<PlaybookDetail />} />
            <Route path="/communications"     element={<Communications />} />
            <Route path="/deals"              element={<Deals />} />
            <Route path="/deals/:id"          element={<DealDetail />} />
            <Route path="/analytics"          element={<Analytics />} />
          </Routes>
        </main>
      </div>
    </BrowserRouter>
  )
}
