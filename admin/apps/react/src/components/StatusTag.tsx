// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import { Tag } from 'antd'

/** 各模块状态枚举 —— 取值以 docs/install.sql 的列 COMMENT 为准（后端控制器只透传数值），集中一处避免各页面各写一份 */
export type Option = { label: string; value: number; color?: string }

const opt = (label: string, value: number, color?: string): Option => ({ label, value, color })

// 枚举值一律以 docs/install.sql 的列 COMMENT 为准（后端控制器只透传数值、不给文案），两端口径同此。
// 别把「停用/正常」和「禁用/启用」混用：小区是前者（management_community），用户与角色是后者（management_admin_user / admin_role）。
//
// 颜色一律用 antd 预设名（success / warning / error / processing / default，渲染为「浅底彩字」），
// **不用 purple 这类自定义色相、也不按值轮换**（team-lead 2026-10-03 裁定，同 Angular `tags()`）：
// ① 状态类字典用五档语义，**同一状态两端同档位**；② 分类类字典（无褒贬含义：分类/用途/装修/性别/渠道…）
// 不传 color，落到 StatusTag 的 `default` 中性 —— 彩色轮换无信息量，且是两端分叉的主要来源。
export const STATUS_MAPS = {
  normal: [opt('停用', 0, 'error'), opt('正常', 1, 'success')],
  enable: [opt('禁用', 0, 'error'), opt('启用', 1, 'success')],
  room: [opt('空置', 0, 'default'), opt('已售', 1, 'success'), opt('出租', 2, 'processing'), opt('自住', 3, 'processing')],
  owner: [opt('迁出', 0, 'default'), opt('入住', 1, 'success')],
  bill: [
    opt('未缴', 0, 'default'),
    opt('部分缴', 1, 'warning'),
    opt('已缴', 2, 'success'),
    opt('逾期', 3, 'error'),
    opt('豁免', 4, 'default'),
  ],
  repair: [
    opt('待派单', 0, 'default'),
    opt('已派单', 1, 'processing'),
    opt('维修中', 2, 'warning'),
    opt('已完成', 3, 'success'),
    opt('已评价', 4, 'success'),
    opt('已取消', 5, 'default'),
  ],
  // 编号以 docs/install.sql:974 的 COMMENT 为准（`0=待处理 1=处理中 2=已处理 3=已回访 4=已关闭`）——
  // 此前本端与 Angular 按旧守卫读成 `1=待处理 2=处理中`，与 SQL 注释分叉；2026-10-03 后端改的是
  // **守卫**（handle 收 0 置 1、visit 收 1 置 3），编号回到 SQL：前端随之改回，别再按旧守卫推编号。
  complaint: [
    opt('待处理', 0, 'warning'),
    opt('处理中', 1, 'processing'),
    opt('已处理', 2, 'success'),
    opt('已回访', 3, 'success'),
    opt('已关闭', 4, 'default'),
  ],
  // install.sql:1007 `management_visitor.status`：0=已预约 1=已到访 2=已离开 3=已取消。
  // 本端目前只在报表页访客状态饼图里用它的**文案**（图例此前直接把枚举号当文案：「状态0」），
  // 档位按语义预置，与 Angular `dict.ts` 的 VISITOR_STATUS 同文案（它那份不带色）。
  visitor: [opt('已预约', 0, 'processing'), opt('已到访', 1, 'success'), opt('已离开', 2, 'default'), opt('已取消', 3, 'default')],
  urgency: [opt('普通', 1, 'default'), opt('紧急', 2, 'warning'), opt('非常紧急', 3, 'error')],
  // —— 以下均为分类类：不传颜色，一律中性 default（同 Angular 的 USAGE_TYPE_TAGS / REPAIR_CATEGORY_TAGS 等）——
  repairCategory: [
    opt('水电', 1),
    opt('门窗', 2),
    opt('墙面地面', 3),
    opt('管道', 4),
    opt('家电', 5),
    opt('电梯', 6),
    opt('公共设施', 7),
    opt('其他', 8),
  ],
  paymentMethod: [opt('微信', 1), opt('支付宝', 2), opt('现金', 3), opt('银行转账', 4), opt('刷卡', 5)],
  paymentChannel: [opt('在线', 1), opt('线下', 2)],
  usageType: [opt('住宅', 1), opt('商业', 2), opt('办公', 3), opt('仓储', 4)],
  decoration: [opt('毛坯', 1), opt('简装', 2), opt('精装', 3), opt('豪装', 4)],
  gender: [opt('未知', 0), opt('男', 1), opt('女', 2)],
  // 有褒贬，不属分类类，保留语义色（同 Angular COMPLAINT_TYPE_TAGS）
  // SQL：1=投诉 2=建议 3=表扬（此前本端写成 1=建议 2=投诉，是把两端搞反了，2026-10-03 修正）
  complaintType: [opt('投诉', 1, 'error'), opt('建议', 2, 'warning'), opt('表扬', 3, 'success')],
  // SQL：1=服务态度 2=环境卫生 3=安全管理 4=设施维护 5=噪音 6=违建 7=其他（分类类 → 中性）
  complaintCategory: [
    opt('服务态度', 1),
    opt('环境卫生', 2),
    opt('安全管理', 3),
    opt('设施维护', 4),
    opt('噪音', 5),
    opt('违建', 6),
    opt('其他', 7),
  ],
  // 0 实名 / 1 匿名：两值都是有效取值，别当空值渲染 —（同 Angular ANONYMOUS_TAGS，中性）
  anonymous: [opt('实名', 0), opt('匿名', 1)],
  permissionType: [opt('菜单', 1), opt('按钮', 2), opt('API接口', 3)],
} satisfies Record<string, Option[]>

/**
 * 操作来源端 → 展示名。取值见 docs/install.sql:560（`source` 列的八值枚举），
 * 后端 `OperationLog::detectSource()` 原样返回小写标识，别把 `harmonyos` 这类裸标识直接显示给用户。
 * 品牌名保留官方拼写（macOS/Windows/Linux 无通用中文名），有通行中文名的用中文 —— 与 Angular `LOG_SOURCES` 逐字一致，改一端要同步。
 */
export const LOG_SOURCES: Record<string, string> = {
  web: '网页端',
  ios: 'iOS',
  ipados: 'iPadOS',
  android: '安卓',
  harmonyos: '鸿蒙',
  windows: 'Windows',
  macos: 'macOS',
  linux: 'Linux',
}

/** 只用于筛选项（不需要颜色） */
export const toOptions = (list: Option[]) => list.map(({ label, value }) => ({ label, value }))

export function StatusTag({ value, list }: { value: number | null | undefined; list: Option[] }) {
  const hit = list.find((o) => o.value === value)
  if (!hit) return <Tag>{String(value ?? '—')}</Tag>
  // 未标 color 的一律 default 中性（分类类字典与「字典里没这个值」的兜底），与 Angular `?? 'default'` 同口径
  return <Tag color={hit.color ?? 'default'}>{hit.label}</Tag>
}

export const statusText = (value: number | null | undefined, list: Option[]) =>
  list.find((o) => o.value === value)?.label ?? '—'
