# 멀티 테넌트 SaaS 방안 검토 (Multi-Tenant Plan)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
> 상태: 검토 초안 (P3-① 선행 작업) | 날짜: 2026-08-16

## 1. 현황 파악

### 1.1 테이블 구조 분류（65개 테이블, docs/install.sql 검증）

| 카테고리 | 테이블 | 설명 |
|------|-----|------|
| 전역/플랫폼 테이블 | management_admin_user / admin_role / admin_permission / admin_user_role / admin_role_permission、management_system_config、management_operation_log | 인증, 설정, 감사, 본질적으로 플랫폼급, 테넌트 미부착 |
| 커뮤니티 차원 테이블 | management_community 및 community_id로 귀속되는 40+개 비즈니스 테이블（building/unit/room/owner/fee_*/repair_order/parking_*/announcement 등） | community_id를 통해 간접적으로 테넌트에 귀속 |
| 그룹 연관 테이블 | management_group（그룹）、management_group_community（그룹↔단지） | 현재 **선택적 연관**, 테넌트 의미 없음, 단지 간 집계는 join 사용 |
| 플랫폼 확장 테이블 | management_notification_template、management_knowledge_base、management_mall_*、management_face_info 등 | 일부는 플랫폼급, 일부는 커뮤니티급, 개별 확인 필요 |
| 혼동 쉬운 테이블 | **management_tenant（임차인 테이블）** | ⚠️ 의미 충돌: "세대 임차인"（room_id/owner_id 차원）이며, **SaaS 테넌트가 아님** |

### 1.2 인증 체인（admin측, 코드 검증）

```
전역 미들웨어: Cors → SecurityFilter → RateLimit
라우트 그룹 미들웨어: AdminAuth(JWT → $request->adminId) → AdminPermission(RBAC method.path) → OperationLog → Controller
```

- `AdminAuth`가 request 주입 패턴을 이미 구축（`$request->adminId`）, 테넌트 컨텍스트를 완전히 복제 가능
- `AdminPermission`은 플랫폼급 RBAC, 테넌트 격리와 **직교**, 중첩 가능
- service 입주민 포털: JWT가 owner_id 보유, 데이터는 room_owner → room.community_id 경유로 자연 제한, 크로스 테넌트 리스크 낮음

### 1.3 핵심 결론

- 기성 SaaS 테넌트 모델 없음; `management_tenant` 이름이 이미 임차인에 사용 중, 새 개념은 이름을 피해야 함
- 모든 컨트롤러가 Eloquent 직접 쿼리, repository 계층·전역 스코프 없음 —— 격리 개조는 모델 계층에서 해야 함
- config/database.php 단일 커넥션, 하지만 illuminate/database는 멀티 connection을 원래 지원（독립 DB 진화 대비 예약）

## 2. 방안 비교와 추천

| 방안 | 메커니즘 | 개조량 | 운영 비용 | 적용 |
|------|------|--------|----------|------|
| **A. 공유 DB + tenant_id 행 격리（추천）** | 테넌트 테이블 + 비즈니스 테이블 tenant_id 컬럼 + Eloquent 전역 스코프 필터 | 중（2개 테이블 컬럼 추가 + 미들웨어 + 전역 스코프 + 기존 데이터 백필） | 낮음（단일 DB 백업/마이그레이션 불변） | 중소 부동산, 단일 테넌트 <500만 행 |
| B. 독립 DB（테넌트별 1개 DB） | 커넥션 라우팅 + 크로스 DB 집계 | 높음（커넥션 관리/크로스 DB 리포트/마이그레이션×N/백업×N） | 높음 | 대형 그룹, 규정 준수 격리 요구 |
| C. 하이브리드（민감 DB 독립 + 공유） | A+B 조합 | 높음 | 높음 | 결제/안면 등 강격리 시나리오 |

**A 추천, B는 진화 방향.** 이유:

1. 기존 65개 테이블이 단일 DB에 통일, A의 tenant_id 데이터 모델은 향후 DB 분리에 방해 안 됨（필터 세분화를 행에서 DB로 바꾸면 됨, A 방안에서 테넌트 ID가 이미 전역 모델링됨）
2. 비즈니스 데이터가 전부 community_id로 귀속, tenant_id는 **최상위 테이블**에만 추가하면 되고, 중간 40개 비즈니스 테이블은 접근 경로로 보장, 테이블마다 컬럼 추가 불필요
3. 양쪽（admin/service）이 동일 데이터 모델 공유, A의 개조는 admin측 실행 계층에 집중
4. 단일 서버 배포 현황에서 B의 백업/마이그레이션 복잡도는 감당 불가

## 3. 격리 지점 설계

### 3.1 데이터 모델（최소 집합）

- 신규 `management_platform_tenant`（임차인 테이블 management_tenant와 충돌 방지）: id/name/status/created_at 등
- `management_community`에 `tenant_id BIGINT NOT NULL DEFAULT 0` 추가, 인덱스 `(tenant_id, community_id)`
- `management_admin_user`에 `tenant_id BIGINT NOT NULL DEFAULT 0` 추가（0 = 플랫폼 슈퍼 관리자）
- 비즈니스 중간 테이블（building/room/fee_bill 등 40개）**컬럼 미추가**, community_id로 귀속

### 3.2 실행 계층 3종 세트

1. **TenantContext 미들웨어**: JWT payload에 `tenant_id` 클레임 추가 → `$request->tenantId`（AdminAuth 주입 패턴 복제）; 로그인/설치/플랫폼급 라우트（user/role/permission/config）통과 목록
2. **TenantScope 전역 스코프**: Community 및 플랫폼급 비즈니스 모델에 Eloquent 전역 스코프 부착, `$request->tenantId`로 자동 필터; `find()`도 스코프 제약을 받아 크로스 테넌트 단건 직접 조회 자연 차단
3. **Tenant::for() 명시적 컨텍스트**: 스케줄/큐/가져오기는 HTTP 요청이 없으므로 클로저로 감싸 테넌트 명시 지정; 컨텍스트 누락 시 **fail-closed**（쿼리 거부）, 무필터 조용한 통과 불허

