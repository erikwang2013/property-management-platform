// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import type { ThemeConfig } from 'antd'

/** 小筑设计语言色板（admin/apps/README.md §1.1）—— 与 Flutter/Angular 版共用同一组值 */
export const colors = {
  primary: '#4F46E5',
  primaryDark: '#4338CA',
  primaryLight: '#6366F1',
  accent: '#F59E0B',
  success: '#10B981',
  warning: '#F59E0B',
  error: '#F43F5E',
  bgLayout: '#F5F6FA',
  siderBg: '#1E1B4B',
  siderActive: '#FBBF24',
  text: '#1F2937',
  textSecondary: '#6B7280',
  border: '#E5E7EB',
} as const

/** 骨架尺寸（§1.3） */
export const layout = {
  siderWidth: 240,
  siderCollapsedWidth: 64,
  headerHeight: 56,
  contentPadding: 24,
  rowHeight: 48,
} as const

/** 卡片阴影：实际生效点在 index.css 的 :root 变量（antd Card 不消费 boxShadow token） */
export const cardShadow = 'var(--card-shadow)'

/**
 * 图表配色。**顺序即 ECharts 的按位置取色序列**（同一个分类在两端的饼图里必须同色），
 * 八位均由规范 §1.3 定死（2026-10-03 裁定）：前五位语义色
 * primary → primary-light → warning → success → error（§1.3 写作 warning，与 accent 同值 #F59E0B），
 * 第 6–8 位为扩展色 #8B5CF6 / #0EA5E9 / primary-dark，两端逐位相同；不做 5 色循环截断。
 */
export const chartColors = [
  colors.primary,
  colors.primaryLight,
  colors.accent,
  colors.success,
  colors.error,
  '#8B5CF6',
  '#0EA5E9',
  colors.primaryDark,
]

export const fontFamily = '-apple-system, "PingFang SC", "Microsoft YaHei", "Segoe UI", Roboto, sans-serif'

/** Ant Design token 覆写（§1.2：比默认更圆的圆角 + 靛蓝主色） */
export const antdTheme: ThemeConfig = {
  token: {
    colorPrimary: colors.primary,
    colorInfo: colors.primary,
    colorSuccess: colors.success,
    colorWarning: colors.warning,
    colorError: colors.error,
    colorTextBase: colors.text,
    // antd 由 colorTextBase 派生出的 colorText 带 0.88 alpha（白底合成 ≈ #3A434F，比规范 §1.1 的 #1F2937 浅一档），
    // 且组件正文走的是 colorText 而非 colorTextBase —— 只设 Base 会让 body 实心、组件内正文发虚，与 Angular 分叉。此处锁实心。
    colorText: colors.text,
    colorTextSecondary: colors.textSecondary,
    // Typography.Text type="secondary" 读的是 Description 这一档，只设 Secondary 会回落成 antd 派生色（规范 §1.3）
    colorTextDescription: colors.textSecondary,
    colorBgLayout: colors.bgLayout,
    colorBorder: colors.border,
    borderRadius: 8,
    borderRadiusLG: 12,
    borderRadiusSM: 6,
    fontFamily,
    // 正文行高 24px（规范 §1.3 的 48px 表格行高 = 24 内容 + 2×11.5 内边距 + 1 分隔线）
    lineHeight: 24 / 14,
    boxShadowTertiary: cardShadow,
  },
  components: {
    Layout: { siderBg: colors.siderBg, headerBg: '#FFFFFF', headerHeight: layout.headerHeight },
    Menu: {
      darkItemBg: colors.siderBg,
      darkSubMenuItemBg: 'transparent',
      darkItemColor: 'rgba(255,255,255,.72)',
      darkItemHoverBg: 'rgba(255,255,255,.08)',
      darkItemSelectedBg: 'rgba(251,191,36,.14)',
      darkItemSelectedColor: colors.siderActive,
      itemBorderRadius: 8,
    },
    Card: { borderRadiusLG: 12 },
    // 11.5 = (48 行高 − 24 行内内容 − 1 分隔线) / 2；size="middle" 的表格读 MD 变体
    Table: { cellPaddingBlock: 11.5, cellPaddingBlockMD: 11.5, headerBg: '#FAFAFC' },
    // 规范 §1.2：输入/按钮一律 8px（不随 size 变 12/6）；标签、徽标仍是全局 SM 的 6px
    Button: { borderRadius: 8, borderRadiusLG: 8, borderRadiusSM: 8 },
    Input: { borderRadius: 8, borderRadiusLG: 8, borderRadiusSM: 8 },
  },
}
