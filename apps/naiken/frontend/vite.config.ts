import react from '@vitejs/plugin-react'
import { defineConfig } from 'vitest/config'

// 本番(rails.keisuke-nagaoka.com/naiken/)・ローカル(localhost:9300/naiken/)とも
// nginx配下の /naiken/ で配信するため、ビルド成果物のパスも /naiken/ 起点にする
export default defineConfig({
  base: '/naiken/',
  plugins: [react()],
  server: {
    host: '0.0.0.0',
    port: 5173,
    strictPort: true,
  },
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
  },
})
