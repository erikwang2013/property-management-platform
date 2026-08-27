# 데이터베이스 복구 훈련 매뉴얼（Recovery Runbook）

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
> 적용: property-management-platform（admin측 + service측, MySQL 8.0）
> [OPS_RUNBOOK.md](OPS_RUNBOOK.md) 제1절과 함께 읽기: 백업 생성, crontab, RPO/RTO는 OPS_RUNBOOK 참조, 본 문서는 "복구 방법, 검증 방법"만 다룹니다.

## 0. 목표

- **훈련 목표: 30분 안에 전체 복구 훈련 1회 완료**（복구 + 검증）, 분기 1회 이상.
- 언제든 최근 백업 1건을 확보하면 본 문서대로 빈 DB 또는 지정 시점으로 복구 가능.

선행 조건:

- 백업 파일 사용 가능: `scripts/backup.sh`가 cron으로 실행 중（OPS_RUNBOOK 1.2 참조）.
- 복구 대상 환경（훈련 머신 또는 프로덕션 머신）이 프로덕션과 동형: 동일 docker-compose, 동일 버전 MySQL 8.0.
- 복구 전 확인: `gzip -t 백업파일` 통과; 디스크 여유 공간 ≥ 백업 용량 2배.

## 1. 시나리오 A: 빈 DB로 복구（가장 흔함, 훈련 기본 시나리오）

목표: 백업을 완전히 새로운 빈 DB로 가져와 데이터 사용 가능 여부 검증.

```bash
cd /path/to/property-management-platform

# 1) 选取最近一份备份
ls -lt backups/backup_*.sql.gz | head

# 2) 完整性检查（不通过则换更早的备份）
gzip -t backups/backup_20260816_020000.sql.gz && echo OK

# 3) 确认目标容器在跑
docker compose -f admin/docker-compose.yml ps mysql

# 4) 建空库（演练库名加 _drill 后缀，避免误覆盖生产数据）
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot -e "CREATE DATABASE IF NOT EXISTS management_drill DEFAULT CHARACTER SET utf8mb4;"'

# 5) 导入（-T 关闭 TTY，保证非交互；实测约 1-5 分钟）
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot --default-character-set=utf8mb4 management_drill' \
  < backups/backup_20260816_020000.sql.gz
```

> 자격 증명 안내: `MYSQL_PWD`는 `admin/.env`의 `DB_PASSWORD` 사용; 프로덕션에서 shell 히스토리에 평문 노출 금지, `--env-file admin/.env` 또는 환경 변수 주입 권장. 본 매뉴얼 예시는 훈련 환경 약정값.

## 2. 시나리오 B: 지정 시점 복구（binlog 리플레이）

전제: MySQL 8 기본 binlog 활성화（`log_bin=ON`）, 백업 시점 이후 증분은 전부 binlog에 있음. 데이터 손실 ≤ 최근 백업 + binlog 보존 기간（기본 `binlog_expire_logs_seconds=2592000`, 30일）.

방식: 전체 복구 → binlog 시작점 찾기 → `mysqlbinlog`로 목표 시점까지 리플레이.

```bash
# 1) 确认 binlog 开启，列出日志文件
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot -e "SHOW VARIABLES LIKE \"log_bin\"; SHOW BINARY LOGS;"'

# 2) 全量恢复（同场景 A 第 4-5 步，恢复到空库）

# 3) 找备份对应的 binlog 起点：备份文件里记录的位置（--master-data=2 时）
#    本脚本未带 --master-data，起点用"备份开始时刻"，误差在备份时长内。
#    回放 binlog 到目标时间点（示例：恢复到 2026-08-16 10:30:00）
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysqlbinlog --stop-datetime="2026-08-16 10:30:00" /var/lib/mysql/binlog.000012 | mysql -uroot management_drill'
```

요점:

