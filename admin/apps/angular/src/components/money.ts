// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

/**
 * 金额显示：**千分位 + 两位小数**（规范 §1.3，如 `1,250,000.00`）。
 * 单位写在标签/表头里（「应收合计（元）」「欠费金额(元)」），值上不挂 `¥`。
 * 非数值（畸形响应）出「—」，跟表格空值同一出口，不显示 `NaN`。
 */
export function formatMoney(value: number | string | null | undefined): string {
  const n = Number(value ?? 0);
  if (!Number.isFinite(n)) return '—';
  return n.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}
