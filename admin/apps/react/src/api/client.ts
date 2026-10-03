// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import { useAuth } from '../auth/store'
import { EP } from './endpoints'

export interface Envelope<T> {
  code: number
  message: string
  data: T
}

export class ApiError extends Error {
  code: number
  constructor(code: number, message: string) {
    super(message)
    this.name = 'ApiError'
    this.code = code
  }
}

/** 统一响应包解包：code !== 0 一律抛 ApiError（message 可直接展示） */
export function unwrap<T>(body: unknown): T {
  if (!body || typeof body !== 'object') {
    throw new ApiError(-1, '响应格式错误')
  }
  const env = body as Partial<Envelope<T>>
  if (env.code !== 0) {
    throw new ApiError(typeof env.code === 'number' ? env.code : -1, String(env.message || '请求失败'))
  }
  return env.data as T
}

/**
 * 验证码图片：后端把整段 data URI 又 base64 了一次，
 * 解码一次后得到可直接作为 <img src> 的 `data:image/png;base64,...`
 */
export function decodeCaptchaImage(image: string): string {
  try {
    return atob(image)
  } catch {
    return ''
  }
}

/** 渲染坐标 → 图片原始坐标（后端按 1:1 像素比对） */
export function toOriginalCoords(
  click: { x: number; y: number },
  natural: { width: number; height: number },
  rendered: { width: number; height: number },
): [number, number] {
  if (!rendered.width || !rendered.height) return [0, 0]
  return [
    Math.round((click.x * natural.width) / rendered.width),
    Math.round((click.y * natural.height) / rendered.height),
  ]
}

export interface TokenStore {
  getAccess: () => string | null
  getRefresh: () => string | null
  setTokens: (accessToken: string, refreshToken?: string | null) => void
  clear: () => void
}

/** 默认落在 zustand 认证态（localStorage 持久化） */
const zustandTokens: TokenStore = {
  getAccess: () => useAuth.getState().accessToken,
  getRefresh: () => useAuth.getState().refreshToken,
  setTokens: (accessToken, refreshToken) => useAuth.getState().setAuth({ access_token: accessToken, refresh_token: refreshToken ?? undefined }),
  clear: () => useAuth.getState().clear(),
}

export interface RequestOptions {
  method?: 'GET' | 'POST' | 'PUT' | 'DELETE'
  params?: Record<string, unknown>
  body?: unknown
  blob?: boolean
}

export interface ApiClientOptions {
  baseUrl?: string
  fetchImpl?: typeof fetch
  store?: TokenStore
  onLogout?: () => void
}

export function createApi(options: ApiClientOptions = {}) {
  const baseUrl = options.baseUrl ?? ''
  const doFetch = options.fetchImpl ?? ((...args: Parameters<typeof fetch>) => fetch(...args))
  const store = options.store ?? zustandTokens
  let refreshing: Promise<boolean> | null = null

  async function refreshTokens(): Promise<boolean> {
    const refreshToken = store.getRefresh()
    if (!refreshToken) return false
    try {
      const res = await doFetch(baseUrl + EP.refresh, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ refresh_token: refreshToken }),
      })
      const json = (await res.json()) as Partial<Envelope<{ access_token: string; refresh_token?: string }>>
      if (json.code !== 0 || !json.data?.access_token) return false
      store.setTokens(json.data.access_token, json.data.refresh_token)
      return true
    } catch {
      return false
    }
  }

  /** 并发 401 只发一次刷新，其余请求排队等同一个 Promise */
  function refreshOnce(): Promise<boolean> {
    if (!refreshing) {
      refreshing = refreshTokens().finally(() => {
        refreshing = null
      })
    }
    return refreshing
  }

  async function send(path: string, opts: RequestOptions, token: string | null): Promise<Response> {
    const url = new URL(baseUrl + path, globalThis.location?.origin ?? 'http://localhost')
    for (const [k, v] of Object.entries(opts.params ?? {})) {
      if (v !== undefined && v !== null && v !== '') url.searchParams.set(k, String(v))
    }
    const headers: Record<string, string> = {}
    if (token) headers.Authorization = `Bearer ${token}`
    let body: string | undefined
    if (opts.body !== undefined) {
      headers['Content-Type'] = 'application/json'
      body = JSON.stringify(opts.body)
    }
    const target = baseUrl ? url.toString() : url.pathname + url.search
    return doFetch(target, { method: opts.method ?? 'GET', headers, body })
  }

  async function request<T>(path: string, opts: RequestOptions = {}): Promise<T> {
    let res = await send(path, opts, store.getAccess())

    if (opts.blob) return (await res.blob()) as T

    let json: unknown = null
    try {
      json = await res.json()
    } catch {
      throw new ApiError(res.status || -1, '响应解析失败')
    }

    const unauthorized = res.status === 401 || (json as Partial<Envelope<unknown>>)?.code === 401
    if (unauthorized) {
      const ok = await refreshOnce()
      if (!ok) {
        store.clear()
        options.onLogout?.()
        throw new ApiError(401, '登录已过期，请重新登录')
      }
      res = await send(path, opts, store.getAccess())
      try {
        json = await res.json()
      } catch {
        throw new ApiError(res.status || -1, '响应解析失败')
      }
    }

    return unwrap<T>(json)
  }

  return {
    request,
    refreshOnce,
    get: <T>(path: string, params?: Record<string, unknown>) => request<T>(path, { params }),
    /** 删除等敏感操作把密码放 query：webman 的 input() 对 DELETE 请求体解析不可靠 */
    del: <T>(path: string, password?: string) =>
      request<T>(path, { method: 'DELETE', params: password ? { password } : undefined }),
    post: <T>(path: string, body?: unknown) => request<T>(path, { method: 'POST', body }),
    put: <T>(path: string, body?: unknown) => request<T>(path, { method: 'PUT', body }),
  }
}

export const api = createApi()

/** 触发浏览器下载（导出 PDF 等） */
export function saveBlob(blob: Blob, filename: string): void {
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  a.click()
  URL.revokeObjectURL(url)
}
