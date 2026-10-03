// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { api } from './client'

/** 后端两种分页形状：Laravel 分页器（data.data）与手写分页（data.list） */
export type PagingShape = 'paginator' | 'flat'

export interface PageResult<T> {
  rows: T[]
  total: number
}

export function readPage<T>(data: unknown, shape: PagingShape = 'paginator'): PageResult<T> {
  const d = (data ?? {}) as Record<string, unknown>
  const raw = shape === 'flat' ? d.list : d.data
  return { rows: Array.isArray(raw) ? (raw as T[]) : [], total: Number(d.total ?? 0) }
}

export function pageParams(
  shape: PagingShape,
  page: number,
  pageSize: number,
  filters: Record<string, unknown> = {},
): Record<string, unknown> {
  return shape === 'flat'
    ? { page, limit: pageSize, ...filters }
    : { page, page_size: pageSize, ...filters }
}

export function useList<T>(
  queryKey: readonly unknown[],
  path: string,
  params: Record<string, unknown>,
  shape: PagingShape = 'paginator',
) {
  return useQuery<PageResult<T>, Error>({
    queryKey: [...queryKey, params],
    queryFn: async () => readPage<T>(await api.get<unknown>(path, params), shape),
    placeholderData: keepPreviousData,
  })
}
