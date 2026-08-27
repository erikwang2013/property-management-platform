# 설치 가이드

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

본 문서는 부동산 관리 시스템을 처음부터 배포하는 방법을 안내합니다.

---

## 목차

1. [Web 설치 마법사（권장）](#web-설치-마법사권장)
2. [수동 설치](#수동-설치)
3. [Docker 배포](#docker-배포)
4. [기본 계정](#기본-계정)
5. [설치 검증](#설치-검증)
6. [자주 묻는 질문](#자주-묻는-질문)

---

## Web 설치 마법사（권장）

프로젝트에 Web 설치 마법사가 내장되어 있어, 관리측을 시작한 후 브라우저로 전체 설정을 완료할 수 있습니다.

### 사용 절차

```bash
# 1. 进入管理측目录
cd admin

# 2. 创建环境变量文件（从模板复制）
cp .env.example .env

# 3. 安装依赖
composer install --no-dev --optimize-autoloader

# 4. 启动服务
php start.php start -d
```

### 5. 설치 마법사 열기

브라우저에서 **`http://localhost:8787/install`** 에 접속해 안내에 따라 3단계 설정을 완료합니다:

| 단계 | 내용 | 설명 |
|------|------|------|
| 1단계 | 데이터베이스 설정 | 호스트, 포트, DB명, 사용자명, 비밀번호 입력 |
| 2단계 | 관리자 계정 | 관리 콘솔 로그인 사용자명과 비밀번호 설정（6자 이상） |
| 3단계 | 설치 확인 | 설정 정보 확인 후 확인 클릭 시 자동 설치 실행 |

설치 과정에서 자동으로 다음을 수행합니다:
1. 데이터베이스 연결 테스트
2. `.env` 설정 파일 작성
3. 전체 65개 데이터 테이블 + 권한 시드 가져오기
4. 관리자 계정 생성 및 슈퍼 관리자 역할 부여
5. 설치 잠금 파일 `public/.installed` 생성

### 설치 완료 후

- 관리 콘솔 주소: `http://localhost:8787/admin`
- 설치 마법사가 로그인 주소와 계정 정보를 표시
- 설정 적용을 위해 서비스 재시작 권장: `php start.php restart -d`
- 재설치가 필요하면 `public/.installed` 파일 삭제

---

## 수동 설치

### 환경 요구 사항

| 구성 요소 | 버전 요구 | 설명 |
|------|---------|------|
| PHP | 8.1+（권장 8.3） | pcntl, pdo_mysql, redis, gd, mbstring 확장 필요 |
| MySQL | 8.0+ | utf8mb4 문자셋 |
| Redis | 6.0+ | 캐시, 속도 제한, Session |
| Composer | 2.x | PHP 의존성 관리 |
| Elasticsearch | 8.x | 전문 검색（선택, 비활성화 시 데이터베이스 쿼리 사용） |
| Flutter SDK | 3.x | 프론트엔드 개발에만 필요 |

### PHP 확장 확인

```bash
php -m | grep -E "pcntl|pdo_mysql|redis|gd|mbstring|curl|json|xml|dom"
```

---

## 데이터베이스 초기화

### 1. 데이터베이스 생성

```bash
mysql -u root -p <<SQL
CREATE DATABASE IF NOT EXISTS management
  DEFAULT CHARSET utf8mb4
  COLLATE utf8mb4_unicode_ci;
SQL
```

### 2. 통합 설치 스크립트 가져오기

```bash
mysql -u root -p management < docs/install.sql
```

`docs/install.sql`에는 전체 65개 테이블 + RBAC 권한 시드 데이터가 포함되며, `CREATE TABLE IF NOT EXISTS`를 사용해 반복 실행 가능합니다.

실행 후 검증:

```bash
mysql -u root -p management -e "SHOW TABLES;" | wc -l
# 应输出: 66（65张表 + 1行表头）
```

---

## 관리측 배포

관리측은 `http://localhost:8787`에서 실행되며, 관리자 콘솔 API를 제공합니다.

```bash
cd admin

# 1. 配置环境变量
cp .env.example .env
# 编辑 .env，修改数据库密码、JWT 密钥等

# 2. 安装依赖
composer install --no-dev --optimize-autoloader

# 3. 启动服务
php start.php start -d
# -d 表示后台运行，不加 -d 可前台运行查看日志

# 4. 验证
curl http://localhost:8787/health
```

### 핵심 설정 항목（admin/.env）

| 설정 항목 | 설명 | 프로덕션 요구 사항 |
|--------|------|-------------|
| `JWT_SECRET_KEY` | JWT 서명 키 | 64자 이상 랜덤 문자열 |
| `HASHIDS_SALT` | ID 암호화 솔트 | 랜덤 문자열, service와 동일 유지 |
| `SNOWFLAKE_DATACENTER_ID` | 데이터센터 ID (0-31) | 다중 IDC 배포 시 구분 필요 |
| `SNOWFLAKE_WORKER_ID` | 워커 노드 ID (0-31) | 같은 IDC의 각 머신마다 상이 |
| `ENCRYPTION_KEY` | API 전송 암호화 키 | 32바이트 랜덤 문자열 |
| `ENCRYPTABLE_KEY` | DB 필드 암호화 키 | 32바이트 랜덤 문자열 |
| `DB_PASSWORD` | DB 비밀번호 | 강력한 비밀번호 |

---

## 입주민 포털 배포

입주민 포털은 `http://localhost:8788`에서 실행되며, 입주민 포털 API를 제공합니다.

```bash
cd service

# 1. 配置环境变量
cp .env.example .env
# 编辑 .env，修改数据库密码、JWT 密钥等

# 2. 安装依赖
composer install --no-dev --optimize-autoloader

# 3. 启动服务
php start.php start -d

# 4. 验证
curl http://localhost:8788/health
```

> **주의:** admin과 service는 동일한 데이터베이스를 공유합니다. `HASHIDS_SALT`는 admin과 반드시 일치해야 하며, 그렇지 않으면 admin이 생성한 암호화 ID를 service측에서 복호화할 수 없습니다.

---

## Docker 배포

### 관리측

```bash
cd admin
cp .env.docker .env
# 编辑 .env 修改生产密钥

docker compose up -d
# 包含: Nginx + PHP + MySQL + Redis + Elasticsearch
```

### 입주민 포털

```bash
cd service
cp .env.docker .env
# 编辑 .env 修改生产密钥

docker compose up -d
```

### 서비스 포트 계획

| 서비스 | admin | service | 설명 |
|------|-------|---------|------|
| 애플리케이션 | 8787 | 8788 | webman HTTP |
| MySQL | 3306 | 3307 | 컨테이너 포트 매핑 |
| Redis | 6379 | 6380 | 컨테이너 포트 매핑 |
| Elasticsearch | 9200 | 9201 | 컨테이너 포트 매핑 |
| Nginx | 80/443 | 80/443 | 배포 위치 분리 필요 |

> 동일 호스트에 두 docker-compose를 배포할 때 service의 포트는 충돌 방지를 위해 오프셋이 미리 설정되어 있습니다.

---

## 기본 계정

| 사용자명 | 비밀번호 | 역할 | 설명 |
|--------|------|------|------|
| admin | admin123 | 슈퍼 관리자 | 전체 권한 보유 |

> **프로덕션 환경에서는 즉시 기본 비밀번호를 변경하세요.**

---

## 설치 검증

### 1. 헬스 체크

```bash
# 管理측
curl http://localhost:8787/health

# 业务측
curl http://localhost:8788/health
```

### 2. API 문서

모든 API 엔드포인트와 파라미터 설명은 별도 문서 [API.md](API.md)를 참조하세요. 서비스 시작 후 자동 생성된 인터랙티브 인터페이스 문서에도 접속할 수 있습니다:

| 엔드 | 주소 |
|----|------|
| 관리자 | http://localhost:8787/apidoc |
| 입주민 포털 | http://localhost:8788/apidoc |

### 3. 로그인 테스트

```bash
curl -X POST http://localhost:8787/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

### 4. 테스트 실행

```bash
# 管理측
cd admin && php vendor/bin/phpunit

# 业务측
cd service && php vendor/bin/phpunit
```

---

## 자주 묻는 질문

### Q: 시작 시 `Call to undefined function pcntl_fork()` 오류

PHP에 pcntl 확장이 없습니다.

```bash
# Ubuntu/Debian
apt install php-pcntl

# Docker
docker-php-ext-install pcntl
```

### Q: 로그인 후 Token 무효 안내

admin과 service의 `.env`에서 다음 설정이 일치하는지 확인:
- `JWT_SECRET_KEY`
- `JWT_ALGORITHM`

### Q: 암호화 ID가 양쪽에서 불일치

admin과 service의 `HASHIDS_SALT` 값이 완전히 동일한지 확인하세요.

### Q: Docker 컨테이너 간 네트워크연결 안 됨

IP 대신 컨테이너 이름으로 연결하세요（예: `DB_HOST=mysql`）.

### Q: 데이터베이스 리셋 방법

```bash
mysql -u root -p -e "DROP DATABASE IF EXISTS management;"
mysql -u root -p -e "CREATE DATABASE management DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -p management < docs/install.sql
```

### Q: HTTPS 설정 방법

프로덕션 환경에서는 Nginx 리버스 프록시로 TLS를 종료할 것을 권장합니다. 참고 설정은 `admin/docs/nginx-security.conf`에 있습니다.

---

## 다음 단계

- [아키텍처 설계 문서](ARCHITECTURE_DESIGN.md) — 시스템 계층 아키텍처와 미들웨어 실행 체인
- [API 문서](API.md) — 전체 인터페이스 참조
- [기능 설계 문서](FEATURE_DESIGN.md) — 34개 모듈 기능 사양
- [버전 비교](EDITIONS.md) — Lite / Standard / Full 버전 차이