### 3.3 권한 초과 방어 테스트 포인트（인수 매트릭스）

| 테스트 케이스 | 기대 |
|------|------|
| 테넌트 A 관리자가 테넌트 B의 community/building/fee_bill 목록 조회 | 빈 값 또는 A 데이터만 반환 |
| 테넌트 A 관리자가 테넌트 B의 단건 레코드 find/update/delete（id 직접 조회） | 403 / 빈 데이터 / 거부 |
| 플랫폼 관리자（tenant_id=0）크로스 테넌트 작업 | 통과（플랫폼급 능력） |
| service 입주민의 커뮤니티 간 작업（납부/수리 접수） | 거부（community 귀속 검증） |
| 스케줄/큐에서 테넌트 컨텍스트 미지정 | 무필터 대신 fail-closed 오류 |

## 4. 진화 경로（단계적 마이그레이션）

| 단계 | 내용 | 인수 |
|------|------|------|
| 1. 데이터 계층 | platform_tenant 테이블 생성 + community/admin_user 컬럼 추가 + 멱등 마이그레이션 + 기본 테넌트 초기화 및 기존 데이터 백필 | 모든 community가 테넌트 필수 부착, 고아 데이터 보고 0건 |
| 2. 실행 계층 | TenantContext 미들웨어 + TenantScope + Tenant::for() 툴 + 라우트 통과 목록 | 단일 테넌트 회귀: 전체 133개 테스트 통과 |
| 3. 파일럿 모듈 | 그룹 관리 → 단지 → 입주민 → 요금（청구서）4개 모듈부터 격리 활성화 | 권한 초과 테스트 매트릭스 통과 |
| 4. 전체 확대 | 배치별（1차 핵심 → 2차 보조 → 확장 모듈）로 모듈별 활성화 | 전 모듈 권한 초과 매트릭스 통과 |
| 5. 진화 | 단일 테넌트 데이터 >500만 행 또는 규정 요구 시 DB 분리 평가（B 방안）, A의 데이터 모델은 차단 없음 | DB 분리 방안 검토 |

데이터 마이그레이션 전략: 기존 데이터는 전부 "기본 테넌트"로 귀속（마이그레이션 스크립트가 생성）, 비즈니스 데이터는 삭제·수정 안 함; 마이그레이션 스크립트 멱등, 반복 실행 가능.

## 5. 리스크 목록

| 리스크 | 영향 범위 | 완화 / 롤백 |
|------|--------|-------------|
| 58+17 컨트롤러 쿼리 경로 개조량 큼 | 전체 비즈니스 인터페이스 | 전역 스코프로 ~80% 목록/상세 커버; raw query와 일괄 가져오기는 Tenant::for() 사용; 배치별 그레이 |
| 전역 스코프가 플랫폼급 쿼리 오사용（대시보드 단지 간 집계） | 대시보드/리포트 | 플랫폼급 인터페이스는 Tenant::without() 명시 또는 tenant_id=0 우회 |
| 스케줄/큐에 요청 컨텍스트 없음 | 독촉/SLA/알림 등 백그라운드 작업 | Tenant::for() 명시 감싸기 + fail-closed |
| 기존 데이터 백필 오류 | 전체 기존 데이터 | 멱등 스크립트 + 백필 검증 + 드라이런 모드 |
| 인덱스/성능 영향 | 고빈도 테이블（fee_bill/room/owner） | (tenant_id, community_id) 결합 인덱스; 슬로우 쿼리 로그 재검토 |
| 133개 테스트 회귀 | 전체 | 스코프 주입 후 전체 회귀 먼저 실행 후 파일럿 시작 |
| 명명 혼동（management_tenant 임차인 vs SaaS 테넌트） | 개발 인지 | 신규 테이블 platform_tenant 명명, 문서에 명시 선언 |
| **롤백 방안** | — | 전역 스코프는 설정 스위치로 원클릭 비활성화（단일 테넌트 의미 복원）, 데이터 컬럼은 보존·삭제 안 함, 파괴적 변경 없음 |

## 6. 검토 결론

**즉시 진행 권장**:
- 공유 DB + tenant_id 행 격리（방안 A）, 신규 `management_platform_tenant` 테이블 생성, community/admin_user 컬럼 추가
- TenantContext 미들웨어 + TenantScope 전역 스코프 + Tenant::for() 툴
- 파일럿 순서: 그룹 → 단지 → 입주민 → 요금
- 선행 의존: 완료됨 — 멀티 테넌트 테이블/컬럼/백필이 docs/install.sql에 인라인 병합（2026-08-16 합병 완료, 단일 DB 구축 진입점）

**보류 권장**:
- 독립 DB 격리（B）: 단일 테넌트 >500만 행 또는 규정 요구 시에만 시작, 데이터 모델은 예약됨
- 하이브리드 방안（C）: 결제/안면 등 강격리 시나리오에서 고객이 명시적으로 요구하면 재평가

**비권장**:
- Schema급 격리（MySQL은 독립 schema 의미 없음, 비용이 독립 DB와 동일）
- 동적 멀티 DB 라우팅（단일 서버 배포에서 이점 없음）
- 테넌트급 맞춤 schema/필드（YAGNI）
- management_tenant 임차인 테이블을 SaaS 테넌트로 재사용/개조（의미 충돌, 임차인 업무 파괴）
