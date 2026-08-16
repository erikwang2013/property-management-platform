// 仪表盘接口压测（k6）— GET /admin/dashboard
// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
//
// 用法: k6 run -e BASE_URL=http://127.0.0.1:8790 -e TOKEN=$(php mint-token.php) dashboard.js
import http from 'k6/http';
import { check } from 'k6';

const BASE = __ENV.BASE_URL || 'http://127.0.0.1:8790';
const TOKEN = __ENV.TOKEN;

export const options = {
  scenarios: {
    load: {
      executor: 'constant-vus',
      vus: __ENV.VUS || 20,
      duration: __ENV.DURATION || '30s',
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<500'],
  },
};

export default function () {
  const res = http.get(`${BASE}/admin/dashboard`, {
    headers: { Authorization: `Bearer ${TOKEN}` },
  });
  check(res, { '200 ok': (r) => r.status === 200 });
}
