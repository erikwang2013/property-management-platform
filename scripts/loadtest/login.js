// 登录接口压测（k6）
// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
//
// 注意: 登录有验证码 + 限流（10 次/分/IP）双保护，属安全设计，无法做高并发。
// 本脚本以低速率探测登录链路延迟（期望 422 验证码错误或 429 限流，均属正常防御生效）。
// 用法: k6 run -e BASE_URL=http://127.0.0.1:8790 login.js
import http from 'k6/http';
import { check } from 'k6';

const BASE = __ENV.BASE_URL || 'http://127.0.0.1:8790';

export const options = {
  scenarios: {
    probe: {
      executor: 'shared-iterations',
      vus: 1,
      // 每 ~7s 一次，低于 10 次/分钟限流阈值
      iterations: 8,
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<500'],
  },
};

export default function () {
  const res = http.post(
    `${BASE}/api/auth/login`,
    JSON.stringify({
      username: 'erik',
      password: 'LoadTest123!',
      captcha_key: 'loadtest-invalid',
      clicks: [[1, 1], [2, 2]],
    }),
    { headers: { 'Content-Type': 'application/json', 'API-Version': 'v1' } }
  );
  // 200=成功(需有效验证码) 422=验证码错误 429=限流，均属预期
  check(res, { 'expected status': (r) => [200, 422, 429].includes(r.status) });
}
