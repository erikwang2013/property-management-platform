# 인터페이스 문서 (API Reference)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## 개요

- 관리자 API는 `http://localhost:8787`에서 실행
- 입주민 포털 API는 `http://localhost:8788`에서 실행
- 통일 응답 형식: `{"code": 0, "message": "success", "data": {...}}`
- 모든 ID 필드는 hashids 인코딩으로 전송
- API 버전은 요청 헤더 `API-Version`으로 제어（기본 `v1`）
- 언어는 요청 헤더 `Accept-Language`로 제어（`zh-CN` / `en-US`, 기본 `zh-CN`）

### 온라인 API 문서

서비스 시작 후 `hg/apidoc`에 접속하면 자동 생성된 인터랙티브 문서를 볼 수 있습니다:

| 엔드 | 주소 | 그룹 수 |
|----|------|--------|
| 관리자 | `http://localhost:8787/apidoc` | 10개 그룹（common/dashboard/system/property-core/property-aux/property-adv/extensions/export/import/upload） |
| 입주민 포털 | `http://localhost:8788/apidoc` | 9개 그룹（공개 인터페이스/홈/요금/수리 접수/피드백/주차/활동/개인/확장） |

---

## 관리자 API (admin :8787)

### 공개 인터페이스 — 인증 불필요

#### POST /api/captcha/generate
클릭형 캡차 획득.

요청 파라미터: 없음

응답:
```json
{
  "code": 0,
  "data": {
    "key": "captcha_key_string",
    "image": "base64_encoded_png",
    "extra": { "targets": ["树", "鸟", "花"] }
  }
}
```

#### POST /api/captcha/verify
클릭형 캡차 검증.

요청 파라미터:
| 파라미터 | 타입 | 설명 |
|------|------|------|
| key | string | 캡차 key, generate가 반환 |
| clicks | array | 클릭 좌표 [{x, y}, ...] |

응답:
```json
{
  "code": 0,
  "data": { "valid": true }
}
```

검증 실패 시 `code`는 422, `data.valid`는 `false`.

#### POST /api/auth/login
관리자 로그인.

요청 파라미터:
| 파라미터 | 타입 | 설명 |
|------|------|------|
| username | string | 사용자 이름 |
| password | string | 비밀번호 |
| captcha_key | string | 캡차 key |
| clicks | array | 클릭 좌표 [{x, y}, ...] |

응답:
```json
{
  "code": 0,
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "user": { "id": "aB3xK9mW...", "username": "admin", "real_name": "管理员" }
  }
}
```

#### POST /api/auth/refresh
Token 갱신.

요청 파라미터:
| 파라미터 | 타입 | 설명 |
|------|------|------|
| refresh_token | string | 갱신 토큰 |

응답:
```json
{
  "code": 0,
  "data": { "access_token": "eyJ..." }
}
```

#### GET /health
헬스 체크.

#### GET /metrics
Prometheus 모니터링 지표.

#### GET /api/docs
OpenAPI 문서.

---

### 관리자 인터페이스 — 인증 필요 (Bearer Token)

모든 인터페이스는 `/admin` 접두사를 사용하며, `Authorization: Bearer {access_token}` 헤더가 필요합니다.

#### 대시보드

**GET /admin/dashboard**
대시보드 통계 데이터 조회.

#### 관리자 사용자 관리

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /admin/user | 사용자 목록 (?keyword=&status=&page=&page_size=) |
| POST | /admin/user | 사용자 생성 |
| GET | /admin/user/{hashid} | 사용자 상세 |
| PUT | /admin/user/{hashid} | 사용자 수정 |
| DELETE | /admin/user/{hashid} | 사용자 삭제（비밀번호 확인 필요） |
| POST | /admin/user/batch/destroy | 일괄 삭제 |
| POST | /admin/user/batch/status | 일괄 활성/비활성화 |
| POST | /admin/import/users | Excel 사용자 가져오기 |

