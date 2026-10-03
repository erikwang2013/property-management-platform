// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
// @vitest-environment jsdom

import { afterEach, describe, expect, it } from 'vitest'
import { cleanup, render } from '@testing-library/react'
import { LOG_SOURCES, STATUS_MAPS, StatusTag } from './StatusTag'

afterEach(() => cleanup())

/** 五档语义色是「两端同档位」的锚点：混进别的色相或实色名，这里就红 */
const TIERS = ['success', 'warning', 'error', 'processing', 'default']

const STATUS_KEYS = ['normal', 'enable', 'room', 'owner', 'bill', 'repair', 'complaint', 'visitor', 'urgency', 'complaintType'] as const
const CATEGORY_KEYS = [
  'repairCategory',
  'paymentMethod',
  'paymentChannel',
  'usageType',
  'decoration',
  'gender',
  'complaintCategory',
  'anonymous',
  'permissionType',
] as const

describe('StatusTag 徽标档位', () => {
  it('状态类字典逐值只挂五档语义色', () => {
    for (const key of STATUS_KEYS) {
      expect(STATUS_MAPS[key].length, key).toBeGreaterThan(0)
      for (const option of STATUS_MAPS[key]) {
        expect(TIERS, `${key}=${option.label}`).toContain(option.color)
      }
    }
  })

  it('分类类字典一律不挂色（落到 default 中性）', () => {
    for (const key of CATEGORY_KEYS) {
      for (const option of STATUS_MAPS[key]) {
        expect(option.color, `${key}=${option.label}`).toBeUndefined()
      }
    }
  })

  // 这套编号被改过两次（旧守卫读法 vs SQL 注释），钉死防回归：
  // 2026-10-03 后端改的是守卫，编号回到 install.sql:974 —— handle 收 0 置 1、visit 收 1 置 3
  it('投诉状态按 SQL 编号（0待处理 1处理中 2已处理 3已回访 4已关闭）', () => {
    expect(STATUS_MAPS.complaint.map((o) => [o.value, o.label])).toEqual([
      [0, '待处理'],
      [1, '处理中'],
      [2, '已处理'],
      [3, '已回访'],
      [4, '已关闭'],
    ])
  })

  it('按值渲染标签与预设色，字典外走中性兜底', () => {
    const { container } = render(<StatusTag value={2} list={STATUS_MAPS.room} />)
    const tag = container.querySelector('.ant-tag-processing')
    expect(tag?.textContent).toBe('出租')

    cleanup()
    // 字典里没有的值：原样显示 + 中性（不误配成某个语义色）
    const { container: miss } = render(<StatusTag value={99} list={STATUS_MAPS.room} />)
    expect(miss.textContent).toBe('99')
    expect(miss.querySelector('[class*="ant-tag-success"],[class*="ant-tag-error"]')).toBeNull()
  })

  it('0 是有效取值，不能渲染成破折号', () => {
    const { container } = render(<StatusTag value={0} list={STATUS_MAPS.anonymous} />)
    expect(container.textContent).toBe('实名')
  })
})

// 内联色名是第二处分叉源：antd 的 `gold`/`green` 与语义 token（warning/success）**不是同一个色值**
// （gold #FAAD14 vs colorWarning #F59E0B，green #52C41A vs colorSuccess #10B981），两端各写一种就永远对不齐 ——
// 登录页验证码提示条此前正是 gold/green，Angular 同位置是 warning/success（2026-10-03 对齐）。
// 扫源码文本而不是靠渲染：这类字面量散在页面里，只有全量扫才拦得住下一个。
describe('内联预设色名', () => {
  it('页面与组件里不得出现五档以外的 antd 预设色名', () => {
    const OFF_TIER = ['gold', 'purple', 'magenta', 'volcano', 'geekblue', 'cyan', 'lime', 'orange', 'blue', 'green', 'red', 'pink', 'yellow', 'violet']
    const sources = import.meta.glob('../{pages,components}/**/*.tsx', { query: '?raw', import: 'default', eager: true }) as Record<string, string>
    const hits: string[] = []
    for (const [file, text] of Object.entries(sources)) {
      if (file.includes('.test.')) continue
      for (const name of OFF_TIER) {
        if (text.includes(`'${name}'`) || text.includes(`"${name}"`)) hits.push(`${file}: ${name}`)
      }
    }
    expect(hits).toEqual([])
  })
})

describe('LOG_SOURCES', () => {
  // 取值见 docs/install.sql:560 的 `source` 列 COMMENT，八个一个不能少、也不许多
  it('来源端八值枚举全部有展示名（不显示裸小写标识）', () => {
    expect(Object.keys(LOG_SOURCES).sort()).toEqual(['android', 'harmonyos', 'ios', 'ipados', 'linux', 'macos', 'web', 'windows'])
    expect(LOG_SOURCES.harmonyos).toBe('鸿蒙')
    expect(LOG_SOURCES.web).toBe('网页端')
  })
})
