// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import { Empty } from 'antd'

/**
 * 宠物「小筑」接线点（admin/apps/README.md §2）
 * 资产是 docs/images/*.svg 的副本，改动源文件时需同步 public/ 下的两份。
 */
export const PET_MARK = '/favicon.svg'
export const PET_FULL = '/pet_xiaozhu.svg'

export function petGreeting(hour = new Date().getHours()): string {
  if (hour < 12) return '早安'
  if (hour < 18) return '午安'
  return '晚安'
}

/** 侧栏顶部 / 卡片标题里的小筑图标标记 */
export function PetMark({ size = 28 }: { size?: number }) {
  return <img src={PET_MARK} alt="小筑" width={size} height={size} style={{ borderRadius: size * 0.25, display: 'block' }} />
}

/** 小筑全身像（登录页主视觉 / 404） */
export function PetFull({ height = 160 }: { height?: number }) {
  return <img src={PET_FULL} alt="小筑" style={{ height, width: 'auto' }} />
}

/** 列表空态插图：用图标标记而不是默认的空盒子 */
export function EmptyState({ description = '暂无数据' }: { description?: string }) {
  // antd 6：imageStyle 已废弃，styles.image 与它同为 CSSProperties，逐字等价
  return <Empty image={PET_MARK} styles={{ image: { height: 56 } }} description={description} />
}