#### 역할·권한 관리

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /admin/role | 역할 목록 |
| POST | /admin/role | 역할 생성 |
| GET | /admin/role/{hashid} | 역할 상세 |
| PUT | /admin/role/{hashid} | 역할 수정 |
| DELETE | /admin/role/{hashid} | 역할 삭제 |
| GET | /admin/permission | 권한 목록（트리 구조） |
| POST | /admin/permission | 권한 생성 |
| PUT | /admin/permission/{hashid} | 권한 수정 |
| DELETE | /admin/permission/{hashid} | 권한 삭제 |

#### 시스템 설정

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /admin/config | 설정 목록 (?group=) |
| POST | /admin/config | 설정 생성 |
| PUT | /admin/config/{hashid} | 설정 수정 |
| DELETE | /admin/config/{hashid} | 설정 삭제 |

#### 작업 로그

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /admin/log | 로그 목록 (?user_id=&action=&method=&source=&start_date=&end_date=) |

#### 개인 센터

| 메서드 | 경로 | 설명 |
|------|------|------|
| PUT | /admin/profile | 개인 정보 수정 |
| PUT | /admin/profile/password | 비밀번호 변경 |
| POST | /admin/profile/logout | 로그아웃 |

#### 내보내기

| 메서드 | 경로 | 설명 |
|------|------|------|
| POST | /admin/export/excel | Excel 내보내기 ({ table, columns, conditions, title }) |
| POST | /admin/export/pdf | PDF 내보내기 ({ type, title, data }) |

---

### 부동산 관리 — 관리자 인터페이스

#### 단지 관리

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /admin/community | 목록 (?keyword=&status=) |
| POST | /admin/community | 생성 |
| GET | /admin/community/{hashid} | 상세 |
| PUT | /admin/community/{hashid} | 수정 |
| DELETE | /admin/community/{hashid} | 삭제（비밀번호 필요） |

#### 동 관리

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /admin/building | 목록 (?community_id=&keyword=) |
| POST | /admin/building | 생성 |
| GET | /admin/building/{hashid} | 상세 |
| PUT | /admin/building/{hashid} | 수정 |
| DELETE | /admin/building/{hashid} | 삭제 |

#### 호 관리

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /admin/unit | 목록 (?building_id=) |
| POST | /admin/unit | 생성 |
| GET | /admin/unit/{hashid} | 상세 |
| PUT | /admin/unit/{hashid} | 수정 |
| DELETE | /admin/unit/{hashid} | 삭제 |

#### 세대 유형 관리

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /admin/room-type | 목록 |
| POST | /admin/room-type | 생성 |
| GET | /admin/room-type/{hashid} | 상세 |
| PUT | /admin/room-type/{hashid} | 수정 |
| DELETE | /admin/room-type/{hashid} | 삭제 |

#### 부동산 관리

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /admin/room | 목록 (?community_id=&building_id=&unit_id=&status=) |
| POST | /admin/room | 생성 |
| GET | /admin/room/{hashid} | 상세 |
| PUT | /admin/room/{hashid} | 수정 |
| DELETE | /admin/room/{hashid} | 삭제 |
| GET | /admin/room/tree | 부동산 트리（단지→동→호→세대） |

#### 입주민 관리

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /admin/owner | 목록 (?keyword=&status=) |
| POST | /admin/owner | 생성 |
| GET | /admin/owner/{hashid} | 상세（연결 부동산 포함） |
| PUT | /admin/owner/{hashid} | 수정 |
| DELETE | /admin/owner/{hashid} | 삭제（비밀번호 필요） |
| POST | /admin/owner/batch/import | Excel 일괄 가져오기 |
| POST | /admin/owner/batch/destroy | 일괄 삭제 |

#### 임차인 관리

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /admin/tenant | 목록 (?room_id=&status=) |
| POST | /admin/tenant | 생성 |
| GET | /admin/tenant/{hashid} | 상세 |
| PUT | /admin/tenant/{hashid} | 수정 |
| DELETE | /admin/tenant/{hashid} | 삭제 |

