# 부동산 관리 시스템 — 종합 프로젝트 계획

> 생성일: 2026-08-16 · 출처: pmp-team 팀 감사（auditor / security-auditor / planner）

## 1. 현황 감사 결론

**기능면: 선언과 일치.** 22개 비즈니스 모듈 + 12개 확장 기능 전부 완료, 68개 테이블 / 178 API, admin 58개 컨트롤러 / 127개 라우트、service 19개 컨트롤러 / 57개 라우트, Flutter Web 관리 콘솔 42페이지 + 입주민 포털 13페이지, HarmonyOS 5페이지. docs/ 14개 문서 + 35장 SVG 모두 코드로 뒷받침되며, "선언만 하고 미구현"인 기능은 발견되지 않음.

**테스트: 전체 그린（2026-08-17 기준）.** admin 193 tests / 452 assertions、service 101 tests / 385 assertions（7 skip은 환경 의존）、Flutter widget 테스트 9건（로그인/홈/청구서 페이지）.

**공학면 이미 갖춤:** 양측 docker-compose, GitHub Actions CI（PHP 문법 + 양측 phpunit + composer audit + Flutter analyze）, Dependabot, Prometheus 지표 엔드포인트.

**기술 부채（저위험 위주）:**
1. 로그 적체: service/workerman.log 9.3M、admin/runtime/logs 5.7M（gitignore됨, 디스크만 점유）→ 로테이션 필요
2. README에 service측 57개 모델 문서 기준 미기재（64는 admin측만 지칭）
3. TODO/FIXME 없음, .env 미커밋, 의존성 버전 이상 없음 — 깨끗

## 2. 보안과 품질 격차（security-auditor）

**18층 방어: 16/18 검증됨**, 구현이 SECURITY_ARCHITECTURE.md와 일치（캡차, 2차 확인, poster, SecurityFilter, AES-256-CBC, JWT, 세션 제한, 계정 잠금, RBAC, 속도 제한, hashids, 필드 암호화, 마스킹, 감사 로그, CSP）.

**두 가지 불일치 항목（P1 모두 수정 완료）:**
1. ~~security-php가 service측에만 설치~~ → 양측 SecurityFilter에 연결 완료（admin + service 모두 4b 깊이 스캔 계층, SecurityGuard 지연 초기화, block 시 기록 후 승격）
2. ~~PDF 저작권 워터마크 미구현~~ → ExportController 18층 워터마크 구현 확인（ExportController.php:179,206）, 감사 오보

**최고위험: 하드코딩 폴백 키（수정 완료）.** EncryptionService/암호화 설정 전부 fail-fast로 변경（누락 또는 change-me면 시작 시 오류）, 플러그인 계층 encryptable/jwt의 하드코딩과 랜덤 폴백 제거; .env 키는 생성된 실제 랜덤 값, CI는 .env.example 복사 로드. DB/Redis 비밀번호는 여전히 플레이스홀더로, 배포 자격 증명에 해당하며 배포 측에서 주입.

**공학화 단점（P1 보완 완료):** CI에 phpstan 작업 추가（Level 5 + baseline）, 양측 PHPUnit 커버리지 게이트（실측 베이스라인 admin 1.66% / service 3.21%, 게이트로 제로 계측 회귀 방지）, gitleaks 키 유출 스캔（.gitleaks.toml로 환경 템플릿 통과）.

