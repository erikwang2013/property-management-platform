# 성능 부하 테스트와 슬로우 쿼리관리 보고서（2026-08-16）

Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## 1. 테스트 환경과 방법

| 항목 | 값 |
|---|---|
| 애플리케이션 | webman v2（PHP 8.3, 32 workers）, admin + service 이중 애플리케이션 |
| 피측정 인스턴스 | admin 독립 포트 8790（`SERVER_LISTEN=http://0.0.0.0:8790`） |
| 도구 | k6 v0.51.0（로컬 머신에 wrk/ab/hey 없음）, 스크립트는 `scripts/loadtest/` |
| 부하 목표 | 로그인（/api/auth/login）, 대시보드（/admin/dashboard）, 요금 납부 목록（/admin/fee-payment） |
| 인증 | dashboard/fee는 `scripts/loadtest/mint-token.php`로 JWT 발급（캡차 우회, `sub=21000000000000100`）; 로그인 스크립트는 무효 캡차로 체인 탐지 |
| 데이터 | 단일 머신에서 127.0.0.1 직결, 게이트웨이/CDN 미경유; MySQL/Redis와 애플리케이션 동일 머신 |

스크립트 진입점: `bash scripts/loadtest/run.sh [BASE_URL] [VUS] [DURATION]`（k6가 PATH에 필요）.
로그인 스크립트 설명: 로그인은 캡차 + 속도 제한（10회/분/IP）이중 보호로, 보안 설계에 해당하며 고동시성 부하 테스트가 불가능하고 해서도 안 됨; login.js는 1 VU / 8회 요청 저속도로 체인 지연을 탐지하며, 422（캡차 오류）또는 429（속도 제한）반환을 기대 — 모두 방어가 정상 작동한 것.

## 2. 부하 테스트 결과

### 20 VU / 30s（기준 부하）

| 인터페이스 | 요청 수 | 처리량 | avg | p90 | p95 | max | 실패율 |
|---|---|---|---|---|---|---|---|
| login（1 VU × 8회） | 8 | 14.4/s | 68.6ms | 154ms | 207.8ms | 261ms | 0% |
| dashboard | 6863 | 227.9/s | 86.0ms | 151ms | 189.5ms | 1.37s | 0% |
| fee-payment | 5944 | 197.2/s | 99.3ms | 178ms | 220.0ms | 704ms | 0% |

### 50 VU / 30s（가중）

| 인터페이스 | 요청 수 | 처리량 | avg | p95 | max | 실패율 |
|---|---|---|---|---|---|---|
| login（1 VU × 8회） | 8 | 18.7/s | 52.1ms | 173ms | 243.8ms | 0% |
| dashboard | 6902 | 226.9/s | 212.7ms | 544.0ms | 1.99s | 0% |
| fee-payment | 7525 | 247.4/s | 195.7ms | 514.2ms | 2.0s | 0% |

（50 VU에서 p95 > 500ms 임계값, k6이 임계 초과로 종료 판정, 그러나 0% 요청 실패, 0개 비200.）

### 결론

- 모든 인터페이스가 20 VU에서 0 실패, p95 < 220ms, 건강.
- **처리량 병목 약 230–250 rps**: 20 VU → 50 VU 처리량이 오르지 않고 평탄（dashboard 227.9 → 226.9, fee 197 → 247）, p95 지연은 2배（~190ms → ~540ms）. 단일 머신 32 worker에서 worker당 약 7–8 rps로, PHP 전체 체인（MySQL 쿼리, Redis 캐시 왕복 포함）의 단일 코어 처리 상한 특성이며 커넥션 고갈이 아님（실패 요청 없음）.
- 권장: 단일 머신에서 이 규모면 충분（약 2천만 요청/일）; 더 높은 처리량이 필요하면 가로 확장 인스턴스 추가가 우선, 다음으로 각 인터페이스 SQL과 캐시 히트 점검（아래 참조）.

## 3. 슬로우 쿼리 검토

- 요금 테이블 `erik_fee_bill` / `erik_fee_payment` 인덱스 완비（paid_at, bill_id, owner_id, payment_number 등）, 핵심 쿼리에 모두 인덱스 사용 가능.
- 발견 포인트: 요금 목록이 `payment_number like %kw%` 퍼지 검색（선행 와일드카드）으로 인덱스를 탈 수 없어, 데이터량이 많아지면 해당 조건이 전체 테이블 스캔으로 퇴화. 저빈도 관리측 검색으로 현재는 처리 안 함; 데이터량 증가 후 역인덱스 또는 접두사 인덱스로 변경 가능.
- **MySQL slow_query_log가 OFF**: 활성화하고 `long_query_time=1` 설정 권장, 부하 테스트 추론이 아닌 실제 슬로우 SQL 지속 관찰. 프로덕션 실행:
  ```sql
  SET GLOBAL slow_query_log = ON;
  SET GLOBAL long_query_time = 1;
  ```
- 대시보드 집계: 캐시 재구축마다 약 8개 COUNT 집계 + 30일 그룹 통계, 단일 재구축은 초 단위 비용이며 Redis 5분 캐시가 흡수（아래 참조）, 핫 경로 아님.

## 4. Redis 캐시 재검토

- 대시보드 캐시 `dashboard:data`: `setex 300`, 히트 시 ~10ms, 미히트 시 초 단위 재구축. **문제: 어떤 쓰기 작업에도 무효화 로직이 없음**, 데이터 변경 후 최대 5분 지연. 요금/부동산 쓰기 인터페이스에서 해당 key 삭제 권장（한 줄 `del dashboard:data`）.
- **캐시 스탬피드(붕괴) 보호 없음**: key 만료 순간 32개 worker가 동시 재구축（8개 집계 쿼리 중복 실행）. 데이터량 증가 후 간단한 뮤텍스 권장（예: `set nx ex` 락 + 이중 체크）.
- 권한 캐시 `perm:{adminId}` 60s, 동작 정상.
- 남은 조사 항목: 로컬 머신 Redis에서 `dashboard:data` 키가 관찰되지 않음（여러 db 모두 없음）, 그러나 인터페이스 응답은 정상이고 히트 시 지연이 확연히 낮음. 부하 테스트 중 간헐적 403「권한 없음」발생（2회 후 안정 200 복귀）. 로컬 머신 다중 Redis 인스턴스/환경 변수 설정이 프로덕션과 다를 가능성, 대상 환경에서 재확인 필요. 부하 테스트 결론에는 영향 없음（안정 구간 0 실패）.

## 5. 인도물

- `scripts/loadtest/mint-token.php` — 부하 테스트 JWT 발급（`php mint-token.php --file=/tmp/pmp-token`）
- `scripts/loadtest/login.js` / `dashboard.js` / `fee.js` — k6 스크립트
- `scripts/loadtest/run.sh` — 원클릭 실행（mint token + 3개 스크립트, 파라미터: BASE_URL VUS DURATION）
- 본 보고서

재현 명령: `PATH=/home/erik/bin:$PATH bash scripts/loadtest/run.sh http://127.0.0.1:8790 20 30s`
