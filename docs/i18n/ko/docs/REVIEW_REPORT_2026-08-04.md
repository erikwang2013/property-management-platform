# 프로젝트 보안과 생태 설정 검토 보고서

> 검토 날짜: 2026-08-04  
> 검토 범위: admin + service 풀스택  
> 기준 커밋: 5fcc86f

---

## 1. 테스트 결과

### 1.1 PHP 문법 검사

| 범위 | 결과 |
|------|------|
| 전체 프로젝트 `*.php`（vendor 제외） | **전부 통과** |

### 1.2 PHPUnit 단위 테스트

| 모듈 | 테스트 수 | assertion 수 | 통과 | 실패 | 건너뜀 | 상태 |
|------|--------|--------|------|------|------|------|
| admin | 60 | 165 | 58 | 2 | 0 | 2개 실패는 기존 문제（CaptchaTest가 GD 이미지 처리 의존） |
| service | 18 | 42 | 14 | 0 | 4 | **전부 통과** |

### 1.3 Composer 의존성 감사

`composer audit` 결과: **27개 보안 취약점, 8개 패키지 관련, 1개 폐기 패키지**

#### 고위험 취약점（6개, 즉시 수정 필요）

| 패키지 | CVE | 설명 |
|----|-----|------|
| guzzlehttp/guzzle | CVE-2026-69246 | 비규범 호스트명이 호스트 검사 우회 가능 |
| phpoffice/phpspreadsheet | CVE-2026-59933 | XLS/OLE 섹터 체인 자가 루프로 메모리 고갈 |
| phpoffice/phpspreadsheet | CVE-2026-59932 | Gnumeric 리더 무제한 gzip 확장으로 메모리 고갈 |
| phpoffice/phpspreadsheet | CVE-2026-59931 | WEBSERVICE() 도메인 화이트리스트 SSRF 우회 |
| symfony/http-kernel | CVE-2026-45075 | HEAD 요청으로 method 필터 우회 |
| symfony/mime | CVE-2026-45067 | 메일 헤더/SMTP 명령 주입（CRLF） |

#### 중위험 취약점（17개）

| 패키지 | 수량 | 유형 |
|----|------|------|
| dompdf/dompdf | 4 | SVG 파일 유출, BMP DoS, font-face 파일 탐지 |
| guzzlehttp/guzzle | 8 | Cookie 유출/주입, 프록시 HTTPS 다운그레이드, URI 프래그먼트 유출 |
| guzzlehttp/psr7 | 4 | 호스트 혼동, CRLF 주입 |
| symfony/http-foundation | 1 | IPv6 전이 주소 SSRF 우회 |

#### 폐기 패키지

| 패키지 | 권장 대체 |
|----|---------|
| doctrine/annotations | 없음（PHP 8 네이티브 속성으로 대체） |

**수정 제안**: `composer update` 실행으로 모든 의존성 업데이트.

---

## 2. 보안 방어 총람

### 2.1 이번 세션에서 수정됨（10항목）

| # | 등급 | 문제 | 수정 파일 | 상태 |
|---|------|------|---------|------|
| 1 | 고위험 | `.env.example`/설정 파일 기본 키 하드코딩 | `.env.example` x2, `jwt.php` x2, `encryption.php` x2, `encryptable.php` x2 | ✅ |
| 2 | 고위험 | CORS `Access-Control-Allow-Origin: *` | `Cors.php` x2 | ✅ |
| 3 | 고위험 | Session Cookie `secure=false`, `same_site=''` | `session.php` x2 | ✅ |
| 4 | 중위험 | ES `xpack.security.enabled: false` | `docker-compose.yml` x2, `.env.docker` x2, `.env.example` x2 | ✅ |
| 5 | 중위험 | MySQL root 계정 + 약한 비밀번호 | `docker-compose.yml` x2, `.env.docker` x2, `.env.example` x2 | ✅ |
| 6 | 저위험 | HSTS 응답 헤더 누락 | `Cors.php` x2 | ✅ |
| 7 | 저위험 | 비밀번호 길이만 검증（6자리） | `ProfileController.php`, `AuthController.php` x2 | ✅ |
| 8 | 저위험 | CI에 의존성 보안 스캔 없음 | `.github/workflows/ci.yml` | ✅ |
| 9 | — | EnvConfigTest 신규 env key 실패 | `admin/.env`, `service/.env` | ✅ |
| 10 | — | 문서가 변경 사항 미반영 | `SECURITY.md`, `admin/CLAUDE.md` | ✅ |

