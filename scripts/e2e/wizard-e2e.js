// 安装向导 E2E — 双模式运行
//   E2E_MODE=broken  当前 git 状态（模板在 app/view/install/）：验证 500 缺陷现象
//   E2E_MODE=fixed   模板临时位于 app/admin/view/install/：完整向导流程 + 截图
// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
'use strict';

const { BASE, report, shot, launch, summary } = require('./lib');

const MODE = process.env.E2E_MODE || 'broken';
const BASE_URL = `${BASE}/install`;

async function brokenMode(page, api) {
  // 当前状态：模板路径错位 → 全部向导页 500（真实缺陷）
  const r = await api.get(`${BASE}/install`);
  report('broken: GET /install 状态码', r.status() === 500,
    `实际 ${r.status()}（缺陷: 模板解析路径 app/admin/view/install/ 不存在）`);
  const rText = await r.text();
  report('broken: 500 响应体为被掩盖的 TypeError（MetricsCollector 返回类型过窄）',
    rText.includes('MetricsCollector') && rText.includes('TypeError'),
    '真实错误（模板 include 失败）被 MetricsCollector 类型错误掩盖');

  await page.goto(`${BASE}/install`, { waitUntil: 'domcontentloaded' });
  report('broken: 页面渲染出安装向导标题', false, '500 错误页，无向导内容');
  await shot(page, 'broken-step1-500.png');

  // POST 各步骤同样 500
  const p2 = await api.post(`${BASE}/install`, { form: { _step: '2' } });
  report('broken: POST _step=2 也 500', p2.status() === 500, `实际 ${p2.status()}`);
  const p3 = await api.post(`${BASE}/install`, { form: { _step: '3' } });
  report('broken: POST _step=3 也 500', p3.status() === 500, `实际 ${p3.status()}`);
}

