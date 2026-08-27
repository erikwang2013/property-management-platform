// installed.html（安装锁定页）E2E — 需 public/.installed 存在（由 run.sh 临时创建）
// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
'use strict';

const { BASE, report, shot, launch, summary } = require('./lib');

async function main() {
  const browser = await launch();
  const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });
  try {
    await page.goto(`${BASE}/install`, { waitUntil: 'domcontentloaded' });
    report('installed: 标题为「已安装」', (await page.title()) === '已安装 — 物业管理系统', await page.title());
    report('installed: 显示系统已安装文案', (await page.locator('h1').textContent()) === '系统已安装');
    report('installed: 提示删除 .installed 重新安装', (await page.locator('body').textContent()).includes('public/.installed'));
    report('installed: 存在「前往管理后台」按钮', await page.locator('a.btn-primary').count() === 1
      && (await page.locator('a.btn-primary').getAttribute('href')) === '/admin');
    await shot(page, 'fixed-installed-page.png');
  } catch (e) {
    report('执行异常(installed-page)', false, e.message);
  }
  const s = summary();
  await browser.close();
  process.exit(s.fail > 0 ? 1 : 0);
}

main();