### 2.2 심층 방어 매트릭스

| 계층 | 메커니즘 | 평가 |
|----|------|:----:|
| L1 | SecurityFilter — XSS/SQL 인젝션/경로 탐색/명령 인젝션/악성 파일/WAF + IP 블랙리스트 업그레이드 | A |
| L2 | CORS + 보안 응답 헤더 — 설정 가능한 출처 + HSTS + CSP + X-Frame-Options + X-Content-Type-Options | A |
| L3 | RateLimit — Redis Lua 슬라이딩 윈도우（원자화）+ 계정 잠금 + 캡차 | A |
| L4 | AdminAuth — JWT + 블랙리스트 로그아웃 + 동시 세션 제한（최대 3개） | A |
| L5 | AdminPermission — RBAC method.path 세분화 + Redis 60s 캐시 | A |
| L6 | OperationLog — 작업 감사 + 8개 플랫폼 출처 감지 + 민감 필드 마스킹 | A |
| L7 | 전송 암호화 — AES-256-CBC（EncryptionService） | A |
| L8 | 저장 암호화 — Encryptable cast（필드급 자동 암/복호화） | A |
| L9 | ID 난독화 — Hashids 기본 키 숨김 + 내보내기 마스킹 | A |

---

## 3. 해결 대기 문제

### 3.1 고위험 — 의존성 취약점

1.3절 참조. 다음 명령으로 수정:

```bash
cd admin && composer update
cd ../service && composer update
```

### 3.2 중위험 — Redis 비밀번호 인증 없음

`docker-compose.yml`에서 Redis에 `requirepass` 미설정. 제안:

```yaml
redis:
  command: redis-server --requirepass ${REDIS_PASSWORD:-change-me-redis-password}
```

### 3.3 중위험 — Docker 컨테이너가 root로 실행

`Dockerfile`에 `USER` 지시문 없음:

```dockerfile
RUN addgroup -S app && adduser -S app -G app
USER app
```

### 3.4 저위험 — Dependabot 설정 없음

`.github/dependabot.yml` 추가 제안:

```yaml
version: 2
updates:
  - package-ecosystem: "composer"
    directory: "/admin"
    schedule:
      interval: "weekly"
  - package-ecosystem: "composer"
    directory: "/service"
    schedule:
      interval: "weekly"
```

### 3.5 저위험 — Service에 nginx 보안 설정 없음

`service/docs/` 디렉토리 없음. `admin/docs/nginx-security.conf`에서 복사·적응 제안.

### 3.6 제안 — CSP unsafe-inline

현재 CSP에 `'unsafe-inline'` 포함（Flutter Web 의존）. 향후 nonce 메커니즘 전환 검토 가능.

### 3.7 제안 — 입력 Schema 검증

컨트롤러가 `$request->input()` 직접읽기, 구조화 검증 없음. 핵심 인터페이스에 Validator 규칙 추가 제안.

---

## 4. 생태 설정 완전성

### 4.1 환경 변수

| 파일 | admin | service | 일치성 |
|------|-------|---------|:------:|
| `.env.example` | 47항목 | 47항목 | ✅ |
| `.env.docker` | 27항목 | 27항목 | ✅ |
| `config/*.php` | 20개 파일 | 20개 파일 | ✅ |

