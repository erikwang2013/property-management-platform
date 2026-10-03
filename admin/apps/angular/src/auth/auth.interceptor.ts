// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
import {
  HttpErrorResponse,
  HttpEvent,
  HttpInterceptorFn,
  HttpResponse,
} from '@angular/common/http';
import { inject } from '@angular/core';
import { Observable, catchError, finalize, map, shareReplay, switchMap, throwError } from 'rxjs';

import { AuthService } from './auth.service';

/** 后端 401 有两种形态：HTTP 401，或 HTTP 200 + body.code 401（AdminAuth 中间件走后者） */
function isUnauthorized(err: unknown): boolean {
  return err instanceof HttpErrorResponse && err.status === 401;
}

function unauthorizedError(url: string): HttpErrorResponse {
  return new HttpErrorResponse({ status: 401, statusText: 'Unauthorized', url });
}

/**
 * body.code === 401 在 HTTP 层是成功响应，必须自己翻成错误。
 * 原始请求与重放请求都要过这一道，否则「重放后仍 401」会被当成正常数据放行。
 */
function detectUnauthorized(url: string) {
  return map((event: HttpEvent<unknown>) => {
    if (
      event instanceof HttpResponse &&
      typeof event.body === 'object' &&
      event.body !== null &&
      (event.body as { code?: number }).code === 401
    ) {
      throw unauthorizedError(url);
    }
    return event;
  });
}

/** 只在途一次刷新：并发 401 共享同一个 Observable，其余请求等它 */
let refreshInFlight$: Observable<string> | null = null;

function refreshOnce(auth: AuthService): Observable<string> {
  refreshInFlight$ ??= auth.refresh().pipe(
    finalize(() => (refreshInFlight$ = null)),
    shareReplay({ bufferSize: 1, refCount: false }),
  );
  return refreshInFlight$;
}

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const auth = inject(AuthService);

  // 登录/刷新自身不做 Bearer 注入，也不参与重放
  const isAuthEndpoint = req.url.includes('/auth/login') || req.url.includes('/auth/refresh');
  const token = auth.accessToken();
  const authorized =
    token && !isAuthEndpoint
      ? req.clone({ setHeaders: { Authorization: `Bearer ${token}` } })
      : req;

  /** 带新 token 重放；重放后仍 401 说明刷新也没救回来，直接登出 */
  const replay = (t: string) =>
    next(req.clone({ setHeaders: { Authorization: `Bearer ${t}` } })).pipe(
      detectUnauthorized(req.url),
      catchError((err: unknown) => {
        if (isUnauthorized(err)) auth.sessionExpired();
        return throwError(() => err);
      }),
    );

  return next(authorized).pipe(
    detectUnauthorized(req.url),
    catchError((err: unknown) => {
      if (!isUnauthorized(err)) return throwError(() => err);
      // 刷新自身的 401：不再嵌套刷新，直接登出
      if (isAuthEndpoint) {
        auth.sessionExpired();
        return throwError(() => err);
      }
      // catchError 放在 switchMap 之前，只拦刷新失败；重放的错误由 replay 自己处理
      return refreshOnce(auth).pipe(
        catchError((refreshErr: unknown) => {
          auth.sessionExpired();
          return throwError(() => refreshErr);
        }),
        switchMap((newToken) => replay(newToken)),
      );
    }),
  );
};
