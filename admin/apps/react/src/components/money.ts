// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

/**
 * 金额显示：**千分位 + 两位小数**（规范 §1.3，如 `1,250,000.00`）。
 * 单位写在标签/表头里（「应收合计（元）」「欠费金额(元)」），值上不挂 `¥`。
 * 非数值（畸形响应）出「—」，跟表格空值同一出口，不显示 `NaN`。
 *
 * 与 Angular `src/components/money.ts` 的 `formatMoney` 同实现（它先有）：此前三个页面各写一份
 * `Number(v ?? 0).toFixed(2)`，**都没有千分位** —— 统计卡看着有分组是 antd `Statistic` 自己加的，
 * 表格单元格与导出 PDF 里的金额就没有（同一页两种格式）。收敛到这一处，改格式只改这里。
 */
export function formatMoney(value: number | string | null | undefined): string {
  const n = Number(value ?? 0)
  if (!Number.isFinite(n)) return '—'
  return n.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}