- binlog는 컨테이너 내 경로 `/var/lib/mysql/binlog.0000NN`, `SHOW BINARY LOGS` 출력에서 대조.
- "백업 시작 시점 이후"의 binlog만 리플레이; 리플레이 후 즉시 검증（제3절 참조）, `max(updated_at)`이 기대와 일치 확인.
- 초 단위 정밀 오조작 복구: 먼저 오조작 문장 위치 확인 `mysqlbinlog /var/lib/mysql/binlog.0000NN | grep -n "오조작 키워드"`, 그 다음 `--stop-datetime` 또는 `--stop-position` 결정.

## 3. 데이터 일관성 검증（복구 후 필수）

| 검사 항목 | 명령 | 통과 기준 |
|---|---|---|
| 백업 파일 무결성 | `gzip -t <백업>` | 오류 없음 |
| 핵심 테이블 행 수 | `SELECT COUNT(*) FROM management_admin_user;` | 백업 전 기록 행 수와 일치 |
| 비즈니스 테이블 표본 조사 | `SELECT COUNT(*) FROM management_owner;`、`management_tenant`、`management_fee_bill`、`management_repair_order` | 3개 이상 수량급 합리적（0이 아니고 백업 전과 일치） |
| 암호화 필드 복호화 가능 | encryptable 필드 포함 레코드 1건 조회（예: `management_owner` 주민등록번호/휴대폰） | 값 정확, 애플리케이션 로그에 decrypt 오류 없음 |
| 업무 스모크 | 로그인, 목록 인터페이스 각 1회 | 200 / 정상 반환 |

표본 조사 스크립트 예시（훈련 환경）:

```bash
docker compose -f admin/docker-compose.yml exec -T -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot management_drill -e "
    SELECT (SELECT COUNT(*) FROM management_admin_user) AS users,
           (SELECT COUNT(*) FROM management_owner) AS owners,
           (SELECT COUNT(*) FROM management_tenant) AS tenants,
           (SELECT COUNT(*) FROM management_fee_bill) AS fee_bills,
           (SELECT COUNT(*) FROM management_repair_order) AS repair_orders;"'
```

> 행 수 일치: 백업 전 동일 SQL로 베이스라인 기록, 복구 후 비교; 훈련 시 베이스라인을 훈련 기록에 작성.

## 4. 30분 훈련 일정

| 시간 | 동작 | 담당 |
|---|---|---|
| 0-5 min | 백업 선택, `gzip -t`, 빈 DB 생성, 베이스라인 행 수 기록 | 운영 |
| 5-15 min | 시나리오 A 복구 가져오기 | 운영 |
| 15-25 min | 제3절 일관성 검증 + 업무 스모크 | 운영 + 업무 |
| 25-30 min | 결과 기록, 훈련 DB 정리（`DROP DATABASE management_drill`）, OPS_RUNBOOK 1.4 실측 RTO 업데이트 | 운영 |

## 5. 실패 처리

| 증상 | 처리 |
|---|---|
| `gzip -t` 실패 | 백업 손상, 더 이전 백업으로 교체, 더 큰 RPO 수용, 백업 cron 정상 여부 확인 |
| 가져오기 오류（문자셋/권한） | `--default-character-set=utf8mb4`와 빈 DB 문자셋 일치 확인; 사용자 테이블 생성 권한 확인 |
| 행 수가 베이스라인과 불일치 | 즉시 훈련 중단, 잘못된 DB/파일 가져왔는지 확인; 프로덕션 복구 상황이면 계속 조사하고 애플리케이션 롤백 |
| binlog 리플레이 후에도 데이터 부족 | `--stop-datetime`이 백업 시작 시점보다 늦은지 확인; 백업 이후 첫 binlog부터 리플레이 시작 확인 |

## 6. 훈련 기록 템플릿

```text
日期: 2026-08-16
恢复目标: 空库（场景 A）/ 时间点（场景 B）
备份文件: backups/backup_20260816_020000.sql.gz
基线行数: management_admin_user=1, management_owner=42, management_fee_bill=128
恢复耗时: XX 分钟    验证耗时: XX 分钟    总计: XX 分钟（目标 ≤ 30）
结果: 通过 / 失败（附失败原因与处理）
```
