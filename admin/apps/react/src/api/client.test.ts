// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import { describe, expect, it } from 'vitest'
import { ApiError, createApi, decodeCaptchaImage, unwrap, type TokenStore } from './client'

const json = (body: unknown) => new Response(JSON.stringify(body), { status: 200, headers: { 'Content-Type': 'application/json' } })

function memoryStore(access: string | null = 'old-token', refresh: string | null = 'refresh-token'): TokenStore & { cleared: number } {
  const state = { access, refresh, cleared: 0 }
  return {
    get cleared() {
      return state.cleared
    },
    getAccess: () => state.access,
    getRefresh: () => state.refresh,
    setTokens: (a, r) => {
      state.access = a
      state.refresh = r ?? state.refresh
    },
    clear: () => {
      state.access = null
      state.refresh = null
      state.cleared += 1
    },
  }
}

describe('响应包解包', () => {
  it('code=0 返回 data', () => {
    expect(unwrap<{ id: string }>({ code: 0, message: 'ok', data: { id: 'abc' } })).toEqual({ id: 'abc' })
  })

  it('code!==0 抛 ApiError 并带上后端 message', () => {
    expect(() => unwrap({ code: 422, message: '小区名称不能为空', data: [] })).toThrowError(
      new ApiError(422, '小区名称不能为空'),
    )
  })

  it('非对象响应也抛错', () => {
    expect(() => unwrap(null)).toThrowError(ApiError)
  })
})

describe('验证码 image 二次编码', () => {
  it('解码一次即得到可直接用作 src 的 data URI', () => {
    const dataUri = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUg=='
    const image = btoa(dataUri)
    expect(image).not.toContain('data:image')
    expect(decodeCaptchaImage(image)).toBe(dataUri)
    expect(decodeCaptchaImage(image).startsWith('data:image/png;base64,')).toBe(true)
  })

  it('非法 base64 不抛异常', () => {
    expect(decodeCaptchaImage('!!!!')).toBe('')
  })
})

describe('401 刷新排队', () => {
  it('并发 401 只发一次刷新，其余请求等同一结果后重放', async () => {
    const store = memoryStore()
    const calls: string[] = []
    let refreshCount = 0
    let protectedCount = 0

    const fetchImpl = (async (input: RequestInfo | URL, init?: RequestInit) => {
      const url = String(input)
      calls.push(url)
      if (url.includes('/api/v1/auth/refresh')) {
        refreshCount += 1
        return json({ code: 0, message: 'success', data: { access_token: 'new-token', refresh_token: 'new-refresh' } })
      }
      protectedCount += 1
      // 第一次带旧 token 的请求全部 401（后端以 code 表达，HTTP 仍是 200）
      const auth = (init?.headers as Record<string, string> | undefined)?.Authorization
      if (auth === 'Bearer old-token') return json({ code: 401, message: 'Token已过期或无效', data: [] })
      return json({ code: 0, message: 'success', data: { echo: url } })
    }) as typeof fetch

    const api = createApi({ fetchImpl, store })
    const [a, b] = await Promise.all([api.get<{ echo: string }>('/admin/user'), api.get<{ echo: string }>('/admin/role')])

    expect(refreshCount).toBe(1)
    expect(protectedCount).toBe(4) // 2 次失败 + 2 次重放
    expect(a.echo).toBe('/admin/user')
    expect(b.echo).toBe('/admin/role')
    expect(store.getAccess()).toBe('new-token')
    expect(store.cleared).toBe(0)
    expect(calls.filter((u) => u.includes('/api/v1/auth/refresh'))).toHaveLength(1)
  })

  it('刷新自身 401 时清空认证态并抛 401（不再重放）', async () => {
    const store = memoryStore()
    let loggedOut = 0
    let protectedCount = 0

    const fetchImpl = (async (input: RequestInfo | URL) => {
      const url = String(input)
      if (url.includes('/api/v1/auth/refresh')) {
        return json({ code: 401, message: '刷新令牌无效或已过期', data: [] })
      }
      protectedCount += 1
      return json({ code: 401, message: 'Token已过期或无效', data: [] })
    }) as typeof fetch

    const api = createApi({ fetchImpl, store, onLogout: () => (loggedOut += 1) })

    await expect(api.get('/admin/user')).rejects.toThrowError(ApiError)
    expect(protectedCount).toBe(1)
    expect(store.cleared).toBe(1)
    expect(loggedOut).toBe(1)
  })
})
