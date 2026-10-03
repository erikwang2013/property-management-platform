// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'

const backend = 'http://localhost:8787'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': { target: backend, changeOrigin: true },
      '/admin': { target: backend, changeOrigin: true },
    },
  },
  test: {
    // 纯逻辑用 node；挂载页面的冒烟测试在文件头用 `@vitest-environment jsdom` 自行声明环境
    environment: 'node',
    include: ['src/**/*.test.ts', 'src/**/*.test.tsx'],
  },
})
