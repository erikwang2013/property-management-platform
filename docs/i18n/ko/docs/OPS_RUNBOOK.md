# 운영 매뉴얼（OPS Runbook）

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
> 적용: property-management-platform（admin측 + service측, PHP 8.3 webman）

## 1. 데이터베이스 백업과 복구

admin측과 service측은 동일한 MySQL 인스턴스와 DB `property_management`를 공유하므로, 백업 1회로 충분합니다. 통일 진입점:

| DB명 | 백업 스크립트 | 설명 |
|---|---|---|
| `property_management` | `scripts/backup.sh` | `admin/.env`에서 커넥션 읽기（`--container=`로 컨테이너명 오버라이드 가능）, 기본은 컨테이너 내 mysqldump |

출력 `backups/backup_YYYYMMDD_HHMMSS.sql.gz`, 기본 최근 7일 보관（`--keep-days=`로 조정 가능）.

### 1.1 전체 백업

```bash
cd /path/to/property-management-platform
bash scripts/backup.sh
```

### 1.2 크론잡（crontab）

```cron
# 每天 02:00 全量备份
0 2 * * * cd /path/to/property-management-platform && bash scripts/backup.sh >> /var/log/pmp-backup.log 2>&1
```

프로덕션 권장: 백업 디렉토리를 별도 디스크/원격 스토리지에 마운트하고, 주기적으로 백업 파일 무결성 점검（`gzip -t` 검증）.

### 1.3 복구 훈련 절차（분기 1회 이상）

1. 최근 백업 1건 선택: `ls -t backups/backup_*.sql.gz`
2. **별도 환경**（또는 임시 DB）에서 복구 실행: [RECOVERY_RUNBOOK.md](RECOVERY_RUNBOOK.md) 시나리오 A（빈 DB 복구）와 시나리오 B（시점 복구） 참조.
3. 검증:
   - 행 수 비교: `SELECT COUNT(*) FROM erik_user;` 백업 전 기록과 일치
   - 암호화 필드 정상 복호화: encryptable 필드 포함 레코드 1건 조회, 값 정확, 로그에 decrypt 오류 없음
   - 업무 스모크: 로그인, 목록 인터페이스 정상
4. 훈련 소요 시간과 결과 기록（RTO 평가용）.

> 전체 훈련 매뉴얼（빈 DB 복구 / 시점 복구 / 일관성 검증 / 30분 훈련 일정）은 [RECOVERY_RUNBOOK.md](RECOVERY_RUNBOOK.md) 참조.

### 1.4 RPO / RTO 설명

- **RPO（허용 데이터 손실량）**: 백업 빈도에 의해 결정. 일일 전체 백업 → RPO ≤ 24시간, 즉 최대 최근 하루치 데이터 손실. 더 작은 RPO가 필요하면 백업 빈도 증가（예: 하루 2회）또는 binlog 증분 백업 활성화.
- **RTO（복구 소요 시간）**: DB 크기와 복구 속도에 좌우, 목표 ≤ 1시간（복구 + 검증 + 서비스 재시작）. 훈련마다 실측값 업데이트.
- 복구 실패 시 비상: 먼저 애플리케이션 코드 롤백 후, 최근 사용 가능한 백업으로 재시도; 백업 손상 시 더 이전 백업을 사용하고 더 큰 RPO 수용.

## 2. 키 관리

프로젝트는 5개 키에 의존하며, 모두 `.env`에 있음（admin과 service 각자 독립, 동일 세트 공용 금지）:

| 변수 | 길이 | 용도 |
|---|---|---|
| `ENCRYPTION_KEY` | 32바이트 | API 전송 암호화（config/encryption.php） |
| `ENCRYPTABLE_KEY` | 32바이트 | DB 민감 필드 암호화（encryptable 플러그인, **ENCRYPTION_KEY와 공용 금지**） |
| `JWT_SECRET_KEY` | 64자 이상 | JWT 서명 |
| `HASHIDS_SALT` | — | ID 암호화/복호화 |
| `HASHIDS_ALT_SALT` | — | ID 암호화/복호화 예비 |

### 2.1 키 생성

```bash
# 输出 5 个 KEY=VALUE 到 stdout，可直接追加到 .env
php scripts/gen_env_keys.php

# 直接写入 .env：已存在的密钥不覆盖，只追加缺失的
php scripts/gen_env_keys.php --file=.env
```

> .env의 특정 키가 아직 `change-me` 플레이스홀더라면 해당 줄을 먼저 삭제한 후 실행（플레이스홀더는 "이미 존재"로 간주되어 덮어쓰지 않음）.

