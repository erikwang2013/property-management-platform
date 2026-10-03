// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
// 端点常量：与 admin/app/admin/controller/*.php 及 config/route.php 核对过。
// 开发环境由 proxy.conf.json 把 /api 与 /admin 反代到 http://localhost:8787。

export const API = {
  // 认证
  captchaGenerate: '/api/v1/captcha/generate',
  login: '/api/v1/auth/login',
  refresh: '/api/v1/auth/refresh',
  logout: '/admin/profile/logout',

  // 个人中心
  profile: '/admin/profile',
  profilePassword: '/admin/profile/password',

  // 仪表盘
  dashboard: '/admin/dashboard',
  dashboardProperty: '/admin/dashboard/property',

  // 报表
  report: '/admin/report',
  exportPdf: '/admin/export/pdf',

  // 小区
  community: '/admin/community',

  // 楼栋 / 单元 / 户型（房产表单的下拉数据源）
  building: '/admin/building',
  unit: '/admin/unit',
  roomType: '/admin/room-type',

  // 费用类型（账单表单 / 批量生成的下拉数据源）
  feeType: '/admin/fee-type',

  // 房产
  room: '/admin/room',
  roomTree: '/admin/room/tree',

  // 业主
  owner: '/admin/owner',
  ownerBatchDestroy: '/admin/owner/batch/destroy',

  // 账单
  feeBill: '/admin/fee-bill',
  feeBillBatchGenerate: '/admin/fee-bill/batch/generate',

  // 缴费
  feePayment: '/admin/fee-payment',
  feePaymentOffline: '/admin/fee-payment/offline',

  // 员工名册（报修派单的人员下拉：hashid + name）
  staff: '/admin/staff',

  // 报修
  repair: '/admin/repair',
  repairDetail: (id: string) => `/admin/repair/${id}`,
  repairAssign: (id: string) => `/admin/repair/${id}/assign`,
  repairProgress: (id: string) => `/admin/repair/${id}/progress`,

  // 投诉
  complaint: '/admin/complaint',
  complaintDetail: (id: string) => `/admin/complaint/${id}`,
  complaintHandle: (id: string) => `/admin/complaint/${id}/handle`,
  complaintVisit: (id: string) => `/admin/complaint/${id}/visit`,

  // 用户
  user: '/admin/user',
  userBatchStatus: '/admin/user/batch/status',

  // 角色 / 权限
  role: '/admin/role',
  permission: '/admin/permission',

  // 系统配置
  config: '/admin/config',

  // 操作日志
  log: '/admin/log',
} as const;
