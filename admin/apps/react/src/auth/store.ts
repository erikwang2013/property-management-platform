// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import { create } from 'zustand'
import { persist, createJSONStorage } from 'zustand/middleware'

export interface AuthUser {
  id: string
  username: string
  real_name?: string
}

interface AuthState {
  accessToken: string | null
  refreshToken: string | null
  user: AuthUser | null
  setAuth: (payload: { access_token: string; refresh_token?: string; user?: AuthUser }) => void
  clear: () => void
}

/** 认证态是全局唯一的持久化状态；其余数据全部走 TanStack Query 缓存 */
export const useAuth = create<AuthState>()(
  persist(
    (set) => ({
      accessToken: null,
      refreshToken: null,
      user: null,
      setAuth: ({ access_token, refresh_token, user }) =>
        set((s) => ({
          accessToken: access_token,
          refreshToken: refresh_token ?? s.refreshToken,
          user: user ?? s.user,
        })),
      clear: () => set({ accessToken: null, refreshToken: null, user: null }),
    }),
    { name: 'property-admin-auth', storage: createJSONStorage(() => localStorage) },
  ),
)

export const isLoggedIn = () => Boolean(useAuth.getState().accessToken)