#### 요금 유형

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /admin/fee-type | 목록 |
| POST | /admin/fee-type | 생성 |
| GET | /admin/fee-type/{hashid} | 상세 |
| PUT | /admin/fee-type/{hashid} | 수정 |
| DELETE | /admin/fee-type/{hashid} | 삭제 |

#### 청구서 관리

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /admin/fee-bill | 목록 (?community_id=&status=&due_date_start=&due_date_end=) |
| POST | /admin/fee-bill | 청구서 생성 |
| GET | /admin/fee-bill/{hashid} | 상세 |
| PUT | /admin/fee-bill/{hashid} | 수정 |
| DELETE | /admin/fee-bill/{hashid} | 삭제 |
| POST | /admin/fee-bill/batch/generate | 청구서 일괄 생성 |

#### 납부 기록

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /admin/fee-payment | 목록 (?bill_id=&payment_method=&date_start=&date_end=) |
| POST | /admin/fee-payment/offline | 오프라인 수금 등록 |

#### 수리 접수 관리

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /admin/repair | 목록 (?status=&category=) |
| POST | /admin/repair | 생성 |
| GET | /admin/repair/{hashid} | 상세（진행 기록 포함） |
| PUT | /admin/repair/{hashid} | 수정 |
| DELETE | /admin/repair/{hashid} | 삭제 |
| PUT | /admin/repair/{id}/assign | 배정（{ staff_id }） |
| POST | /admin/repair/{id}/progress | 진행 상황 업데이트（{ status_to, remark }） |

#### 공지 관리

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /admin/announcement | 목록 (?community_id=&category=&is_published=) |
| POST | /admin/announcement | 생성 |
| GET | /admin/announcement/{hashid} | 상세 |
| PUT | /admin/announcement/{hashid} | 수정 |
| DELETE | /admin/announcement/{hashid} | 삭제 |

#### 주차 관리

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /admin/parking-space | 목록 (?community_id=) |
| POST | /admin/parking-space | 주차 공간 생성 |
| PUT | /admin/parking-space/{hashid} | 수정 |
| DELETE | /admin/parking-space/{hashid} | 삭제 |
| GET | /admin/parking-vehicle | 목록 (?owner_id=&space_id=) |
| POST | /admin/parking-vehicle | 차량 등록 |
| PUT | /admin/parking-vehicle/{hashid} | 수정 |
| DELETE | /admin/parking-vehicle/{hashid} | 삭제 |
| GET | /admin/parking-record | 주차 기록 (?vehicle_id=&date_start=&date_end=) |

#### 장비 관리

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /admin/equipment | 목록 (?community_id=&category=&status=) |
| POST | /admin/equipment | 생성 |
| PUT | /admin/equipment/{hashid} | 수정 |
| DELETE | /admin/equipment/{hashid} | 삭제 |
| GET | /admin/equipment-maintenance | 유지보수 기록 (?equipment_id=) |
| POST | /admin/equipment-maintenance | 유지보수 등록 |

#### 민원 처리

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /admin/complaint | 목록 (?type=&status=) |
| GET | /admin/complaint/{hashid} | 상세 |
| PUT | /admin/complaint/{id}/handle | 처리（{ handler_remark }） |
| POST | /admin/complaint/{id}/visit | 방문 회신（{ visitor_remark }） |

#### 방문객 승인

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /admin/visitor | 목록 (?status=) |
| PUT | /admin/visitor/{id}/approve | 승인 통과 |

#### 계약 관리

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /admin/contract | 목록 (?contract_type=&status=) |
| POST | /admin/contract | 생성 |
| PUT | /admin/contract/{hashid} | 수정 |
| DELETE | /admin/contract/{hashid} | 삭제 |

#### 재무 관리

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /admin/finance-income | 수입 목록 (?income_type=&date_start=&date_end=) |
| POST | /admin/finance-income | 수입 등록 |
| GET | /admin/finance-expense | 지출 목록 |
| POST | /admin/finance-expense | 지출 등록 |
| GET | /admin/finance/statistics | 월별 수입·지출 통계 (?year=) |