async function fixedMode(page, api) {
  // ===== step1：渲染 =====
  await page.goto(`${BASE}/install`, { waitUntil: 'domcontentloaded' });
  report('fixed: step1 渲染成功(200)', page.url().startsWith(BASE_URL), page.url());
  report('fixed: step1 标题', (await page.title()) === '安装向导 — 物业管理系统', await page.title());
  report('fixed: step1 进度条第 1 步 active', await page.locator('.progress .step.active').textContent() === '1',
    `active=${await page.locator('.progress .step.active').textContent()}`);
  const fields = ['host', 'port', 'database', 'username', 'password'];
  for (const f of fields) {
    report(`fixed: step1 存在字段 #${f}`, await page.locator(`#${f}`).count() === 1);
  }
  report('fixed: step1 默认值 host=127.0.0.1', await page.locator('#host').inputValue() === '127.0.0.1',
    await page.locator('#host').inputValue());
  report('fixed: step1 默认值 port=3306', await page.locator('#port').inputValue() === '3306',
    await page.locator('#port').inputValue());
  report('fixed: step1 默认值 database=property_management', await page.locator('#database').inputValue() === 'property_management',
    await page.locator('#database').inputValue());
  report('fixed: step1 隐藏 _step=2', await page.locator('input[name=_step]').inputValue() === '2');
  report('fixed: step1 提交按钮文案', (await page.locator('button[type=submit]').textContent()).includes('下一步'));
  report('fixed: step1 页脚版权', (await page.locator('.footer').textContent()).includes('erik.xyz'));
  await shot(page, 'fixed-step1-render.png');

  // ===== step1：客户端 HTML5 必填校验（空表单点提交 → 浏览器拦截）=====
  await page.locator('#host').fill('');
  await page.locator('#port').fill('');
  await page.locator('#database').fill('');
  await page.locator('#username').fill('');
  await page.click('button[type=submit]');
  await page.waitForTimeout(500);
  report('fixed: step1 空表单被 HTML5 required 拦截（URL 未跳转/仍在本页）',
    page.url().startsWith(BASE_URL) && (await page.locator('#host').evaluate(el => el.validity.valueMissing)));
  await shot(page, 'fixed-step1-html5-required.png');

  // ===== step1：服务端校验（绕过 HTML5）=====
  const bad = await api.post(`${BASE}/install`, { form: { _step: '2', host: '', port: 'abc', database: '', username: '' } });
  const badText = await bad.text();
  report('fixed: step1 服务端校验错误返回 200 + 错误文案', bad.status() === 200 && badText.includes('请输入数据库主机地址'),
    badText.match(/请输入[^<]*/)?.[0] || '');
  report('fixed: step1 服务端校验提示端口', badText.includes('请输入有效的端口号'));
  report('fixed: step1 服务端校验提示库名/用户名', badText.includes('请输入数据库名') && badText.includes('请输入数据库用户名'));
  await page.goto(`${BASE}/install`, { waitUntil: 'domcontentloaded' });
  await page.locator('#host').fill('127.0.0.1');
  await page.locator('#port').fill('3306');
  await page.locator('#database').fill('property_management');
  await page.locator('#username').fill('root');
  await page.click('button[type=submit]');
  await page.waitForLoadState('domcontentloaded');
  report('fixed: step1 合法输入 → step2 渲染', (await page.title()) === '安装向导 — 物业管理系统'
    && (await page.locator('.subtitle').textContent()).includes('步骤 2/3'),
    await page.locator('.subtitle').textContent());
  report('fixed: step2 进度条第 1 步 done、第 2 步 active', await page.locator('.progress .step.done').count() === 1
    && (await page.locator('.progress .step.active').textContent()) === '2');
  report('fixed: step2 DB 摘要显示主机端口', (await page.locator('.db-summary').textContent()).includes('127.0.0.1:3306'));
  report('fixed: step2 隐藏域携带 DB 配置', await page.locator('input[name=host]').inputValue() === '127.0.0.1'
    && await page.locator('input[name=db_username]').inputValue() === 'root');
  report('fixed: step2 可选配置折叠(细节)存在', await page.locator('details summary').count() === 1);
  await shot(page, 'fixed-step2-render.png');

  // ===== step2：管理员账户服务端校验 =====
  const u = await api.post(`${BASE}/install`, { form: { _step: '3', host: 'h', port: '1', database: 'd', db_username: 'u', admin_username: 'ab', admin_password: 'weak', admin_password_confirm: 'different' } });
  const uText = await u.text();
  report('fixed: step2 用户名 <3 字符提示', uText.includes('管理员用户名至少3个字符'), uText.match(/管理员用户名[^<]*/)?.[0]);
  report('fixed: step2 密码强度提示(短/无大写/无数字/无特殊字符)', uText.includes('管理员密码长度需 8-32 位')
    && uText.includes('管理员密码需包含大小写字母、数字和特殊字符'));
  report('fixed: step2 两次密码不一致提示', uText.includes('两次输入的密码不一致'));
  await page.goto(`${BASE}/install`, { waitUntil: 'domcontentloaded' });
  await page.locator('#host').fill('127.0.0.1'); await page.locator('#port').fill('3306');
  await page.locator('#database').fill('property_management'); await page.locator('#username').fill('root');
  await page.click('button[type=submit]');
  await page.waitForLoadState('domcontentloaded');
  // 注: 'ab'/'abcdef' 会被 HTML5 minlength 拦截，用 form.submit() 绕过客户端校验直测服务端
  await page.locator('#admin_username').fill('ab');
  await page.locator('#admin_password').fill('abcdef');
  await page.locator('#admin_password_confirm').fill('abcdef');
  await page.evaluate(() => document.querySelector('form').submit());
  await page.waitForSelector('.error-msg', { timeout: 10000 });
  report('fixed: step2 服务端错误回显在页面', (await page.locator('.error-msg').count()) >= 1
    && (await page.locator('.error-msg').first().textContent()).includes('至少3个字符'),
    await page.locator('.error-msg').first().textContent());
  await shot(page, 'fixed-step2-validation-error.png');

  // ===== step2 → step3 确认页（不触发安装执行）=====
  await page.locator('#admin_username').fill('admin');
  await page.locator('#admin_password').fill('Admin@12345');
  await page.locator('#admin_password_confirm').fill('Admin@12345');
  await page.click('button[type=submit]');
  await page.waitForLoadState('domcontentloaded');
  report('fixed: 合法管理员 → step3 确认页', (await page.locator('.subtitle').textContent()).includes('步骤 3/3')
    && (await page.locator('.subtitle').textContent()).includes('确认安装'),
    await page.locator('.subtitle').textContent());
  report('fixed: step3 显示确认安装表单(未执行)', await page.locator('form button.btn-primary').count() === 1
    && (await page.locator('form button.btn-primary').textContent()).includes('确认安装'));
  report('fixed: step3 密码掩码显示', (await page.locator('.summary').textContent()).includes('密码') && (await page.locator('.summary').textContent()).includes('••'));
  report('fixed: step3 隐藏 _confirm=1', await page.locator('input[name=_confirm]').inputValue() === '1');
  report('fixed: step3 隐藏域保留管理员账户', await page.locator('input[name=admin_username]').inputValue() === 'admin');
  await shot(page, 'fixed-step3-confirm.png');

  // 执行安装（_confirm=1）会改写 .env + 建库 + 创建 .installed —— 禁测
  report('fixed: step3 执行安装(_confirm=1)', false, '环境不可测：会覆盖生产 .env、导入 install.sql、创建 public/.installed，按约束禁用');
}

async function main() {
  const { chromium } = require('playwright');
  const browser = await chromium.launch({ headless: true, args: ['--no-sandbox', '--disable-gpu'] });
  const ctx = await browser.newContext({ viewport: { width: 1280, height: 800 } });
  const page = await ctx.newPage();
  const api = ctx.request;

  try {
    if (MODE === 'broken') await brokenMode(page, api);
    else await fixedMode(page, api);
  } catch (e) {
    report(`执行异常(${MODE})`, false, e.message);
  }
  const s = summary();
  await browser.close();
  process.exit(s.fail > 0 ? 1 : 0);
}

main();
