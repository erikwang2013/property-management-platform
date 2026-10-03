// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
// TS 侧的设计 token 副本（图表等需要真实色值的地方用）；SCSS 侧见 _tokens.scss。

export const TOKENS = {
  primary: '#4F46E5',
  primaryDark: '#4338CA',
  primaryLight: '#6366F1',
  accent: '#F59E0B',
  success: '#10B981',
  warning: '#F59E0B',
  error: '#F43F5E',
  text: '#1F2937',
  textSecondary: '#6B7280',
  border: '#E8E9F2',
  sider: '#1E1B4B',
} as const;

/**
 * ECharts 通用配色。**顺序即按位置取色序列** —— 同一个分类在两端的图里必须同色。
 * 八位均由规范 §1.3 定死（2026-10-03 裁定）：前五位语义色 primary → primary-light →
 * warning → success → error（规范写 warning，与 accent 同值 #F59E0B）；
 * 第 6–8 位为扩展色 #8B5CF6 / #0EA5E9 / primaryDark，与 React 的 `chartColors` 逐位相同。
 */
export const CHART_PALETTE = [
  TOKENS.primary,
  TOKENS.primaryLight,
  TOKENS.warning,
  TOKENS.success,
  TOKENS.error,
  '#8B5CF6',
  '#0EA5E9',
  TOKENS.primaryDark,
] as const;