#### 부동산 대시보드

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /admin/dashboard/property | 부동산 통계（미수금/입주율/수리 접수/민원/수입·지출 추이） |
| POST | /admin/export/property-excel | 부동산 데이터 Excel 내보내기（{ type: owners|bills }） |

#### 보안 순찰

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /admin/security-patrol | 목록 (?community_id=) |
| POST | /admin/security-patrol | 순찰 경로 생성 |
| GET | /admin/patrol-record | 기록 (?patrol_id=&staff_id=) |
| POST | /admin/patrol-record | 기록 등록 |

#### 청소 관리

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /admin/cleaning-area | 구역 목록 |
| POST | /admin/cleaning-area | 구역 생성 |
| GET | /admin/cleaning-record | 기록 (?area_id=) |
| POST | /admin/cleaning-record | 기록 등록 |

#### 조경 관리

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /admin/green-area | 구역 목록 |
| POST | /admin/green-area | 구역 생성 |
| GET | /admin/green-maintenance | 유지관리 기록 (?area_id=) |
| POST | /admin/green-maintenance | 기록 등록 |

#### 커뮤니티 활동

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /admin/activity | 목록 (?status=) |
| POST | /admin/activity | 활동 등록 |
| PUT | /admin/activity/{hashid} | 수정 |
| DELETE | /admin/activity/{hashid} | 삭제 |
| GET | /admin/activity-signup | 신청 목록 (?activity_id=) |
| PUT | /admin/activity-signup/{id}/checkin | 출석 확인 |

#### 에너지 관리

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /admin/energy-meter | 미터 목록 (?room_id=&meter_type=) |
| POST | /admin/energy-meter | 미터 등록 |
| GET | /admin/energy-record | 검침 기록 (?meter_id=&date_start=&date_end=) |
| POST | /admin/energy-record | 기록 등록 |

#### 직원 관리

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /admin/staff | 목록 (?community_id=&status=) |
| POST | /admin/staff | 생성 |
| PUT | /admin/staff/{hashid} | 수정 |
| DELETE | /admin/staff/{hashid} | 삭제 |
| POST | /admin/staff/batch/status | 일괄 활성/비활성화 |

#### 메시지 알림

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /admin/notification-template | 템플릿 목록 |
| POST | /admin/notification-template | 템플릿 생성 |
| PUT | /admin/notification-template/{hashid} | 템플릿 수정 |
| DELETE | /admin/notification-template/{hashid} | 템플릿 삭제 |
| GET | /admin/notification | 메시지 목록 (?type=&is_read=) |
| POST | /admin/notification/send | 수동 알림 전송 |

#### 승인 워크플로

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /admin/approval-type | 승인 유형 목록 |
| POST | /admin/approval-type | 승인 유형 생성 |
| GET | /admin/approval | 승인 목록 (?status=) |
| GET | /admin/approval/{hashid} | 승인 상세 |
| POST | /admin/approval | 승인 제출 |
| PUT | /admin/approval/{hashid}/approve | 승인（통과/반려） |

#### 결제 관리

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /admin/payment-order | 주문 목록 |
| GET | /admin/payment-order/{hashid} | 주문 상세 |
| POST | /admin/payment-order/{hashid}/refund | 환불 |
| GET | /admin/payment/statistics | 결제 통계 |

#### 입주민 투표

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /admin/vote | 투표 목록 (?status=) |
| POST | /admin/vote | 투표 등록 |
| GET | /admin/vote/{hashid}/statistics | 집계 통계 |
| PUT | /admin/vote/{hashid}/publish | 투표 공개 |
| PUT | /admin/vote/{hashid}/end | 투표 종료 |

#### SLA 관리 · 스마트 납부 독촉 · 순찰 관리 · 쇼핑몰 관리 · 안면 관리 · 그룹 관리 · 지식 베이스

（전체 엔드포인트는 `docs/API.md` 파일 참조）

---

## 입주민 포털 API (service :8788)

### 공개 인터페이스 — 인증 불필요

#### POST /api/captcha/generate
클릭형 캡차 획득.（관리자와 동일）

