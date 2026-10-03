// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
// @vitest-environment jsdom

import { useState } from 'react'
import { afterEach, describe, expect, it } from 'vitest'
import { cleanup, render, waitFor } from '@testing-library/react'
import { QueryClient, QueryClientProvider, useQuery } from '@tanstack/react-query'
import RouteErrorBoundary from './RouteErrorBoundary'

/** 畸形响应：/admin/room/tree 本该是数组，这里给对象 —— 就是 verifier 复现白屏的那组桩 */
function Bomb(): React.ReactElement {
  const { data } = useQuery({ queryKey: ['bomb'], queryFn: async () => ({ not: 'an array' }) })
  // 渲染期抛错，模拟页面拿畸形数据直接迭代
  const rows = [...((data as unknown as unknown[]) ?? [])]
  return <div>行数 {rows.length}</div>
}

function Ok() {
  const [n] = useState(0)
  return <div>正常页面 {n}</div>
}

function mount(ui: React.ReactElement) {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return render(<QueryClientProvider client={client}>{ui}</QueryClientProvider>)
}

// 每个用例后必须卸载：用例 1 的回退界面里也有一个「重试」按钮，不卸载则用例 2 的 getByRole
// 会命中上一个用例遗留树里的那个按钮（点到别的 QueryClient 上），表现为「点了没反应」。
afterEach(() => {
  cleanup()
})

describe('路由级错误边界', () => {
  it('页面渲染抛错时只替换内容区，并给出重试', async () => {
    const { getByText, getByRole, queryByText } = mount(
      <div>
        <nav>侧栏仍在这里</nav>
        <RouteErrorBoundary resetKey="/repairs">
          <Bomb />
        </RouteErrorBoundary>
      </div>,
    )
    await waitFor(() => expect(getByText('这个页面出了点问题')).toBeTruthy())
    // 两个汉字的按钮 antd 会插一个空格渲染成「重 试」，所以按 role + 正则断言
    expect(getByRole('button', { name: /重\s*试/ })).toBeTruthy()
    // 壳没被一起炸掉 —— 这正是「边界放在路由层级」的意义
    expect(queryByText('侧栏仍在这里')).toBeTruthy()
  })

  it('点「重试」会让出错的查询重新发请求', async () => {
    const calls: number[] = []
    function Fetcher(): React.ReactElement {
      const { data } = useQuery({
        queryKey: ['retry-probe'],
        queryFn: async () => {
          calls.push(1)
          return { not: 'an array' }
        },
      })
      return <div>行数 {[...((data as unknown as unknown[]) ?? [])].length}</div>
    }
    const client = new QueryClient({ defaultOptions: { queries: { retry: false } } })
    const { getByRole, getByText } = render(
      <QueryClientProvider client={client}>
        <RouteErrorBoundary resetKey="/repairs">
          <Fetcher />
        </RouteErrorBoundary>
      </QueryClientProvider>,
    )
    await waitFor(() => expect(getByText('这个页面出了点问题')).toBeTruthy())
    expect(calls.length).toBe(1)
    getByRole('button', { name: /重\s*试/ }).click()
    await waitFor(() => expect(calls.length).toBe(2))
  })

  it('正常响应下边界是透明的', async () => {
    const { getByText } = mount(
      <RouteErrorBoundary resetKey="/repairs">
        <Ok />
      </RouteErrorBoundary>,
    )
    await waitFor(() => expect(getByText('正常页面 0')).toBeTruthy())
  })
})
