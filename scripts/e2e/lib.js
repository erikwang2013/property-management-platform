// E2E 共享工具：浏览器启动 / 服务器探活 / 截图 / 断言
// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
'use strict';

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const BASE = process.env.E2E_BASE || 'http://127.0.0.1:8787';
const SHOT_DIR = path.join(__dirname, 'screenshots');

const results = [];
let passCount = 0;
let failCount = 0;

function report(name, ok, detail) {
  const status = ok ? 'PASS' : 'FAIL';
  if (ok) passCount++; else failCount++;
  results.push({ name, status, detail: detail || '' });
  console.log(`[${status}] ${name}${detail ? ' — ' + detail : ''}`);
}

async function shot(page, name) {
  fs.mkdirSync(SHOT_DIR, { recursive: true });
  const file = path.join(SHOT_DIR, name);
  await page.screenshot({ path: file, fullPage: true });
  return file;
}

async function launch() {
  return chromium.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-gpu'],
  });
}

function summary() {
  console.log(`\n===== 汇总: ${passCount} 通过 / ${failCount} 失败 =====`);
  return { pass: passCount, fail: failCount, results };
}

module.exports = { BASE, SHOT_DIR, report, shot, launch, summary, results };
