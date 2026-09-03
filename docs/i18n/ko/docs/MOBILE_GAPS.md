# 모바일측 격차 보완 목록

> 생성일: 2026-08-16 · 출처: pmp-team ci-agent（P3-③ 현황 파악, 읽기 전용）
> 해당 로드맵: docs/PROJECT_PLAN.md P3 — "HarmonyOS 7페이지를 핵심 경로（납부/수리 접수/공지/방문객/주차）로 확장, Flutter 입주민 포털 모바일 적응"

## 1. HarmonyOS 입주민 포털 현황（apps/harmonyos, 7페이지）

| 페이지 | 라우트（main_pages.json 등록 완료） | 호출 API |
|------|------------------------------|---------|
| LoginPage | pages/LoginPage | 로그인（AuthService） |
| HomePage | pages/HomePage | GET /service/v1/home（대시보드: 미납/작업/부동산 수 + 공지 목록） |
| FeeBillsPage | pages/FeeBillsPage | GET /service/v1/fees/bills?page=1&per_page=50 |
| RepairListPage | pages/RepairListPage | GET /service/v1/repairs |
| RepairSubmitPage | pages/RepairSubmitPage | POST /service/v1/repair |
| AnnouncementPage | pages/AnnouncementPage | GET /service/v1/announcements?page=1&per_page=50 |
| ProfilePage | pages/ProfilePage | GET /service/v1/profile、POST /service/v1/profile/logout |

**네비게이션 현황**（전체 앱에 4개 점프만 존재）: Login→Home、Home→Login（로그아웃）、Profile→Login、RepairList→RepairSubmit. HomePage는 통계 카드 + 공지 목록만 있고 기능 진입 그리드 없음; FeeBills/Announcement/Profile 페이지는 존재하지만 **진입 경로 없음, 도달 불가**.

## 2. HarmonyOS 핵심 경로 대조

| 핵심 경로 | 현황 | 격차 유형 |
|---------|------|---------|
| 납부 | 페이지 있음, API 통함 | 순수 프론트: Home 진입 없음（도달 불가） |
| 수리 접수 | 목록+제출 페이지 있음, API 통함 | 순수 프론트: Home 진입 없음（도달 불가） |
| 공지 | 페이지 있음, API 통함 | 순수 프론트: Home 진입 없음（도달 불가） |
| 방문객 | 페이지 없음 | 신규 페이지 필요（API 준비됨: GET/POST/PUT/DELETE /visitor*） |
| 주차 | 페이지 없음 | 신규 페이지 필요（API 준비됨: /parking/vehicles、/parking/spaces、/parking/records） |

백엔드 갭 없음: 5개 핵심 경로의 service API가 모두 준비됨（fees/repairs/announcements 상주 라우트; parking/visitors는 standard 버전 게이트 안）. ApiService.ets에 공용 get/post/put/delete가 이미 있으며, 신규 페이지에서 바로 재사용 가능.

## 3. Flutter 입주민 포털 현황（apps/flutter, 13모듈）

**페이지 목록**: login、home、fee、repair、parking×3、visitor×2、activity、notification、vote、mall×3、chat、face、profile — 모두 라우트 등록 완료（app.dart getPages）, 5개 핵심 경로 전부 구현됨.

**모바일 적응 문제**: home_page / login_page만 LayoutBuilder/MediaQuery 반응형 브레이크포인트 사용; **10개 페이지가 데스크톱 폭을 하드코딩**하여, 모바일 폭（<400px）에서 RenderFlex 오버플로 필연 발생:

| 페이지 | 하드코딩 |
|------|--------|
| chat_page | SizedBox(width: 600) |
| mall_products_page | width: 800 |
| mall_product_detail / mall_orders | SizedBox(width: 600) |
| notification_list | width: 480 + SizedBox(width: 600) |
| vote_list / vote_detail | SizedBox(width: 600) |
| activity_detail、parking_records/vehicles、visitor_list、face_register | 브레이크포인트 처리 없음（동일 문제 예상, 줄 단위 검증 안 함） |

또한: 하단 네비게이션 바（BottomNavigationBar）없음, 진입은 AppBar + 그리드; 페이지 padding 24는 데스크톱 스타일에 치우침. i18n 이중 언어는 이미 갖춤.

## 4. 격차 목록（분류 + 작업량）

### 백엔드 의존（없음）

### 순수 프론트

| # | 항목 | 작업량 |
|---|----|--------|
| 1 | HarmonyOS HomePage에 기능 진입 그리드 추가（Flutter판 12개 진입 대조）, 납부/수리 접수/공지/방문객/주차/개인 센터 연결 | M |
| 2 | HarmonyOS VisitorPage 신규（목록 + 등록, VisitorController 재사용） | M |
| 3 | HarmonyOS ParkingPage 신규（차량/주차 공간/기록, ParkingController 재사용） | M |
| 4 | Flutter 입주민 포털 하드코딩 폭 제거（600/800/480 → maxWidth 내로 제약 또는 ConstrainedBox 전환） | S |
| 5 | Flutter 입주민 포털 하단 네비게이션 바 + 컴팩트 padding 보완（모바일측이 인수 목표일 경우） | M |

### 연동 검증 필요

| # | 항목 | 작업량 |
|---|----|--------|
| 6 | HarmonyOS 실기기/에뮬레이터에서 납부→결제, 수리 접수 제출, 방문객 등록 전체체인 검증 | S（테스트 장비 제약 있음, PROJECT_PLAN에 해당 리스크 기재됨） |

## 5. 구현 순서 제안

1. 격차 1（가성비 최고: 기존 3개 페이지 재사용, 신규 페이지 0개）
2. 격차 4（Flutter 오버플로는 치명적, 모바일에서 반드시 크래시）
3. 격차 2、3（신규 페이지）
4. 격차 5（경험 개선）
5. 격차 6（장비 필요, 별도 진행）
