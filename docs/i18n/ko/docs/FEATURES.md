# 기능 문서 (Features)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## 기능 목록

| 번호 | 모듈 | 소속 배치 | 관리자 | 입주민 | 데이터 테이블 |
|------|------|---------|---------|--------|--------|
| 1 | 단지 관리 | 1차 | CRUD + 검색 페이징 | 단지 바인딩 조회 | management_community |
| 2 | 동 관리 | 1차 | CRUD + 단지별 필터 | - | management_building |
| 3 | 호 관리 | 1차 | CRUD + 동별 필터 | - | management_unit |
| 4 | 세대 유형 관리 | 1차 | CRUD | - | management_room_type |
| 5 | 부동산 관리 | 1차 | CRUD + 주택 트리 + 입주민 일괄 바인딩 | 내 부동산 목록/상세 | management_room |
| 6 | 입주민 관리 | 1차 | CRUD + 일괄 임포트/활성비활성/삭제 | 가입/로그인/개인정보 | management_owner, management_room_owner |
| 7 | 임차인 관리 | 1차 | CRUD + 부동산별 필터 | - | management_tenant |
| 8 | 요금 관리 | 1차 | 요금 유형 CRUD + 청구서 관리 + 일괄 생성 + 오프라인 수납 | 청구서 조회 + 온라인 납부 + 요금 통계 | management_fee_type, management_fee_bill, management_fee_payment |
| 9 | 수리 접수 관리 | 1차 | 수리 목록 + 배정 + 진행 상황 업데이트 | 수리 접수 + 진행 상황 확인 + 평가 | management_repair_order, management_repair_progress |
| 10 | 공지 알림 | 1차 | CRUD + 발행/상단 고정 | 공지 목록/상세 | management_announcement |
| 11 | 주차 관리 | 2차 | 주차 구역/차량 관리 + 주차 기록 | 내 주차구역/차량 + 주차 기록 | management_parking_space, management_parking_vehicle, management_parking_record |
| 12 | 설비 관리 | 2차 | 설비 대장 + 유지보수 기록 | - | management_equipment, management_equipment_maintenance |
| 13 | 민원/제안 | 2차 | 민원 목록 + 처리 + 재방문 | 민원 제출 + 진행 상황 확인 + 평가 | management_complaint |
| 14 | 방문객 관리 | 2차 | 방문객 승인 + 기록 조회 | 방문 예약 + 통행 코드 | management_visitor |
| 15 | 계약 관리 | 2차 | CRUD + 상태 관리 | - | management_contract |
| 16 | 재무 관리 | 2차 | 수입/지출 관리 + 통계 보고서 | - | management_finance_income, management_finance_expense |
| 17 | 경비 순찰 | 3차 | 순찰 경로 + 순찰 기록 | - | management_security_patrol, management_patrol_record |
| 18 | 청소 관리 | 3차 | 청소 구역 + 청소 기록 | - | management_cleaning_area, management_cleaning_record |
| 19 | 조경 관리 | 3차 | 조경 구역 + 관리 기록 | - | management_green_area, management_green_maintenance |
| 20 | 커뮤니티 활동 | 3차 | 활동 관리 + 신청 조회 | 활동 목록 + 신청 | management_community_activity, management_activity_signup |
| 21 | 에너지 관리 | 3차 | 계량기 관리 + 검침 기록 | - | management_energy_meter, management_energy_record |
| 22 | 직원 관리 | 3차 | CRUD + 상태 관리 | - | management_staff |

## 확장 기능(4차 — 12개 모듈)

| 번호 | 모듈 | 관리자 | 입주민 | 데이터 테이블 |
|------|------|---------|--------|--------|
| 23 | 메시지 알림 | 템플릿 CRUD + 수동 발송 + 목록 | 내 메시지 + 읽음 표시 | management_notification_template, management_notification |
| 24 | 승인 워크플로 | 승인 유형 + 인스턴스 + 단계 전환 | - | management_approval_type, management_approval, management_approval_record |
| 25 | 결제 연동 | 주문 관리 + 환불 + 위챗/알리페이 콜백 | - | management_payment_order |
| 26 | 입주민 투표 | 투표 CRUD + 옵션 + 면적 가중 통계 | 투표 목록 + 투표 + 면적 가중 | management_vote, management_vote_option, management_vote_record |
| 27 | SLA 자동 승격 | 규칙 설정 + 지연 확인 + 벌칙 | - | management_sla_rule, management_sla_record |
| 28 | 스마트 납부 독촉 | 전략 설정 + 연체 매칭 + 연체료 | - | management_collection_strategy, management_collection_record |
| 29 | 모바일 순찰 | 작업 배정 + GPS 출근 기록 + 사진 촬영 | - | management_inspection_task, management_inspection_checkpoint |
| 30 | 커뮤니티 몰 | 카테고리/상품/주문/배송 관리 | 상품 둘러보기 + 주문 + 내 주문 | management_mall_category, management_mall_product, management_mall_order |
| 31 | 얼굴 인식 | 심사 관리 | 얼굴 등록 + 인증 상태 | management_face_info |
| 32 | 그룹 관리 | 그룹 CRUD + 단지 연관 + 구역 간 집계 | - | management_group, management_group_community |
| 33 | 스마트 Q&A | 지식 베이스 + 대화 기록 + 통계 | 질문 + 키워드 매칭 | management_knowledge_base, management_chat_record |
| - | 데이터 스크린 | 실시간 부동산 데이터 시각화 전체 화면 표시 | - | (기존 데이터 인터페이스 재사용) |

