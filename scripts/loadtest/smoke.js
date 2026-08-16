// 部署后压测冒烟（k6）— 登录链路 + 可选鉴权业务接口
// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
//
// 低速率冒烟：验证部署后登录链路与关键业务接口可达，非性能压测。
// 登录有验证码 + 限流（10 次/分/IP），422/429 均属防御正常生效，视为链路可达。
// 业务接口需 TOKEN（部署服务器上用 mint-token.php 签发）；不传则只探测登录。
// 用法:
//   k6 run -e BASE_URL=http://host:8790 smoke.js
//   k6 run -e BASE_URL=http://host:8790 -e TOKEN=$(php mint-token.php) smoke.js
import http from 'k6/http';
import { check } from 'k6';

const BASE = __ENV.BASE_URL || 'http://127.0.0.1:8790';
const TOKEN = __ENV.TOKEN || '';

export const options = {
  scenarios: {
    smoke: {
      executor: 'constant-vus',
      vus: __ENV.VUS || 2,
      duration: __ENV.DURATION || '30s',
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<500'],
  },
};

export default function () {
  const login = http.post(
    `${BASE}/api/auth/login`,
    JSON.stringify({
      username: 'erik',
      password: 'LoadTest123!',
      captcha_key: 'loadtest-invalid',
      clicks: [[1, 1], [2, 2]],
    }),
    { headers: { 'Content-Type': 'application/json', 'API-Version': 'v1' } }
  );
  // 200=成功 422=验证码错误 429=限流，均证明登录链路可达
  check(login, { 'login reachable': (r) => [200, 422, 429].includes(r.status) });

  if (TOKEN) {
    const dash = http.get(`${BASE}/admin/dashboard`, {
      headers: { Authorization: `Bearer ${TOKEN}` },
    });
    check(dash, { 'dashboard 200': (r) => r.status === 200 });
  }
}
