// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

/**
 * 后端统一响应包：code === 0 为成功。
 * 注意文案键有两种：控制器 `success()/fail()` 给 `message`，
 * 框架级异常（如非法 hashid）给 `msg` 且不带 message，故两者都标成可选。
 */
export interface Envelope<T> {
  code: number;
  message?: string;
  msg?: string;
  data: T;
}

/** Laravel 分页器对象（5 个 paginate() 端点返回） */
export interface Paginator<T> {
  data: T[];
  current_page: number;
  per_page: number;
  total: number;
  last_page: number;
}

/** 手工 offset/limit 端点（user / role / config / log）返回 */
export interface ManualList<T> {
  list: T[];
  total: number;
  page: number;
  limit: number;
}

/** 列表页统一消费的行集（两种后端形状归一后的结果） */
export interface PageResult<T> {
  rows: T[];
  total: number;
  page: number;
  pageSize: number;
}

export type QueryValue = string | number | boolean | null | undefined;

/** 列表查询参数（搜索区产出） */
export type Query = Record<string, QueryValue>;

export interface Option {
  label: string;
  value: string | number;
}