## 관리자 콘솔 모듈(admin 기존)

| 모듈 | 기능 |
|------|------|
| 대시보드 | 실시간 통계/추세/분포/로그(Redis 5m 캐시) |
| 사용자 관리 | 관리자 사용자 CRUD + 일괄 삭제/활성비활성 + Excel 임포트 |
| 역할/권한 | CRUD + 권한 트리 + RBAC method.path 검증 |
| 시스템 설정 | 키-값 CRUD |
| 작업 감사 | 로그 조회 + 8개 플랫폼 소스 자동 감지 |
| 파일 관리 | 업로드 + Excel/PDF 내보내기(민감 데이터 마스킹) |
| 보안 관리 | 18단계 심층 방어 + security.txt |
| 운영 모니터링 | 헬스 체크 + Prometheus 메트릭 + API 문서 |
| 국제화 | 중국어/영어 이중 언어, PHP symfony/translation + Flutter GetX Translations + HarmonyOS 리소스 한정자 |
| API 문서 | `hg/apidoc` 자동 생성, admin 10개 그룹 + service 9개 그룹, 기능 모듈별 구성 |

## 모듈 간 기능

### ID 암호화 전송
모든 API 요청과 응답의 ID 필드는 `erikwang2013/hashids`로 인코딩/디코딩됩니다. 클라이언트는 hashid 문자열(예: `aB3xK9mW2pQ7rT5v`)을 받고, 백엔드는 BIGINT로 디코딩하여 처리합니다.

### 민감 데이터 보호
- API 전송 레이어: `erikwang2013/encryption` — AES-256-CBC
- 데이터베이스 저장 레이어: `erikwang2013/encryptable` — Eloquent Model casts 자동 암/복호화
- 프런트엔드 표시 레이어: 휴대폰 번호 138****1234, 이메일 a***@e.com

### 작업 감사
모든 관리자 POST/PUT/DELETE 작업이 자동 기록되며, 작업 사용자, IP, 경로, 파라미터(마스킹됨), 작업 시간, 소스 플랫폼(web/ios/android/harmonyos/windows/macos/linux/ipados)을 포함합니다.

### 권한 제어
- 관리자: RBAC method.path 단위 검증, 슈퍼 관리자 `*` 검사 건너뜀
- 입주민: JWT Bearer Token 인증, 입주민은 자신의 데이터만 조작 가능

### 보안 방어
18단계 심층 방어: 캡차 → 비밀번호 확인 → 랜덤 검증 → 보안 스캔 → 공격 차단 → 전송 암호화 → JWT → 세션 제어 → 계정 잠금 → RBAC → 속도 제한 → ID 보호 → 요청 암호화 → 저장 암호화 → 표시 마스킹 → 감사 → CSP → 저작권 워터마크

### 내보내기 기능
- Excel: PhpSpreadsheet, 파란 배경 흰 글자 표 헤더 + 첫 행 고정 + 자동 필터 + 민감 데이터 마스킹
- PDF: Dompdf A4 가로, 페이지 헤더 저작권 + 페이지 푸터 제거 불가 저작권 워터마크
- 패널 시각화 데이터 PDF 내보내기

### 검색 엔진
- `erikwang2013/webman-scout`이 Elasticsearch 구동
- 자동 인덱스 동기화(증가/삭제/수정 시 자동 푸시)
- 인덱스 접두사 `management_`, 데이터베이스 테이블 접두사와 일치

### 국제화 (i18n)
- **PHP 백엔드**: symfony/translation — `resource/translations/{zh_CN,en}/messages.php`, 42개 번역 키, 컨트롤러는 `__()` 메서드로 번역 획득
- **Flutter Web**: GetX `Translations` — `lib/i18n/messages.dart`, 101개 번역 키, 페이지는 `.tr` 확장으로 사용
- **HarmonyOS**: `resources/{base,en_US}/element/string.json` 리소스 한정자
- **기본 언어**: 중국어 간체(zh_CN), 대체 언어 영어(en)
- **요청 헤더**: `Accept-Language`로 응답 언어 제어 지원

### 테스트 커버리지
- **테스트 프레임워크**: PHPUnit 12.x
- **TDD 프로세스**: 레드→그린→리팩토링, 테스트 먼저 작성 후 코드
- **관리자**: 60개 테스트, 164개 단언, 기반 서비스, 환경 설정, 보안 검증 커버
- **입주민 포털**: 18개 테스트, 45개 단언, 100% 통과율
- **합계**: 78개 테스트, 209개 단언
- **커버 범위**: Snowflake ID 생성 고유성, Hashids 인코딩/디코딩 왕복, 통일 응답 형식, 64개 테이블 Schema 검증, 중영문 번역 키 일관성
- **Flutter**: flutter analyze 제로 이슈
- **API 문서**: `hg/apidoc` 자동 생성, admin(10개 그룹) + service(9개 그룹), 기능 모듈별 인터페이스 문서 구성
