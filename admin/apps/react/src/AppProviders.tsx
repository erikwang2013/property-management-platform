// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import { useState, type ReactNode } from 'react'
import { BrowserRouter } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { App as AntdApp, ConfigProvider } from 'antd'
import zhCN from 'antd/locale/zh_CN'
import dayjs from 'dayjs'
import 'dayjs/locale/zh-cn'
import { antdTheme } from './theme/tokens'

dayjs.locale('zh-cn')

function createQueryClient() {
  return new QueryClient({
    defaultOptions: { queries: { retry: false, refetchOnWindowFocus: false, staleTime: 30_000 } },
  })
}

/**
 * 应用的外层依赖（主题 / Ant 上下文 / 数据层 / 路由）集中在这里，
 * main.tsx 与冒烟测试挂载页面时用的是同一份，避免"测试里补了 Provider、线上没补"的假绿。
 */
export default function AppProviders({ children }: { children: ReactNode }) {
  const [queryClient] = useState(createQueryClient)

  return (
    <ConfigProvider theme={antdTheme} locale={zhCN}>
      <AntdApp>
        <QueryClientProvider client={queryClient}>
          <BrowserRouter>{children}</BrowserRouter>
        </QueryClientProvider>
      </AntdApp>
    </ConfigProvider>
  )
}