### 2.2 키 로테이션（encryptable）

```bash
bash scripts/rotate_keys.sh            # 默认操作当前目录 .env
bash scripts/rotate_keys.sh /path/to/service/.env
```

스크립트가 자동 완료: .env 백업 → 새 `ENCRYPTABLE_KEY` 생성 → 이전 key를 `ENCRYPTION_PREVIOUS_KEYS`에 추가（쉼표 구분, 최근 로테이션이 맨 앞）→ 새 key 작성. 이후 안내에 따라 수동: 서비스 재시작 → 복호화 검증 → 확인 후 백업 삭제.

**`ENCRYPTION_PREVIOUS_KEYS` 설명**: encryptable 복호화 시 먼저 현재 `ENCRYPTABLE_KEY`를 사용하고, 실패하면 목록 순서대로 과거 키를 하나씩 시도. 따라서 **로테이션 시 이전 key를 새 key가 적용되기 전에 이 목록에 추가해야 하며**, 그렇지 않으면 재시작 후 이전 데이터를 복호화할 수 없음（데이터는 유실되지 않고, .env 롤백으로 복구 가능）. 목록은 추가만 가능하며, 과거 key 삭제 전에 모든 이전 데이터가 재암호화 완료됐는지 반드시 확인.

**자동 데이터 마이그레이션 없음**: 로테이션 후 이전 데이터는 여전히 이전 key로 암호화되어 정상 읽기/쓰기 가능. 새 key로 기존 데이터를 다시 쓰려면 데이터 마이그레이션 작업을 별도 실행（테이블별 읽기 → 쓰기로 재암호화 트리거）.

### 2.3 Fail-fast 시작 검증

다음 설정은 서비스 시작 시 검증되며, 키가 **누락 또는 여전히 `change-me` 플레이스홀더**면 `RuntimeException`을 던져 시작을 거부합니다（플레이스홀더 키로 배포 방지）:

| 설정 | 검증 키 |
|---|---|
| `service/config/encryption.php` | `ENCRYPTION_KEY` |
| `service/config/encryptable.php`、`service/config/plugin/erikwang2013/encryptable/app.php` | `ENCRYPTABLE_KEY` |
| `service/config/jwt.php`、`service/config/plugin/erikwang2013/jwt/jwt.php` | `JWT_SECRET_KEY` |

시작 오류 예시: `ENCRYPTABLE_KEY 未配置或仍为占位符，请在 .env 中配置 32 字节随机密钥`.

**일상 작업 체크리스트**:

1. 새 환경 배포: `cp .env.example .env` → `change-me` 플레이스홀더 줄 삭제 → `php scripts/gen_env_keys.php --file=.env` → 서비스 시작으로 키 오류 없음 확인.
2. 정기 로테이션: 2.2대로 실행, 분기 1회면 충분（강제 주기 없음, 유출 시 즉시 로테이션）.
3. 백업된 `.env.bak.*`에는 평문 키가 포함되므로 DB 백업과 동일하게 취급（권한 600, 원격 보관）.

## 3. 모니터링 알림（Prometheus + Grafana）

`admin/docker-compose.yml`에 편성됨（prometheus / grafana / redis-exporter 3개 서비스 추가）, 설정은 모두 `admin/deploy/monitoring/`:

```bash
cd admin
docker compose up -d prometheus grafana redis-exporter
# Prometheus: http://host:9090   Grafana: http://host:3000
# 首次登录 Grafana: admin / ${GRAFANA_ADMIN_PASSWORD}（默认 change-me-grafana-password）
```

- **데이터 소스**: Grafana 시작 시 Prometheus 데이터 소스 자동 설정（provisioning）, 패널은 UI에서 생성.
- **알림 규칙**: `deploy/monitoring/alerts.yml`, 커버:
  - `AppDown`（애플리케이션 도달 불가, 전체 5xx와 동급）— critical
  - `MysqlDown` / `RedisDown`（애플리케이션측 탐지 실패）— critical
  - `ElasticsearchDown`（ES 네이티브 `/_prometheus/metrics` 수집 실패）+ `ElasticsearchHealthYellow`（클러스터 비그린）— critical/warning
  - `QueueBacklog`（scout 검색 큐 `queues:scout_*` 적체 >100건 10분 지속）— warning
