// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
import { HttpClient, HttpErrorResponse, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable, map, throwError, catchError } from 'rxjs';

import { API } from './api.config';
import {
  Envelope,
  ManualList,
  Option,
  PageResult,
  Paginator,
  Query,
} from './types';

/** 后端返回 code !== 0 时抛出，message 可直接展示 */
export class ApiError extends Error {
  constructor(
    message: string,
    readonly code: number,
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

/** 搜索区的空值不应作为查询参数发出（后端用 `!== null && !== ''` 判断，但没必要发脏参数） */
export function toParams(query: Query): HttpParams {
  let params = new HttpParams();
  for (const [key, value] of Object.entries(query)) {
    if (value === null || value === undefined || value === '') continue;
    params = params.set(key, String(value));
  }
  return params;
}

/** Laravel 分页器 → 归一化行集 */
export function fromPaginator<T>(p: Paginator<T>, fallbackSize: number): PageResult<T> {
  // 畸形响应在这里就拦下：`data` 不是数组还放行的话，`{}` 会一路进表格、到渲染期才炸成
  // 压缩后的 `t is not iterable` —— 那时错误已脱离 Observable，errorText 够不着，
  // 用户只看到空表 + 控制台报错。抛在管道内才会走到订阅方的 errorText → 人话 toast。
  if (p?.data != null && !Array.isArray(p.data)) throw new TypeError('分页响应 data 不是数组');
  return {
    rows: p?.data ?? [],
    total: p?.total ?? 0,
    page: p?.current_page ?? 1,
    pageSize: p?.per_page ?? fallbackSize,
  };
}

/** 手工 offset/limit 形状 → 归一化行集 */
export function fromManualList<T>(l: ManualList<T>, fallbackSize: number): PageResult<T> {
  if (l?.list != null && !Array.isArray(l.list)) throw new TypeError('列表响应 list 不是数组');
  return {
    rows: l?.list ?? [],
    total: l?.total ?? 0,
    page: l?.page ?? 1,
    pageSize: l?.limit ?? fallbackSize,
  };
}

@Injectable({ providedIn: 'root' })
export class ApiService {
  private readonly http = inject(HttpClient);

  /** 解包统一响应包；code !== 0 抛 ApiError（文案键 message / msg 都兜，见 Envelope 注释） */
  unwrap<T>(res: Envelope<T>): T {
    if (res.code !== 0) {
      throw new ApiError(res.message ?? res.msg ?? '请求失败', res.code);
    }
    return res.data;
  }

  get<T>(url: string, query: Query = {}): Observable<T> {
    return this.http
      .get<Envelope<T>>(url, { params: toParams(query) })
      .pipe(map((res) => this.unwrap(res)));
  }

  post<T>(url: string, body: unknown = {}): Observable<T> {
    return this.http.post<Envelope<T>>(url, body).pipe(map((res) => this.unwrap(res)));
  }

  put<T>(url: string, body: unknown = {}): Observable<T> {
    return this.http.put<Envelope<T>>(url, body).pipe(map((res) => this.unwrap(res)));
  }

  delete<T>(url: string, body: unknown = {}): Observable<T> {
    // 删除需带 password 确认，故走 body 而非纯路径
    return this.http.delete<Envelope<T>>(url, { body }).pipe(map((res) => this.unwrap(res)));
  }

  /** 分页列表（paginate() 形状） */
  getPage<T>(url: string, query: Query, page: number, pageSize: number): Observable<PageResult<T>> {
    return this.get<Paginator<T>>(url, { ...query, page, page_size: pageSize }).pipe(
      map((p) => fromPaginator(p, pageSize)),
    );
  }

  /** 分页列表（手工 offset/limit 形状：user / role / config / log） */
  getManualPage<T>(
    url: string,
    query: Query,
    page: number,
    pageSize: number,
  ): Observable<PageResult<T>> {
    return this.get<ManualList<T>>(url, { ...query, page, limit: pageSize }).pipe(
      map((l) => fromManualList(l, pageSize)),
    );
  }
  /** 文件下载（Excel/PDF 导出返回二进制，不走响应包解包） */
  download(url: string, body: unknown, filename: string): Observable<void> {
    return this.http
      .post(url, body, { responseType: 'blob' })
      .pipe(map((blob) => saveBlob(blob, filename)));
  }
}

/** 触发浏览器下载 */
export function saveBlob(blob: Blob, filename: string): void {
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

/** 把 HttpErrorResponse / ApiError 统一成可展示的文案 */
export function errorText(err: unknown): string {
  if (err instanceof ApiError) return err.message;
  if (err instanceof HttpErrorResponse) {
    const body = err.error as { message?: string; msg?: string } | null;
    return body?.message ?? body?.msg ?? `请求失败（HTTP ${err.status}）`;
  }
  // 内置异常（畸形响应触发的 `t is not iterable` 之类）是压缩后的内部信息，对用户没意义 ——
  // 换一句人话，真错误留给控制台。注意别一刀切成「所有 Error」：本项目有意抛出的
  // `new Error('两次输入的新密码不一致')` 这类普通 Error 要原样透传。
  if (err instanceof TypeError || err instanceof RangeError || err instanceof ReferenceError) {
    console.error(err);
    return '数据格式异常，请刷新重试';
  }
  return err instanceof Error ? err.message : '请求失败';
}

/** 把字典转成下拉选项 */
export function toOptions(dict: Record<string | number, string>): Option[] {
  return Object.entries(dict).map(([value, label]) => ({
    label,
    value: Number.isNaN(Number(value)) ? value : Number(value),
  }));
}

export { API };
