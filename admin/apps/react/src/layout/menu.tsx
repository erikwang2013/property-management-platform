// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import type { ReactNode } from 'react'
import {
  AccountBookOutlined,
  BarChartOutlined,
  DashboardOutlined,
  FileSearchOutlined,
  HomeOutlined,
  IdcardOutlined,
  MessageOutlined,
  SafetyCertificateOutlined,
  SettingOutlined,
  ShopOutlined,
  TeamOutlined,
  ToolOutlined,
  UserOutlined,
  WalletOutlined,
} from '@ant-design/icons'

export interface NavItem {
  path: string
  label: string
  icon: ReactNode
}

export interface NavGroup {
  label: string
  items: NavItem[]
}

/** 导航按域分组（admin/apps/README.md §4） */
export const NAV_GROUPS: NavGroup[] = [
  {
    label: '总览',
    items: [
      { path: '/dashboard', label: '值班台', icon: <DashboardOutlined /> },
      { path: '/reports', label: '报表中心', icon: <BarChartOutlined /> },
    ],
  },
  {
    label: '资产',
    items: [
      { path: '/communities', label: '小区', icon: <ShopOutlined /> },
      { path: '/rooms', label: '房产', icon: <HomeOutlined /> },
      { path: '/owners', label: '业主', icon: <TeamOutlined /> },
    ],
  },
  {
    label: '财务',
    items: [
      { path: '/fee-bills', label: '账单', icon: <AccountBookOutlined /> },
      { path: '/fee-payments', label: '缴费记录', icon: <WalletOutlined /> },
    ],
  },
  {
    label: '服务',
    items: [
      { path: '/repairs', label: '报修', icon: <ToolOutlined /> },
      { path: '/complaints', label: '投诉', icon: <MessageOutlined /> },
    ],
  },
  {
    label: '系统',
    items: [
      { path: '/users', label: '用户', icon: <UserOutlined /> },
      { path: '/roles', label: '角色权限', icon: <SafetyCertificateOutlined /> },
      { path: '/system/config', label: '系统配置', icon: <SettingOutlined /> },
      { path: '/system/logs', label: '操作日志', icon: <FileSearchOutlined /> },
      { path: '/system/profile', label: '个人中心', icon: <IdcardOutlined /> },
    ],
  },
]

/** 路由路径 → 页面标题（浏览器标题：<当前页> · 物业管理平台） */
export const PAGE_TITLES: Record<string, string> = Object.fromEntries(
  NAV_GROUPS.flatMap((g) => g.items.map((i) => [i.path, i.label])),
)