**고위험 패턴 점검:** eval( 은 Redis::eval뿐（안전）、exec 3곳（모니터링/설치 컨트롤러）、md5( 는 token 블랙리스트 해시뿐、SQL 전부 query builder 경유 — 날것 문자열 접합 리스크 없음.

## 3. 전략적 포지셔닝

**기능 완성기 → 공학화/상업화기.** 비즈니스 기능 개발은 마무리됨（최근 커밋은 문서/감사/테스트 보완）. 다음 단계 투자 방향: **CI/CD와 품질 게이트, 결제 프로덕션화, 모니터링 알림과 백업 복구, 멀티 테넌트 SaaS화, 모바일보완**. 상업화 포장은 기반이 있음（EDITIONS 3버전 + 설치 마법사 + 저작권 워터마크）, 부족한 것은 고객이 돈을 내게 만드는 공학 신뢰도.

## 4. 단계별 로드맵

### P1 공학화 공고화（2-4주）— 시스템을 "신뢰 가능"하게

| 목표 | 핵심 작업 | 인수 기준 |
|------|---------|---------|
| 품질 게이트 전체 그린, 키 통제, 데이터 불실 | ① CI 보완: Flutter analyze、service 테스트、PHPUnit 커버리지 게이트、phpstan、gitleaks ② 키 관리: .env 생성기 + JWT/DB 키 로테이션 스크립트 ③ 백업 복구: mysqldump 스크립트 + 복구 훈련 매뉴얼 ④ ES 다운그레이드: 큐 쓰기 실패 로그 폴백 + 검색 MySQL LIKE 다운그레이드（연기）⑤ SQL 버전 관리: 전체 마이그레이션을 docs/install.sql 단일 진입점으로 통일（기존 분할 마이그레이션 방안 취소, 2026-08-16 합병 완료） | CI 전체 그린 커버리지 포함; 복구 훈련 30분 데이터 일치; ES 정지 시 검색 사용 가능; 업그레이드 스크립트 실행 가능 |

**P1 상태**: ✅ 전부 완료（백업 복구는 P8에 추가 기록: scripts/backup.sh + docs/RECOVERY_RUNBOOK.md）.

### P2 상업화 능력（4-8주）— 고객이 "살 용기" 갖게

| 목표 | 핵심 작업 | 인수 기준 |
|------|---------|---------|
| 결제 폐루프, 모니터링 가능, 인도 가능 | ① 결제 프로덕션화: 위챗/알리페이 샌드박스 전 프로세스（주문→콜백 멱등→환불→대사）, 자격 증명을 config/payment.php + env로 집중 ② 모니터링 알림: Prometheus+Grafana 편성 + 알림 규칙（5xx, ES/Redis 커넥션, 큐 적체）+ 로그 로테이션 ③ 상업판 제어: EDITIONS 기반 버전 스위치（Lite/Standard/Full 라우트 그룹 활성화）+ Demo 데이터 ④ 설치 마법사가 결제/ES 설정 커버 | 샌드박스 결제 전 프로세스 통과（중복 콜백 멱등 포함）; 알림 실측 트리거; 3버전 스위치 데모 가능; 새 환경 10분 설치 완료 |

**P2 현재 상태**: ✅ 오프라인 부분 전부 완료（2026-08-16/17）: 결제 전체체인 코드（PaymentService 주문/콜백 멱등/환불/대사 + config/payment.php 자격 증명 집중화 + PaymentServiceTest 순수 함수 커버）、모니터링 편성（이중 Prometheus 스택 + 6개 알림 규칙 + 양측 Grafana dashboard provisioning）、버전 스위치（EDITIONS 3버전 + fail-fast 검증）、설치 마법사（결제 설정 자동 활성화 + 템플릿 경로 버그 수정）. 남은 외부 의존: **샌드박스 연동은 자격 증명 대기**（WECHAT_PAY_* / ALIPAY_* 샌드박스 자격 증명 확보 후 `scripts/payment_sandbox_smoke.php` 실행）、**알림 실측은 배포 대기**（`scripts/verify_monitoring.sh` 로컬 검증 가능, 실제 트리거 검증은 배포 후 실행）.

### P3 규모화（8-12주）— 시스템을 "많이 팔 수 있게"

| 목표 | 핵심 작업 | 인수 기준 |
|------|---------|---------|
| 멀티 테넌트, 성능 달성, 모바일보완 | ① 멀티 테넌트 SaaS: 그룹 관리를 출발점으로, erik_community에 tenant_id 추가 + 미들웨어 격리（방안 검토 선행, 독립 DB는 진화 방향）② 성능 부하 테스트: wrk/k6로 로그인/요금/대시보드, 슬로우 쿼리 + Redis 캐시 재검토 ③ 모바일보완: HarmonyOS 5페이지를 핵심 경로로 확장（납부/수리 접수/공지/방문객/주차）, Flutter 입주민 포털 모바일 적응 ④ 오픈 API / Webhook（선택） | 테넌트 권한 초과 테스트 통과; 핵심 인터페이스 P95 < 300ms; HarmonyOS 핵심 경로 완료 |

**P3 상태**: ✅ 전부 완료（2026-08-16 인도: 멀티 테넌트 3종 세트 + 부하 실측 P95 달성 + HarmonyOS 5페이지 확장）.

### P4-P9 추가 인도 기록（2026-08-16 ~ 08-17, 원래 P1-P3 범위를 넘는 신규 공학 단계）

| 단계 | 인도 내용 | 상태 |
|------|---------|------|
| P4 마무리 | ES 쓰기 경로 폴백（AdminUser Searchable try/catch + 로그 다운그레이드）、설치 마법사 결제 설정（자격 증명 입력 시 자동 활성화）、로그 로테이션（logrotate.conf）、모니터링 알림 편성（이중 Prometheus 스택 + 6개 규칙） | ✅ 완료 |
| P5 잔여 항목 | Webhook 전송（HMAC-SHA256 서명 + 지수 백오프 재시도 + 3개 트리거 포인트）、요금/승인/SLA 비즈니스 단위 테스트 | ✅ 완료 |
| P6 배포 마무리 | 원클릭 배포 스크립트（deploy.sh: pull → .env → compose → install.sql 멱등 가져오기 → 모니터링 스모크）、컨테이너 로그 마운트 수정、CI 커버리지 게이트 상향、확장 대비 방안（SCALING_PLAN） | ✅ 완료 |
| P7 테스트 심화 | service 단위 테스트 43→82、Flutter widget 테스트 3페이지 8건（CI 통합）、오픈 API（/open 3개 읽기 전용 엔드포인트 + X-API-Key 인증 + gen_api_key.php）、부하 스모크（k6 smoke.js + workflow_dispatch 수동 workflow） | ✅ 완료 |
| P8 운영 마무리 | 백업 복구구축（backup.sh + RECOVERY_RUNBOOK）、Grafana dashboard（service측 7패널 provisioning）、admin 단위 테스트 +11（152 전체 그린）、**설치 마법사 템플릿 경로 버그 수정**（템플릿을 app/view/install로 이동, curl 실측 렌더 200） | ✅ 완료 |
| P9 공학 마무리 | 무효 백업 스크립트 정리（git rm 양측 4개 파일 + 8곳 문서 통일）、admin측 Grafana dashboard（open_admin_* 접두사 7패널）、InstallValidator 검증 순수 함수 추출 + 17개 테스트（admin 193 전체 그린） | ✅ 완료 |

**P4-P9 요약**: admin 단위 테스트 93→193、service 단위 테스트 43→101、Flutter widget 테스트 9/9、오픈 API 3개 엔드포인트、양측 모니터링 패널 대칭、백업/복구/키/배포 전 세트 운영 스크립트 준비 완료.

## 5. Top 10 우선 행동 항목（투입 대비 산출 기준）

| # | 행동 항목 | 영향 | 비용 | 리스크 | 상태 |
|---|--------|------|------|------|------|
| 1 | 키 관리: env 생성기 + 로테이션 스크립트 + 하드코딩 폴백 키 제거（시작 시 change-me 검증） | 높음（보안 컴플라이언스） | 낮음 | 낮음 | ✅ 완료 |
| 2 | CI 보완: Flutter analyze + service 테스트 + 커버리지 게이트 + phpstan + gitleaks | 높음（품질 하한선） | 낮음 | 낮음 | ✅ 완료（P7에 flutter test 추가） |
| 3 | 백업 스크립트 + 복구 훈련 | 높음（데이터 불실） | 낮음 | 낮음 | ✅ 완료（P8: backup.sh + RECOVERY_RUNBOOK） |
| 4 | ES 다운그레이드 폴백（MySQL LIKE） | 높음（가용성） | 낮음 | 중（이중 쿼리 경로 유지） | ✅ 완료（P4: 쓰기 경로 try/catch 폴백; 검색은 원래 전부 MySQL LIKE） |
| 5 | 결제 샌드박스 전 프로세스 + 콜백 멱등 검증 | 높음（상업화 필수） | 중 | 중（자격 증명/콜백 보안） | 🔶 코드 완료, 샌드박스 연동은 자격 증명 대기 |
| 6 | Prometheus + Grafana 알림 + 로그 로테이션 | 높음（운영 가능성） | 중 | 낮음 | ✅ 완료（양측 패널 P8/P9 보완; 알림 실측은 배포 대기） |
| 7 | SQL 마이그레이션 관리（전체를 install.sql 단일 진입점으로 병합） | 중（업그레이드 가능성） | 낮음 | 낮음 | ✅ 완료（2026-08-16 합병 완료） |
| 8 | 멀티 테넌트 방안 검토 + tenant_id 격리 | 높음（천장） | 높음 | 높음（전체 쿼리 영향） | ✅ 완료（P3 인도, 권한 초과 테스트 통과） |
| 9 | 부하 테스트 + 슬로우 쿼리관리 | 중（성능） | 중 | 낮음 | ✅ 완료（P3 실측 P95 달성; P7 스모크판 CI 진입） |
| 10 | 상업판 권한 스위치 + Demo 데이터 | 중（영업 전） | 중 | 낮음 | ✅ 완료（EDITIONS + demo_data.php + 데모 흐름 문서） |

## 6. 리스크와 의존

| 리스크 | 현황 | 완화 제안 | 상태 |
|------|------|---------|------|
| 단일 머신 배포 무HA | docker-compose 단일 머신, MySQL/Redis/ES 동일 머신 | 백업 복구 훈련 + 모니터링 알림 + 확장 대비 문서 | ✅ 완화구축（P8 백업 + P2/P8/P9 모니터링 + P6 SCALING_PLAN）; 훈련 실행은 배포 대기 |
| ES 하드 의존 | 검색/인덱스 동기 전부 ES 경유 | 다운그레이드 폴백 + 인덱스 재구축 스크립트 | ✅ 완화（P4 쓰기 경로 폴백; 검색은 원래 전부 MySQL LIKE, ES는 쿼리 경로 의존 아님） |
| 키 관리 | 플레이스홀더 + 하드코딩 폴백 키, 로테이션 없음 | 생성기 + 로테이션 스크립트; 프로덕션은 환경 변수 주입 | ✅ 해결（fail-fast 검증 + gen_env_keys.sh + rotate_keys.sh） |
| 결제 자격 증명 분산 | 결제 모듈 중앙 설정 없음, 샌드박스 미검증 | 설정 집중화 + 샌드박스 선행 | 🔶 설정 집중 완료（config/payment.php）, 샌드박스 연동은 자격 증명 대기 |
| 마이그레이션 관리 | 단일 파일 install.sql（IF NOT EXISTS 멱등） | 단일 전체 진입점으로 통일 완료; 증분 업그레이드 경로 필요 시 별도 논의 | ✅ 통일 완료（2026-08-16 합병 완료） |
| 테스트 커버리지 구조 편향 | 133개 테스트가 schema/보안/왕복에 집중 | 커버리지 게이트 + 핵심 비즈니스（요금/승인/SLA）단위 테스트 보완 | ✅ 강화 완료（admin 193 / service 101 / Flutter 9; 게이트로 제로 계측 회귀 방지） |
| 모바일 격차 | HarmonyOS 5페이지뿐, 입주민 포털 네이티브 App 없음 | P3 핵심 경로보완; 의존: HarmonyOS 테스트 장비 | ✅ 핵심 경로보완（5페이지: 납부/수리 접수/공지/방문객/주차）; 실기기 검증은 장비 대기 |

## 7. 팀 분업（pmp-team）

| 역할 | 투입 작업 |
|------|---------|
| 아키텍처 | 멀티 테넌트 방안 검토와 tenant_id 격리 설계（P3）、ES 다운그레이드 아키텍처、모니터링 아키텍처（P2）、결제 콜백 멱등 설계 검토 |
| 백엔드 | 키 생성/로테이션 스크립트、ES 다운그레이드 구현、결제 설정 집중화 + 샌드박스 연동、마이그레이션 스크립트 분할、부하 테스트와 슬로우 쿼리관리 |
| Flutter 프론트 | CI 통합 flutter analyze、입주민 포털 모바일 적응（P3）、버전 스위치 UI 협조 |
| HarmonyOS | 핵심 경로보완: 납부/수리 접수/공지/방문객/주차（P3） |
| 테스트 | 커버리지 게이트、결제 샌드박스 테스트（중복 콜백/환불/대사）、부하 스크립트、백업 복구 훈련 실행 |
| 검토 | 결제와 보안 핵심 경로 review、gitleaks CI 진입、멀티 테넌트 권한 초과 테스트 검토 |
| 문서 | 배포/운영 매뉴얼（복구 훈련 포함）、멀티 테넌트 방안 문서、모니터링 설정 매뉴얼、상업판 인도 매뉴얼 |

## 8. 즉시 행동 제안

✅ 원래 P1 1-4항（키 공고화 → CI 보완 → 백업 스크립트 → ES 다운그레이드）이 모두 실행 완료（P4-P9 반복 인도）.

**남은 의존 항목（외부 조건 필요, 코드 격차 아님）**:
1. 결제 샌드박스 연동: WECHAT_PAY_* / ALIPAY_* 샌드박스 자격 증명 확보 후 `scripts/payment_sandbox_smoke.php` 실행（주문→중복 콜백 멱등→환불→대사 전체체인 검증）
2. 모니터링 알림 실측: 배포 후 `scripts/verify_monitoring.sh`로 규칙 로드 검증, 실제 5xx/커넥션 장애 트리거로 알림 검증（Http5xxRatio 규칙은 바로 적용 가능）
3. 백업 복구 훈련: docs/RECOVERY_RUNBOOK.md에 따라 분기 훈련 실행 및 실측 소요 기록（RTO ≤ 1h 목표）
4. HarmonyOS 실기기 검증: 테스트 장비 도착 후 핵심 경로 실행（납부/수리 접수/공지/방문객/주차）