#### POST /api/captcha/verify
클릭형 캡차 검증.（요청/응답이 관리자와 동일）

#### POST /api/auth/login
입주민 로그인.

요청 파라미터:
| 파라미터 | 타입 | 설명 |
|------|------|------|
| phone | string | 휴대폰 번호 |
| password | string | 비밀번호 |
| captcha_key | string | 캡차 key |
| clicks | array | 클릭 좌표 |

응답:
```json
{
  "code": 0,
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "owner": { "id": "xB9k...", "name": "张三", "phone": "138****1234" }
  }
}
```

#### POST /api/auth/register
입주민 회원가입.

요청 파라미터:
| 파라미터 | 타입 | 설명 |
|------|------|------|
| phone | string | 휴대폰 번호 |
| password | string | 비밀번호（6자 이상） |
| name | string | 이름 |
| captcha_key | string | 캡차 key |
| clicks | array | 클릭 좌표 |
| room_id | string | （선택）연결할 세대 hashid |
| id_card_last4 | string | （선택）주민등록번호 뒤 4자리 |

#### POST /api/auth/refresh
Token 갱신.

---

### 입주민 포털 인터페이스 — 인증 필요 (Bearer Token)

모든 인터페이스는 `/service` 접두사를 사용하며, `Authorization: Bearer {access_token}` 헤더가 필요합니다.

#### 홈

**GET /service/home**

응답:
```json
{
  "code": 0,
  "data": {
    "room_count": 2,
    "pending_amount": "1250.00",
    "pending_bill_count": 3,
    "repairing_count": 1,
    "announcements": [{ "id": "xB9k...", "title": "停水通知", "published_at": "2026-05-20 09:00" }]
  }
}
```

#### 내 부동산

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /service/rooms | 내 부동산 목록 |
| GET | /service/room/{hashid} | 부동산 상세（면적, 방향, 권리, 단지 정보 포함） |

#### 요금 관리

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /service/fees/bills | 청구서 목록 (?status=0미납/1부분 납부/2납부 완료/3연체) |
| GET | /service/fees/bill/{hashid} | 청구서 상세（요금 유형, 결제 기록 포함） |
| GET | /service/fees/payments | 납부 기록 |
| POST | /service/fees/pay | 온라인 납부（{ bill_id, payment_method, password }） |
| GET | /service/fees/statistics | 요금 통계 (?year=2026) |

#### 수리 접수

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /service/repairs | 수리 접수 목록 (?status=) |
| GET | /service/repair/{hashid} | 수리 접수 상세（진행 타임라인 포함） |
| POST | /service/repair | 수리 접수 제출（{ room_id, category, urgency, description, images[], scheduled_at }） |
| DELETE | /service/repair/{hashid} | 취소（비밀번호 필요, { password }） |
| POST | /service/repair/{hashid}/rate | 평가（{ rating: 1-5, feedback }） |

#### 민원·제안

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /service/complaints | 민원 목록 |
| GET | /service/complaint/{hashid} | 민원 상세（처리 진행 포함） |
| POST | /service/complaint | 민원 제출（{ type, category, title, content, is_anonymous, images[] }） |
| POST | /service/complaint/{hashid}/satisfaction | 만족도 평가（{ satisfaction: 1-5 }） |

#### 공지

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /service/announcements | 공지 목록 (?category=) |
| GET | /service/announcement/{hashid} | 공지 상세 |

#### 주차

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /service/parking/vehicles | 내 차량 |
| GET | /service/parking/spaces | 내 주차 공간 |
| GET | /service/parking/records | 주차 기록 |

#### 방문객

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /service/visitors | 내 방문객 예약 |
| POST | /service/visitor | 예약 생성（출입 코드 생성） |
| PUT | /service/visitor/{hashid} | 예약 수정 |
| DELETE | /service/visitor/{hashid} | 예약 취소 |

#### 커뮤니티 활동

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /service/activities | 활동 목록 (?status=) |
| GET | /service/activity/{hashid} | 활동 상세 |
| POST | /service/activity/{hashid}/signup | 신청하기 |
| POST | /service/activity/{hashid}/cancel | 신청 취소 |