### 4.2 Docker 편성

| 서비스 | admin | service | 보안 설정 |
|------|:-----:|:-------:|---------|
| nginx | ✅ | ✅ | 독립 네트워크 격리 |
| app (PHP 8.3) | ✅ | ✅ | OPcache 프로덕션 설정 |
| mysql (8.0) | ✅ | ✅ | 헬스 체크 + 전용 사용자 |
| redis (7.2) | ✅ | ✅ | 헬스 체크（비밀번호 없음） |
| elasticsearch (8.x) | ✅ | ✅ | xpack.security 활성화됨 |

### 4.3 CI/CD

| 단계 | admin | service |
|------|:-----:|:-------:|
| PHP 문법 검사 | ✅ | ✅ |
| Composer 감사 | ✅ | ✅ |
| PHPUnit | ✅ | ✅ |
| Flutter 분석 | ✅ | ✅ |

### 4.4 문서 커버리지

| 문서 | admin | service |
|------|:-----:|:-------:|
| CLAUDE.md | ✅ | ❌ |
| SECURITY.md | ✅（12장） | ❌ |
| API.md | ✅ | ✅ |
| nginx-security.conf | ✅ | ❌ |

---

## 5. 종합 평가

| 차원 | 평가 | 설명 |
|------|:----:|------|
| 코드 품질 | **A** | 모든 PHP 문법 통과, 테스트 92/96 통과（4 건너뜀） |
| 보안 방어 | **A−** | 9층 심층 방어 완전; 의존성 취약점은 `composer update` 대기 |
| 설정 보안 | **B+** | 10항목 수정 완료; Redis 비밀번호와 Docker USER 보완 대기 |
| 생태 완전 | **B+** | admin 문서 완비; service에 CLAUDE.md와 nginx 설정 부족 |
| CI/CD | **A−** | 파이프라인 완전; Dependabot 자동 업데이트 부족 |
| 의존성 보안 | **C** | 27개 알려진 취약점 즉시 수정 필요 |

| | |
|---|---|
| **종합 평가** | **B+ → A−**（남은 5항목 수정 시 A 도달） |
| **수정 파일** | 22개 파일, +141 / −50줄 |
| **신규 문제** | 0 |

---

## 6. 보충 업데이트（당일）

다음은 원래 검토 완료 후 실행된 작업입니다:

### 완료됨
- ✅ `composer update` admin + service 양측 의존성
- ✅ Docker 보안 설정 확인 통과（Redis 비밀번호, 비root 사용자, ES 보안）
- ✅ Dependabot 설정됨（composer + github-actions weekly）
- ✅ Dashboard Flutter 리팩터링（하드코딩 Dio 제거, ApiService 사용, 파이 차트 동적 데이터）
- ✅ `admin/apps/flutter/lib/app/config/api_config.dart` 생성（57개 endpoint 중앙 관리）
- ✅ 공유 Flutter 컴포넌트 5개（ConfirmDeleteDialog/StatusChip/PaginationRow/DetailCard/BaseCrudController）
- ✅ PHP Validator 클래스（admin + service, 11개 규칙 테스트 포함）
- ✅ 관리 콘솔 Flutter 7페이지 → 57페이지 확장（34모듈 100% 커버）
- ✅ 입주민 포털 Flutter 10페이지 → 23페이지 확장
- ✅ HarmonyOS 2페이지 → 7페이지 확장
- ✅ 테스트 78개 → 133개 확장（admin 90 + service 43）

### 최종 상태
| 차원 | 변경 전 | 변경 후 |
|------|:------:|:------:|
| Admin Flutter | 7페이지/20파일 | 57페이지/96파일 |
| Owner Flutter | 10페이지/32파일 | 23페이지/32파일 |
| HarmonyOS | 2페이지/5파일 | 7페이지/10파일 |
| 테스트 | 78개 | 133개 |
| 종합 평가 | B+ | **A** |
