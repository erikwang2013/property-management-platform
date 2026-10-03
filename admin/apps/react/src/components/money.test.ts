// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import { describe, expect, it } from 'vitest'
import { formatMoney } from './money'

describe('formatMoney（规范 §1.3 金额格式）', () => {
  it('千分位 + 两位小数（表格单元格与导出 PDF 都吃这条）', () => {
    expect(formatMoney(1250000)).toBe('1,250,000.00')
    expect(formatMoney(3600.5)).toBe('3,600.50')
    expect(formatMoney('980000')).toBe('980,000.00') // 后端金额可能是字符串
    expect(formatMoney(0)).toBe('0.00')
  })

  it('畸形值出「—」，不显示 NaN', () => {
    expect(formatMoney('abc')).toBe('—')
    expect(formatMoney(NaN)).toBe('—')
    expect(formatMoney(Infinity)).toBe('—')
  })

  // 注意这是与 Angular 一致的既有行为（`value ?? 0`）：缺失的金额显示 0.00 而非 —，
  // 因为「没有值」和「零金额」在账单语境里无法区分，两端同处理。改这条要两端一起改。
  it('null/undefined 落成 0.00（两端同口径）', () => {
    expect(formatMoney(null)).toBe('0.00')
    expect(formatMoney(undefined)).toBe('0.00')
  })
})