- **ES 비밀번호 주입**: prometheus가 compose `secrets`로 `ELASTIC_PASSWORD` 읽음（Docker Compose ≥ 2.24 필요）, 설정 파일에 비밀번호 하드코딩 없음; 미설정 시 change-me 플레이스홀더 사용, ES 수집 401이 ElasticsearchDown 트리거.
- **규칙 리로드**: alerts.yml 수정 후 `curl -X POST localhost:9090/-/reload`（prometheus에 `--web.enable-lifecycle` 필요, 기본 미적용 시 컨테이너 재시작）.
- **로컬 검증**: `bash scripts/verify_monitoring.sh` — admin/service 양측 알림 규칙 YAML 문법 검증, 양쪽 `/metrics`（admin:8787 / service:8788）지표 출력 curl, Prometheus（9090/9091）규칙 로드 확인; 애플리케이션/Prometheus 미실행 시 해당 항목 SKIP 표시 후 exit 0.

**상태**: admin과 service 모두 `/metrics` 엔드포인트 보유（MetricsController, 인증 불필요）. MetricsCollector 미들웨어가 `code="all"|"5xx"`로 실제 누적 집계（admin은 `open_admin_http_requests_total` 출력, service는 `property_service_http_requests_total` 출력）, 양측 alerts.yml의 `Http5xxRatio` 규칙（5xx 비율 >5% 10분 지속）이 바로 적용 가능. **알림 실측은 배포 대기**: 규칙은 준비됐지만 아직 실제 배포 환경에서 트리거 검증되지 않음（`verify_monitoring.sh`와 Prometheus 온라인에 의존）.

## 4. 로그 로테이션

- **컨테이너 로그**: compose의 모든 서비스가 `json-file` + `max-size 10m / max-file 3` 설정 완료, 별도 처리 불필요.
- **호스트 애플리케이션 로그**（`runtime/*.log`、`service/workerman.log`）: `admin/deploy/logrotate/pmp-app` 사용:

```bash
sudo cp admin/deploy/logrotate/pmp-app /etc/logrotate.d/pmp-app
# 按实际部署路径修改文件内的路径后生效；copytruncate 使 webman 免重启轮转
sudo logrotate -d /etc/logrotate.d/pmp-app   # 试运行检查
```

기본 매일 로테이션, 30일 보관, gzip 압축.

## 5. 배포 후 부하 스모크

배포 완료 후 k6로 로그인 체인과 핵심 비즈니스 인터페이스 도달 가능 여부를 스모크 검증합니다（저속도, 성능 부하 테스트 아님）. 스크립트: `scripts/loadtest/smoke.js`（기본 2 VU, 30s, 로그인 + dashboard, 모두 `BASE_URL`/`VUS`/`DURATION`/`TOKEN` 환경 변수 오버라이드 지원）.

### 5.1 로컬 스모크

```bash
cd /path/to/property-management-platform/scripts/loadtest

# 只探测登录체인（无需 token；422 验证码错误/429 限流均属防御生效，视为可达）
k6 run -e BASE_URL=http://127.0.0.1:8790 smoke.js

# 含鉴权业务接口：在部署服务器上签发压测 JWT（依赖 admin/.env 与 vendor）再传入
TOKEN=$(php mint-token.php)
k6 run -e BASE_URL=https://admin.example.com -e TOKEN="$TOKEN" smoke.js

# 自定义并发/时长
k6 run -e BASE_URL=https://admin.example.com -e TOKEN="$TOKEN" -e VUS=5 -e DURATION=60s smoke.js
```

전체 부하 테스트（login + dashboard + fee 3개 스크립트）는 여전히 `bash scripts/loadtest/run.sh [BASE_URL] [VUS] [DURATION]`.

### 5.2 CI 스모크（GitHub Actions 수동 트리거）

저장소 Actions 페이지 → **Loadtest Smoke** → **Run workflow**:

| 입력 | 필수 | 설명 |
|---|---|---|
| `target_url` | 예 | 테스트 환경 주소, 예: `https://admin.example.com` |
| `duration` | 아니요 | 스모크 시간, 기본 `30s` |
| `token` | 아니요 | 부하 테스트 JWT; 비워두면 로그인 체인만 탐지 |

token 획득（배포 서버 저장소 루트에서 실행, `admin/.env`와 `admin/vendor/` 필요）:

```bash
php scripts/loadtest/mint-token.php
```

> 주의: token은 부하 테스트 전용 JWT（기본 erik 관리자 계정）로 workflow 로그에 평문 노출되므로, 부하 테스트 전용 계정으로 발급하세요; 프로덕션에서 노출이 곤란하면 5.1 로컬 스모크로 대체.
