// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
import { Routes } from '@angular/router';

import { authGuard, guestGuard } from './auth/auth.guard';

/** 13 个模块 / 16 条路由（规格 §5），除登录外全部懒加载 */
export const routes: Routes = [
  {
    path: 'login',
    canActivate: [guestGuard],
    loadComponent: () => import('./pages/login/login').then((m) => m.LoginComponent),
    title: '登录 · 物业管理平台',
  },
  {
    path: '',
    canActivate: [authGuard],
    loadComponent: () => import('./layout/layout').then((m) => m.LayoutComponent),
    children: [
      { path: '', pathMatch: 'full', redirectTo: 'dashboard' },
      {
        path: 'dashboard',
        loadComponent: () =>
          import('./pages/dashboard/dashboard').then((m) => m.DashboardComponent),
        title: '值班台 · 物业管理平台',
      },
      {
        path: 'reports',
        loadComponent: () => import('./pages/reports/reports').then((m) => m.ReportsComponent),
        title: '报表中心 · 物业管理平台',
      },
      {
        path: 'communities',
        loadComponent: () =>
          import('./pages/communities/communities').then((m) => m.CommunitiesComponent),
        title: '小区 · 物业管理平台',
      },
      {
        path: 'rooms',
        loadComponent: () => import('./pages/rooms/rooms').then((m) => m.RoomsComponent),
        title: '房产 · 物业管理平台',
      },
      {
        path: 'owners',
        loadComponent: () => import('./pages/owners/owners').then((m) => m.OwnersComponent),
        title: '业主 · 物业管理平台',
      },
      {
        path: 'fee-bills',
        loadComponent: () => import('./pages/fee-bills/fee-bills').then((m) => m.FeeBillsComponent),
        title: '账单 · 物业管理平台',
      },
      {
        path: 'fee-payments',
        loadComponent: () =>
          import('./pages/fee-payments/fee-payments').then((m) => m.FeePaymentsComponent),
        title: '缴费记录 · 物业管理平台',
      },
      {
        path: 'repairs',
        loadComponent: () => import('./pages/repairs/repairs').then((m) => m.RepairsComponent),
        title: '报修 · 物业管理平台',
      },
      {
        path: 'complaints',
        loadComponent: () =>
          import('./pages/complaints/complaints').then((m) => m.ComplaintsComponent),
        title: '投诉 · 物业管理平台',
      },
      {
        path: 'users',
        loadComponent: () => import('./pages/users/users').then((m) => m.UsersComponent),
        title: '用户 · 物业管理平台',
      },
      {
        path: 'roles',
        loadComponent: () => import('./pages/roles/roles').then((m) => m.RolesComponent),
        title: '角色权限 · 物业管理平台',
      },
      {
        path: 'system',
        loadComponent: () => import('./pages/system/system').then((m) => m.SystemComponent),
        title: '系统配置 · 物业管理平台',
      },
      {
        path: 'system/logs',
        loadComponent: () => import('./pages/system/logs').then((m) => m.LogsComponent),
        title: '操作日志 · 物业管理平台',
      },
      {
        path: 'system/profile',
        loadComponent: () => import('./pages/system/profile').then((m) => m.ProfileComponent),
        title: '个人中心 · 物业管理平台',
      },
    ],
  },
  {
    path: '**',
    loadComponent: () => import('./pages/not-found/not-found').then((m) => m.NotFoundComponent),
    title: '页面不存在 · 物业管理平台',
  },
];
