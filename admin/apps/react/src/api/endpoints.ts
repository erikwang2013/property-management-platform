// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

/** 后端端点常量（与后端 config/route.php 核对过，base 由 dev server 代理到 :8787） */
export const EP = {
  // 认证
  captchaGenerate: '/api/v1/captcha/generate',
  login: '/api/v1/auth/login',
  refresh: '/api/v1/auth/refresh',

  // 仪表盘 / 报表
  dashboard: '/admin/dashboard',
  dashboardProperty: '/admin/dashboard/property',
  report: '/admin/report',
  exportPdf: '/admin/export/pdf',

  // 资产
  community: '/admin/community',
  room: '/admin/room',
  roomTree: '/admin/room/tree',
  owner: '/admin/owner',
  ownerBatchDestroy: '/admin/owner/batch/destroy',

  // 财务
  feeBill: '/admin/fee-bill',
  feeBillBatchGenerate: '/admin/fee-bill/batch/generate',
  feePayment: '/admin/fee-payment',
  feePaymentOffline: '/admin/fee-payment/offline',
  feeType: '/admin/fee-type',

  // 服务
  repair: '/admin/repair',
  complaint: '/admin/complaint',
  staff: '/admin/staff',

  // 系统
  user: '/admin/user',
  userBatchDestroy: '/admin/user/batch/destroy',
  userBatchStatus: '/admin/user/batch/status',
  role: '/admin/role',
  permission: '/admin/permission',
  config: '/admin/config',
  log: '/admin/log',
  profile: '/admin/profile',
  profilePassword: '/admin/profile/password',
  profileLogout: '/admin/profile/logout',
} as const

/** 子资源端点（hashid 在路径上） */
export const item = (base: string, id: string) => `${base}/${id}`
