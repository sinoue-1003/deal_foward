export default function LoadingSpinner({ message = '読み込み中...' }) {
  return (
    <div className="flex items-center justify-center h-64 text-gray-400">
      <div className="text-center">
        <div className="w-8 h-8 border-4 border-brand-200 border-t-brand-600 rounded-full animate-spin mx-auto mb-3" />
        <p className="text-sm">{message}</p>
      </div>
    </div>
  )
}
