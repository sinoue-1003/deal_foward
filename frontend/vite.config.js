import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    host: true, // Docker では 0.0.0.0 でバインドする必要がある
    proxy: {
      // Docker 環境では API_URL=http://backend:8000 を環境変数で注入
      '/api': process.env.API_URL || 'http://localhost:8000',
    },
  },
})
