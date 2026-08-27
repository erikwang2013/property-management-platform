// 首页/登录入口 E2E — 验证 / 路由、index/view.html 模板可达性与健康检查
// 结论先行：route.php 调用 Route::disableDefaultRoute()，/ 与 /index 均未注册路由；
// app/view/index/view.html 为 webman 默认 hello 模板，无任何路由渲染它（不可达）。
// 实际前端登录入口是 Flutter Web 应用（apps/flutter，独立构建产物）。
// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
'use strict';

const { BASE, report, shot, launch, summary } = require('./lib');

async function main() {
  const browser = await launch();
  const ctx = await browser.newContext({ viewport: { width: 1280, height: 800 } });
  const page = await ctx.newPage();
  const api = ctx.request;

  try {
    const root = await api.get(`${BASE}/`);
    const rootText = await root.text();
    report('首页 GET / 状态码', root.status() === 404, `实际 ${root.status()}（disableDefaultRoute，无 / 路由）`);
    report('首页不渲染 index/view.html 模板内容',
      !rootText.includes('hello') || rootText.includes('404'),
      `body 前 80 字符: ${rootText.replace(/\s+/g, ' ').slice(0, 80)}`);

    const idx = await api.get(`${BASE}/index/view.html`);
    report('GET /index/view.html 状态码', idx.status() === 404, `实际 ${idx.status()}（模板存在但无路由可达）`);

    await page.goto(`${BASE}/`, { waitUntil: 'domcontentloaded' });
    await shot(page, 'index-root-404.png');

    const health = await api.get(`${BASE}/health`);
    report('健康检查 GET /health 状态码', health.status() === 200, `实际 ${health.status()}`);
    const healthJson = JSON.parse(await health.text());
    report('健康检查返回 JSON 结构', healthJson && typeof healthJson === 'object', JSON.stringify(healthJson).slice(0, 200));
    await shot(page, 'health-200.png');

    // 安装向导入口（属于首页/登录链路的前置页面）
    const install = await api.get(`${BASE}/install`);
    report('安装向导 GET /install 状态码', install.status() === 200, `实际 ${install.status()}（当前 git 状态下为 500，见 wizard-e2e.js broken 模式）`);
  } catch (e) {
    report('执行异常(index-page)', false, e.message);
  }
  const s = summary();
  await browser.close();
  process.exit(s.fail > 0 ? 1 : 0);
}

main();
