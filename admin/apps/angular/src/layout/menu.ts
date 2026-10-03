// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
// 导航按域分组（规格 §4），与 Flutter 版的平铺分组不同。
import type { IconDefinition } from '@ant-design/icons-angular';
import {
  AccountBookOutline,
  ApartmentOutline,
  DownloadOutline,
  FileDoneOutline,
  KeyOutline,
  PercentageOutline,
  ThunderboltOutline,
  WarningOutline,
  AppstoreOutline,
  BarChartOutline,
  CheckCircleOutline,
  ClockCircleOutline,
  CloseCircleOutline,
  DeleteOutline,
  DownOutline,
  EditOutline,
  ExclamationCircleOutline,
  ExportOutline,
  FileTextOutline,
  HomeOutline,
  IdcardOutline,
  LogoutOutline,
  MenuFoldOutline,
  MenuUnfoldOutline,
  MessageOutline,
  PlusOutline,
  ProfileOutline,
  ReloadOutline,
  SafetyCertificateOutline,
  SearchOutline,
  SettingOutline,
  SyncOutline,
  TeamOutline,
  ToolOutline,
  UserAddOutline,
  UserOutline,
  WalletOutline,
} from '@ant-design/icons-angular/icons';

export interface NavItem {
  label: string;
  path: string;
  icon: string;
}

export interface NavGroup {
  title: string;
  items: NavItem[];
}

export const NAV: NavGroup[] = [
  {
    title: '总览',
    items: [
      { label: '值班台', path: '/dashboard', icon: 'appstore' },
      { label: '报表中心', path: '/reports', icon: 'bar-chart' },
    ],
  },
  {
    title: '资产',
    items: [
      { label: '小区', path: '/communities', icon: 'home' },
      { label: '房产', path: '/rooms', icon: 'apartment' },
      { label: '业主', path: '/owners', icon: 'team' },
    ],
  },
  {
    title: '财务',
    items: [
      { label: '账单', path: '/fee-bills', icon: 'file-text' },
      { label: '缴费记录', path: '/fee-payments', icon: 'account-book' },
    ],
  },
  {
    title: '服务',
    items: [
      { label: '报修', path: '/repairs', icon: 'tool' },
      { label: '投诉', path: '/complaints', icon: 'message' },
    ],
  },
  {
    title: '系统',
    items: [
      { label: '用户', path: '/users', icon: 'user' },
      { label: '角色权限', path: '/roles', icon: 'safety-certificate' },
      { label: '系统配置', path: '/system', icon: 'setting' },
      { label: '操作日志', path: '/system/logs', icon: 'profile' },
      { label: '个人中心', path: '/system/profile', icon: 'idcard' },
    ],
  },
];

/** 左侧菜单用到 + 页面内零散用到的图标，按需注册（不整包引入 @ant-design/icons-angular） */
export const APP_ICONS: IconDefinition[] = [
  AppstoreOutline,
  DownloadOutline,
  FileDoneOutline,
  KeyOutline,
  PercentageOutline,
  ThunderboltOutline,
  WarningOutline,
  BarChartOutline,
  HomeOutline,
  ApartmentOutline,
  TeamOutline,
  FileTextOutline,
  AccountBookOutline,
  ToolOutline,
  MessageOutline,
  UserAddOutline,
  UserOutline,
  SafetyCertificateOutline,
  SettingOutline,
  ProfileOutline,
  IdcardOutline,
  MenuFoldOutline,
  MenuUnfoldOutline,
  SearchOutline,
  PlusOutline,
  LogoutOutline,
  DownOutline,
  ReloadOutline,
  DeleteOutline,
  EditOutline,
  ExportOutline,
  WalletOutline,
  ClockCircleOutline,
  ExclamationCircleOutline,
  CheckCircleOutline,
  CloseCircleOutline,
  SyncOutline,
];
