// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
import { registerLocaleData } from '@angular/common';
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import localeZh from '@angular/common/locales/zh';
import {
  ApplicationConfig,
  LOCALE_ID,
  provideBrowserGlobalErrorListeners,
  provideZoneChangeDetection,
} from '@angular/core';
import { provideAnimationsAsync } from '@angular/platform-browser/animations/async';
import { provideRouter, withComponentInputBinding } from '@angular/router';
import { provideNzConfig } from 'ng-zorro-antd/core/config';
import { provideNzI18n, zh_CN } from 'ng-zorro-antd/i18n';
import { provideNzIcons } from 'ng-zorro-antd/icon';
import { NzModalService } from 'ng-zorro-antd/modal';

import { routes } from './app.routes';
import { authInterceptor } from './auth/auth.interceptor';
import { APP_ICONS } from './layout/menu';

// 中文语言数据必须在**应用配置**这一层注册，不能放 main.ts：
// ① NG-ZORRO 的 zh_CN 语言包 locale 是 'zh-cn'，日期/时间控件走 Angular `formatDate(date, fmt, 'zh-cn')`，
//    Angular 只认已注册的语言数据，缺了抛 NG0701（实测：/reports 日期区间面板整个渲染不出来）；
//    注册 `zh` 后 Angular 按父语言回落到 `zh-cn`。
// ② 测试（core.spec.ts）直接用 appConfig 的 providers，不走 main.ts —— 放这里两条路径才都覆盖得到，
//    交互冒烟也才有可能「摘掉注册就变红」。
registerLocaleData(localeZh);

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideZoneChangeDetection({ eventCoalescing: true }),
    provideRouter(routes, withComponentInputBinding()),
    provideHttpClient(withInterceptors([authInterceptor])),
    provideAnimationsAsync(),
    // 应用自身的日期/数字管道默认走中文（不设就是 en-US，与页面上到处是中文文案不一致）
    { provide: LOCALE_ID, useValue: 'zh-CN' },
    provideNzI18n(zh_CN),
    provideNzIcons(APP_ICONS),
    // NzModalService 的 ɵprov 没有 providedIn，只由 NzModalModule 提供（其 providers 就是 [NzModalService]，
    // 容器组件均为 standalone）。而 ConfirmService 是 providedIn:'root' 且在根作用域 inject 它，
    // 各页面自己 imports:[NzModalModule] 注册到的是路由级注入器，救不了根级解析 → 必须在这里提供。
    NzModalService,
    // NG-ZORRO 主题：primaryColor 与规格 §1 一致。
    // 注意：用的是 CSS 变量版样式表，实际生效的是 src/theme/_tokens.scss 里的 --ant-* 覆写；
    // 这里的配置保留给后续切运行时主题（dark / compact）时使用。
    provideNzConfig({
      theme: { primaryColor: '#4F46E5' },
      pagination: { nzShowSizeChanger: true },
    }),
  ],
};
