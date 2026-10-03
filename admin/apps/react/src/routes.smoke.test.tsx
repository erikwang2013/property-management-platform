// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
// @vitest-environment jsdom

import { afterEach, beforeAll, describe, expect, it, vi } from 'vitest'
import { cleanup, render, waitFor } from '@testing-library/react'
import App from './App'
import AppProviders from './AppProviders'
import { useAuth } from './auth/store'

/** ECharts 在 jsdom 下没有 canvas，图表交互不在冒烟范围内：只保证页面能挂载 */
vi.mock('echarts', () => ({
  init: () => ({ setOption: () => {}, resize: () => {}, dispose: () => {} }),
}))

/**
 * 网络桩：按 URL 给最小可用响应，两种分页形状的键都给（readPage 按形状各取所需）。
 * 页面只依赖「有响应、能解包」，因此这里不需要真后端、也不需要真数据。
 */
function emptyPayload(url: string): unknown {
  if (url.includes('/api/v1/captcha/generate')) {
    return {
      key: 'smoke-key',
      image: btoa('data:image/png;base64,iVBORw0KGgo='),
      extra: { texts: [{ text: '云', order: 1 }] },
    }
  }
  if (url.includes('/admin/dashboard')) {
    return { stats: [], trends: { dates: [], series: [] }, distribution: { user_status: [] }, recent_logs: [] }
  }
  if (url.includes('/admin/room/tree') || url.includes('/admin/permission')) return []
  if (url.includes('/admin/report') || url.includes('/admin/profile')) return {}
  return { data: [], list: [], total: 0 }
}

interface RouteCase {
  /** 测试名里的模块名，失败时一眼看出是哪个页面 */
  page: string
  path: string
  /** 该页面独有的静态文案：页面崩掉/渲染成空壳时不会出现 */
  marker: string
  authed: boolean
  /** 断言的落点（重定向用） */
  landed?: string
}

const ROUTES: RouteCase[] = [
  { page: '登录', path: '/login', marker: '请依次点击验证码上的文字', authed: false },
  { page: '值班台', path: '/dashboard', marker: '近 30 天趋势', authed: true },
  { page: '报表中心', path: '/reports', marker: '收支趋势', authed: true },
  { page: '小区管理', path: '/communities', marker: '楼栋数', authed: true },
  { page: '房产管理', path: '/rooms', marker: '小区结构树', authed: true },
  { page: '业主管理', path: '/owners', marker: '业主管理', authed: true },
  { page: '账单管理', path: '/fee-bills', marker: '账单管理', authed: true },
  { page: '缴费记录', path: '/fee-payments', marker: '登记线下缴费', authed: true },
  { page: '报修管理', path: '/repairs', marker: '报修管理', authed: true },
  { page: '投诉管理', path: '/complaints', marker: '投诉管理', authed: true },
  { page: '用户管理', path: '/users', marker: '用户管理', authed: true },
  { page: '角色权限', path: '/roles', marker: '角色名', authed: true },
  { page: '系统配置', path: '/system/config', marker: '新建配置', authed: true },
  { page: '操作日志', path: '/system/logs', marker: '操作人', authed: true },
  { page: '个人中心', path: '/system/profile', marker: '当前密码', authed: true },
  { page: '404', path: '/no-such-page', marker: '小筑翻了半天也没找到这个页面', authed: true },
  // 重定向类路由
  { page: '首页重定向', path: '/', marker: '近 30 天趋势', authed: true, landed: '/dashboard' },
  { page: '系统区默认页', path: '/system', marker: '新建配置', authed: true, landed: '/system/config' },
  // 未登录态：受保护路由必须被路由守卫送回登录页，而不是白屏或崩溃
  { page: '未登录守卫', path: '/dashboard', marker: '请依次点击验证码上的文字', authed: false, landed: '/login' },
]

beforeAll(() => {
  // antd 的响应式栅格与 Sider breakpoint 需要 matchMedia，jsdom 没有。
  // 直接挂到 window 上（不走 vi.stubGlobal，否则 afterEach 的 unstubAllGlobals 会把它一并撤掉）
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
  useAuth.getState().clear()
  // antd 内部会排 rAF / 延迟 setState（Form 的值防抖 ms:0/10、DatePicker 的 useOpen、Button 的 loading 延迟）。
  // 若留到文件结束、jsdom 环境已拆掉后才触发，会抛 "window is not defined" —— 例数全绿但整个文件被判 exit 1。
  // 这里把残余计时器在当前用例内跑完，代价 ~50ms/例。
  await new Promise((r) => setTimeout(r, 50))
})

describe('逐路由挂载冒烟（页面能构建但一渲染就崩的兜底）', () => {
  it.each(ROUTES)('$page $path 挂载后渲染出「$marker」', async (route) => {
    vi.stubGlobal('fetch', async (input: RequestInfo | URL) => {
      const url = String(input)
      return {
        status: 200,
        json: async () => ({ code: 0, message: 'ok', data: emptyPayload(url) }),
        blob: async () => new Blob([]),
      } as unknown as Response
    })

    if (route.authed) {
      useAuth.setState({
        accessToken: 'smoke-token',
        refreshToken: 'smoke-refresh',
        user: { id: '1', username: 'smoke', real_name: '冒烟' },
      })
    } else {
      useAuth.getState().clear()
    }

    window.history.pushState({}, '', route.path)
    render(
      <AppProviders>
        <App />
      </AppProviders>,
    )

    await waitFor(() => {
      expect(document.body.textContent ?? '').toContain(route.marker)
    })
    if (route.landed) expect(window.location.pathname).toBe(route.landed)
  })
})
