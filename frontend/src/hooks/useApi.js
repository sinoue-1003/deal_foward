import { useState, useEffect } from 'react'

// In production (Cloudflare Pages), set VITE_API_BASE_URL to the Worker URL:
//   e.g. https://dealforward-api.YOUR_ACCOUNT.workers.dev
// In local dev, leave unset — Vite proxy forwards /api → localhost:8000.
const BASE = (import.meta.env.VITE_API_BASE_URL || '').replace(/\/$/, '')

async function apiFetch(path, options = {}) {
  const res = await fetch(`${BASE}${path}`, {
    headers: { 'Content-Type': 'application/json', ...options.headers },
    ...options,
  })
  if (!res.ok) throw new Error(`API error ${res.status}`)
  return res.json()
}

export function useApi(path) {
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    if (!path) return
    setLoading(true)
    apiFetch(path)
      .then(setData)
      .catch(setError)
      .finally(() => setLoading(false))
  }, [path])

  return { data, loading, error, refetch: () => {
    setLoading(true)
    apiFetch(path).then(setData).catch(setError).finally(() => setLoading(false))
  }}
}

export const api = {
  get: (path) => apiFetch(path),
  post: (path, body) => apiFetch(path, { method: 'POST', body: JSON.stringify(body) }),
  patch: (path, body) => apiFetch(path, { method: 'PATCH', body: JSON.stringify(body) }),
  delete: (path) => apiFetch(path, { method: 'DELETE' }),
}
