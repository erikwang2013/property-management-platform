// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import { describe, expect, it } from 'vitest'
import { pageParams, readPage } from './paging'

/** 形状 A：业务模块（小区/房产/业主/账单/缴费/报修/投诉）的 Laravel 分页器响应 */
const paginatorBody = {
  data: [{ id: 'a1' }, { id: 'a2' }],
  current_page: 1,
  per_page: 20,
  total: 42,
  last_page: 3,
}

/** 形状 B：系统模块（用户/角色/系统配置/操作日志）的自定义分页响应 */
const flatBody = { list: [{ id: 'b1' }], total: 7, page: 2, limit: 20 }

describe('分页形状归一（A 分页器 / B 自定义）', () => {
  it('A：取 data.data 与 total', () => {
    expect(readPage<{ id: string }>(paginatorBody, 'paginator')).toEqual({
      rows: [{ id: 'a1' }, { id: 'a2' }],
      total: 42,
    })
  })

  it('B：取 data.list 与 total', () => {
    expect(readPage<{ id: string }>(flatBody, 'flat')).toEqual({ rows: [{ id: 'b1' }], total: 7 })
  })

  it('形状不匹配时不串味：用错形状读另一种响应得到空列表而非误读', () => {
    expect(readPage(flatBody, 'paginator').rows).toEqual([])
    expect(readPage(paginatorBody, 'flat').rows).toEqual([])
  })

  it('空/异常响应不抛异常，退化为空列表', () => {
    expect(readPage(null)).toEqual({ rows: [], total: 0 })
    expect(readPage({ total: 5 })).toEqual({ rows: [], total: 5 })
    expect(readPage('oops')).toEqual({ rows: [], total: 0 })
  })

  it('入参名随形状切换：A 用 page_size，B 用 limit（page 两者同名）', () => {
    expect(pageParams('paginator', 2, 20, { status: 1 })).toEqual({ page: 2, page_size: 20, status: 1 })
    expect(pageParams('flat', 2, 20, { status: 1 })).toEqual({ page: 2, limit: 20, status: 1 })
  })
})