#### 개인 정보

| 메서드 | 경로 | 설명 |
|------|------|------|
| GET | /service/profile | 개인 정보 |
| PUT | /service/profile | 수정（{ name, email, gender, birthday }） |
| PUT | /service/profile/password | 비밀번호 변경（{ old_password, new_password }） |
| POST | /service/profile/logout | 로그아웃 |

---

## 오픈 API — API Key 인증

외부 노출 전용 읽기 전용 인터페이스로, 제3자 시스템（부동산 플랫폼 연동, 데이터 대시보드 등）에서 호출합니다. 접두사 `/open`, 전부 읽기 전용.

### 인증 방식

모든 요청은 `X-API-Key` 요청 헤더를 포함해야 하며, 값은 `scripts/gen_api_key.php`로 생성된 Key（64자리 hex, DB에는 SHA-256 다이제스트만 저장）입니다:

```bash
curl -H "X-API-Key: <你的Key>" http://localhost:8788/open/announcements
```

- 누락 또는 잘못된 Key는 `401` 반환（`{"code":401,"message":"无效的API Key","data":[]}`）
- Key 관리: `php scripts/gen_api_key.php [--name=용도]`로 생성; 비활성화/삭제는 `management_api_key` 테이블을 직접 조작（`status=0`이면 비활성화되어 키가 즉시 무효화）

### 엔드포인트

#### GET /open/announcements — 공지 목록

파라미터: `page`（기본 1）, `category`（선택）. 응답 구조는 `/service/announcements`와 동일.

```bash
curl -H "X-API-Key: <你的Key>" "http://localhost:8788/open/announcements?page=1"
```

#### GET /open/bills — 청구서 조회

파라미터: `bill_number`（필수, 청구서 번호）. 단일 청구서 상세 반환（요금 유형, 방 번호, 미납 금액 포함）. 없으면 404 반환.

```bash
curl -H "X-API-Key: <你的Key>" "http://localhost:8788/open/bills?bill_number=B202608160001"
```

#### GET /open/repairs — 수리 접수 상태 조회

파라미터: `order_number`（필수, 수리 접수 번호）. 수리 접수 건의 현재 상태 및 진행 타임라인（`progress` 배열）반환. 없으면 404 반환.

```bash
curl -H "X-API-Key: <你的Key>" "http://localhost:8788/open/repairs?order_number=R202608160001"
```

---

## 오류 코드

| code | 의미 | 설명 |
|------|------|------|
| 0 | 성공 | 정상 응답 |
| 400 | 요청 오류 | 파라미터 형식이 올바르지 않음 |
| 401 | 인증되지 않음 | Token 누락/만료/무효/블랙리스트 등록 |
| 403 | 권한 없음 | 사용자 역할에 필요한 권한이 없음 / 계정 비활성화 |
| 404 | 존재하지 않음 | 리소스를 찾을 수 없음 |
| 405 | 메서드 허용 안 됨 | GET/POST/PUT/DELETE/OPTIONS가 아닌 HTTP 메서드 |
| 413 | 요청 본문 과다 | 10MB 초과 |
| 415 | 지원하지 않는 미디어 유형 | Content-Type이 JSON 또는 form-urlencoded가 아님 |
| 422 | 검증 실패 | 폼 파라미터 규칙 위반 / 비밀번호 확인 실패 / 캡차 오류 |
| 429 | 요청 과다 | 속도 제한 / 계정 잠금 |
| 500 | 서버 오류 | 예기치 않은 예외 |

## 속도 제한 응답 헤더

속도 제한이 걸리면 429를 반환하며, 응답 헤더에 다음이 포함됩니다:

| 응답 헤더 | 설명 |
|--------|------|
| X-RateLimit-Limit | 제한 횟수 |
| X-RateLimit-Remaining | 남은 횟수 |
| X-RateLimit-Reset | 초기화 시간（Unix 타임스탬프） |
| Retry-After | 권장 재시도 대기 시간(초) |
