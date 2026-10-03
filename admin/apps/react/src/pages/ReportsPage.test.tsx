// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
// @vitest-environment jsdom

import { afterEach, beforeAll, describe, expect, it, vi } from 'vitest'
import { cleanup, render, waitFor } from '@testing-library/react'
import AppProviders from '../AppProviders'
import { chartColors } from '../theme/tokens'
import ReportsPage from './ReportsPage'

/** Chart 收到的 option 摘出来的最小形状（ECharts 的图例/轴文字画在 canvas 上，DOM 里查不到，只能拦 option） */
type CapturedOption = {
  xAxis?: { data?: string[] }
  color?: string[]
  series?: { name?: string; type?: string; data?: unknown[] }[]
}

// 这两处缺陷都是「图画得出来、肉眼看正常」：图例把枚举号当文案、横轴丢月份，只有断言 option 才抓得到
const seen = vi.hoisted(() => [] as CapturedOption[])

vi.mock('../components/Chart', () => ({
  default: ({ option }: { option: CapturedOption }) => {
    seen.push(option)
    return null
  },
}))

/**
 * 桩数据刻意让两串月份不等长（支出多一个 2026-10）：类目轴与系列按下标对齐，
 * 轴上没有这个月时该点会被静默丢弃 —— 桩数据两端等长就永远测不出来。
 */
const REPORT = {
  income_trend: [
    { month: '2026-08', total: 100 },
    { month: '2026-09', total: 200 },
  ],
  expense_trend: [
    { month: '2026-08', total: 50 },
    { month: '2026-09', total: 60 },
    { month: '2026-10', total: 70 },
  ],
  visitor_status: [
    { status: 0, count: 3 },
    { status: 1, count: 2 },
    { status: 3, count: 1 },
    { status: 9, count: 4 }, // 字典外：兜底文案至少要保住「这是状态字段」
  ],
  arrears_ranking: [],
}

beforeAll(() => {
  // antd 的栅格/Sider 需要 matchMedia 与 ResizeObserver，jsdom 没有（同 routes.smoke.test.tsx）
  Object.defineProperty(window, 'matchMedia', {
    writable: true,
    configurable: true,
    value: (query: string) => ({
      matches: false,
      media: query,
      onchange: null,
      addListener: () => {},
      removeListener: () => {},
      addEventListener: () => {},
      removeEventListener: () => {},
      dispatchEvent: () => false,
    }),
  })
  Object.defineProperty(window, 'ResizeObserver', {
    writable: true,
    configurable: true,
    value: class {
      observe() {}
      unobserve() {}
      disconnect() {}
    },
  })
  Element.prototype.scrollIntoView = () => {}
})

afterEach(async () => {
  cleanup()
  vi.unstubAllGlobals()
  seen.length = 0
  // 把 antd 内部的延迟 setState/rAF 在当前用例里跑完，别留到 jsdom 拆掉之后（详见 smoke 测试的注释）
  await new Promise((r) => setTimeout(r, 50))
})

async function renderReports() {
  vi.stubGlobal('fetch', async (input: RequestInfo | URL) => {
    const url = String(input)
    const data = url.includes('/admin/report') ? REPORT : { data: [], list: [], total: 0 }
    return {
      status: 200,
      json: async () => ({ code: 0, message: 'ok', data }),
      blob: async () => new Blob([]),
    } as unknown as Response
  })

  window.history.pushState({}, '', '/reports')
  render(
    <AppProviders>
      <ReportsPage />
    </AppProviders>,
  )

  await waitFor(() => expect(seen.some((o) => o.series?.some((s) => s.name === '收入'))).toBe(true))
}

const pick = (pred: (o: CapturedOption) => unknown) => {
  const hit = [...seen].reverse().find(pred)
  expect(hit, '未捕获到目标图表的 option').toBeTruthy()
  return hit as CapturedOption
}

describe('报表页图表口径', () => {
  // 色序是**按位置的契约**（ECharts 按序列下标取色）：前五位由规范 §1.3 定死，
  // 改了序，同一个分类在两端的饼图里就会画出不同颜色 —— 这条钉住前五位，调序必须是有意的
  it('图表色序前五位与规范 §1.3 一致（primary → primary-light → warning → success → error）', () => {
    expect(chartColors.slice(0, 5)).toEqual(['#4F46E5', '#6366F1', '#F59E0B', '#10B981', '#F43F5E'])
  })

  it('收支趋势横轴取两串月份的并集，支出独有的月份不丢点', async () => {
    await renderReports()
    const trend = pick((o) => o.series?.some((s) => s.name === '收入'))
    expect(trend.xAxis?.data).toEqual(['2026-08', '2026-09', '2026-10'])
    // 缺月补 0：既有收入 0 的月，也有支出 70 的月，都落在正确下标上
    expect(trend.series?.find((s) => s.name === '收入')?.data).toEqual([100, 200, 0])
    expect(trend.series?.find((s) => s.name === '支出')?.data).toEqual([50, 60, 70])
    // 收入主色 / 支出危险色是**显式取语义色**（同 Angular `[TOKENS.primary, TOKENS.error]`）：
    // 若改回按 `chartColors[下标]` 取，§1.3 一调色序支出的颜色就会悄悄变（玫红→绿），这里把它钉住
    expect(trend.color).toEqual(['#4F46E5', '#F43F5E'])
  })

  it('访客状态图例用字典文案，不出现「状态0」这类裸枚举号', async () => {
    await renderReports()
    // pick 取「最后一个匹配」= 页面里最后一张饼图（支付方式 → 报修 → 投诉 → 访客）。
    // 不按「名字像已预约」去找：那样旧实现（图例是裸枚举号）会匹配不上而报「没捕获到 option」，
    // 掩盖真正的问题 —— 现在旧实现会直接把它实际画的名字摆出来对比。
    const visitor = pick((o) => o.series?.some((s) => s.type === 'pie'))
    // 系列名进 tooltip 标题（§1.3，同 Angular `pie(rows, '访客状态')`），与卡片标题同文案
    expect(visitor.series?.[0]?.name).toBe('访客状态')
    expect(visitor.series?.[0]?.data).toEqual([
      { name: '已预约', value: 3 },
      { name: '已到访', value: 2 },
      { name: '已取消', value: 1 },
      { name: '状态 9', value: 4 },
    ])
  })
})
