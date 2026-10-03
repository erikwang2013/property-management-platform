// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
import { HttpClient } from '@angular/common/http';
import { Injectable, computed, inject, signal } from '@angular/core';
import { Router } from '@angular/router';
import { Observable, map, tap } from 'rxjs';

import { API, ApiService } from '../api/api.service';

export interface AdminUser {
  id: string;
  username: string;
  real_name: string;
  avatar: string;
  email: string;
  phone: string;
  status: number;
  last_login_at: string | null;
  last_login_ip: string;
  created_at: string;
}

export interface LoginResult {
  access_token: string;
  refresh_token: string;
  user: AdminUser;
}

const ACCESS_KEY = 'xz_access_token';
const REFRESH_KEY = 'xz_refresh_token';
const USER_KEY = 'xz_user';

function readUser(): AdminUser | null {
  const raw = localStorage.getItem(USER_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as AdminUser;
  } catch {
    return null;
  }
}

@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly http = inject(HttpClient);
  private readonly api = inject(ApiService);
  private readonly router = inject(Router);

  private readonly _accessToken = signal<string | null>(localStorage.getItem(ACCESS_KEY));
  private readonly _user = signal<AdminUser | null>(readUser());

  readonly user = this._user.asReadonly();
  readonly isLoggedIn = computed(() => this._accessToken() !== null);
  readonly accessToken = this._accessToken.asReadonly();

  /** 登录页用：验证码 + 登录 */
  login(body: {
    username: string;
    password: string;
    captcha_key: string;
    clicks: { x: number; y: number }[];
  }): Observable<LoginResult> {
    return this.api.post<LoginResult>(API.login, body).pipe(tap((r) => this.persist(r)));
  }

  /** 用 refresh_token 换新 token；失败由调用方处理 */
  refresh(): Observable<string> {
    const refreshToken = localStorage.getItem(REFRESH_KEY);
    if (!refreshToken) throw new Error('无刷新令牌');
    return this.http
      .post<{ code: number; message?: string; data: LoginResult }>(API.refresh, {
        refresh_token: refreshToken,
      })
      .pipe(
        map((res) => {
          if (res.code !== 0) throw new Error(res.message ?? '刷新失败');
          this.persist(res.data);
          return res.data.access_token;
        }),
      );
  }

  /** 用户主动登出：通知后端拉黑 token，再清理本地 */
  logout(): void {
    this.http.post(API.logout, {}).subscribe({
      next: () => this.clear(),
      error: () => this.clear(),
    });
  }

  /** 会话失效（token 过期/刷新失败）：只清本地并跳登录，不再打后端 */
  sessionExpired(): void {
    this.clear();
  }

  setUser(user: AdminUser): void {
    this._user.set(user);
    localStorage.setItem(USER_KEY, JSON.stringify(user));
  }

  private persist(r: LoginResult): void {
    localStorage.setItem(ACCESS_KEY, r.access_token);
    localStorage.setItem(REFRESH_KEY, r.refresh_token);
    this._accessToken.set(r.access_token);
    this.setUser(r.user);
  }

  private clear(): void {
    localStorage.removeItem(ACCESS_KEY);
    localStorage.removeItem(REFRESH_KEY);
    localStorage.removeItem(USER_KEY);
    this._accessToken.set(null);
    this._user.set(null);
    void this.router.navigate(['/login']);
  }
}
