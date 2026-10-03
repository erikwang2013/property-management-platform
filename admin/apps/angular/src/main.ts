// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
import { bootstrapApplication } from '@angular/platform-browser';

import { App } from './app';
// 中文语言数据（registerLocaleData(localeZh)）在 app.config.ts 里注册 —— 测试不走 main.ts，
// 放那边测试就拿不到，理由见 app.config.ts 的注释。
import { appConfig } from './app.config';

bootstrapApplication(App, appConfig).catch((err) => console.error(err));
