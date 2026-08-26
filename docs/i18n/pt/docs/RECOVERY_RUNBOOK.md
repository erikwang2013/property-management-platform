# Manual de exercício de restauração do banco de dados (Recovery Runbook)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
> Aplicável a: property-management-platform (admin + service, MySQL 8.0)
> Ler em conjunto com a seção 1 do [OPS_RUNBOOK.md](OPS_RUNBOOK.md): geração de backup, crontab, RPO/RTO ver OPS_RUNBOOK; este documento trata apenas de "como restaurar, como validar".

## 0. Objetivo

- **Meta do exercício: concluir um exercício completo de restauração em 30 minutos** (restauração + validação), pelo menos trimestralmente.
- A qualquer momento, com o backup mais recente em mãos, é possível restaurar para banco vazio ou ponto no tempo conforme este documento.

Pré-condições:

- Arquivo de backup disponível: `scripts/backup.sh` já executado pelo cron (ver OPS_RUNBOOK 1.2).
- O ambiente de destino da restauração (máquina de exercício ou produção) é homólogo à produção: mesmo docker-compose, mesma versão MySQL 8.0.
- Antes de restaurar, confirmar: `gzip -t arquivo-de-backup` passa; espaço livre em disco ≥ 2× o volume do backup.

## 1. Cenário A: restaurar em banco vazio (mais comum, cenário padrão do exercício)

Objetivo: importar o backup em um banco vazio novo e validar a disponibilidade dos dados.

```bash
cd /path/to/property-management-platform

# 1) Escolher o backup mais recente
ls -lt backups/backup_*.sql.gz | head

# 2) Verificação de integridade (se não passar, usar um backup mais antigo)
gzip -t backups/backup_20260816_020000.sql.gz && echo OK

# 3) Confirmar que o contêiner de destino está em execução
docker compose -f admin/docker-compose.yml ps mysql

# 4) Criar banco vazio (sufixo _drill no nome do banco do exercício, evita sobrescrever dados de produção por engano)
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot -e "CREATE DATABASE IF NOT EXISTS property_management_drill DEFAULT CHARACTER SET utf8mb4;"'

# 5) Importar (-T desativa TTY, garante não interativo; na prática cerca de 1-5 minutos)
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot --default-character-set=utf8mb4 property_management_drill' \
  < backups/backup_20260816_020000.sql.gz
```

> Dica de credenciais: `MYSQL_PWD` vem do `DB_PASSWORD` do `admin/.env`; em produção é proibido aparecer em texto claro no histórico do shell; recomenda-se usar `--env-file admin/.env` ou injeção por variável de ambiente. Os exemplos deste manual usam valores de convenção do ambiente de exercício.

## 2. Cenário B: restaurar em ponto no tempo (replay de binlog)

Pré-requisito: MySQL 8 habilita binlog por padrão (`log_bin=ON`); o incremento após o momento do backup está todo no binlog. A perda de dados é ≤ último backup + período de retenção do binlog (padrão `binlog_expire_logs_seconds=2592000`, 30 dias).

Ideia: restauração completa → localizar o ponto inicial do binlog → `mysqlbinlog` para fazer replay até o ponto no tempo desejado.

```bash
# 1) Confirmar que o binlog está habilitado e listar os arquivos de log
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot -e "SHOW VARIABLES LIKE \"log_bin\"; SHOW BINARY LOGS;"'

# 2) Restauração completa (mesmos passos 4-5 do cenário A, restaurar em banco vazio)

# 3) Localizar o ponto inicial do binlog correspondente ao backup: a posição registrada no arquivo de backup (com --master-data=2)
#    Este script não usa --master-data; o ponto inicial é o "momento de início do backup", com erro dentro da duração do backup.
#    Replay do binlog até o ponto no tempo desejado (exemplo: restaurar até 2026-08-16 10:30:00)
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysqlbinlog --stop-datetime="2026-08-16 10:30:00" /var/lib/mysql/binlog.000012 | mysql -uroot property_management_drill'
```

Pontos importantes:

- O binlog está no caminho do contêiner `/var/lib/mysql/binlog.0000NN`; identificar pelo número correspondente na saída de `SHOW BINARY LOGS`.
- Replay apenas do binlog "posterior ao momento de início do backup"; validar imediatamente após o replay (ver seção 3), confirmando que `max(updated_at)` está conforme o esperado.
- Restauração de operação incorreta com precisão de segundos: primeiro localizar a instrução problemática `mysqlbinlog /var/lib/mysql/binlog.0000NN | grep -n "palavra-chave da operação incorreta"`, depois decidir entre `--stop-datetime` ou `--stop-position`.

## 3. Validação de consistência dos dados (obrigatória após a restauração)

| Item de verificação | Comando | Critério de aprovação |
|---|---|---|
| Integridade do arquivo de backup | `gzip -t <backup>` | Sem erros |
| Contagem de linhas das tabelas-chave | `SELECT COUNT(*) FROM erik_admin_user;` | Consistente com a contagem registrada antes do backup |
| Amostragem de tabelas de negócio | `SELECT COUNT(*) FROM erik_owner;`、`erik_tenant`、`erik_fee_bill`、`erik_repair_order` | Três ou mais com ordem de grandeza razoável (não 0 e consistentes com o antes do backup) |
| Campos criptografados decriptografam | Consultar um registro com campo encryptable (ex.: documento/telefone do `erik_owner`) | Valor correto, sem erros de decrypt nos logs da aplicação |
| Smoke de negócio | Login e listagem de interfaces, 1 vez cada | 200 / retorno normal |

Exemplo de script de amostragem (ambiente de exercício):

```bash
docker compose -f admin/docker-compose.yml exec -T -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot property_management_drill -e "
    SELECT (SELECT COUNT(*) FROM erik_admin_user) AS users,
           (SELECT COUNT(*) FROM erik_owner) AS owners,
           (SELECT COUNT(*) FROM erik_tenant) AS tenants,
           (SELECT COUNT(*) FROM erik_fee_bill) AS fee_bills,
           (SELECT COUNT(*) FROM erik_repair_order) AS repair_orders;"'
```

> Consistência de contagens: registrar a linha de base antes do backup com a mesma SQL; comparar após a restauração; registrar a linha de base no registro do exercício.

## 4. Cronograma do exercício de 30 minutos

| Tempo | Ação | Responsável |
|---|---|---|
| 0-5 min | Escolher backup, `gzip -t`, criar banco vazio, registrar contagem de linha de base | Operações |
| 5-15 min | Restauração/importação do cenário A | Operações |
| 15-25 min | Validação de consistência da seção 3 + smoke de negócio | Operações + Negócio |
| 25-30 min | Registrar resultado, limpar banco do exercício (`DROP DATABASE property_management_drill`), atualizar o RTO medido do OPS_RUNBOOK 1.4 | Operações |

## 5. Tratamento de falhas

| Sintoma | Tratamento |
|---|---|
| `gzip -t` falha | Backup corrompido; usar backup mais antigo, aceitar RPO maior, e verificar se o cron de backup está normal |
| Erro na importação (charset/permissões) | Confirmar `--default-character-set=utf8mb4` consistente com o charset do banco vazio; confirmar que o usuário tem permissão de criação de tabelas |
| Contagem diferente da linha de base | Parar o exercício imediatamente; verificar se importou o banco/arquivo errado; em cenário de restauração de produção, continuar investigando e reverter a aplicação |
| Dados ainda faltando após replay do binlog | Verificar se `--stop-datetime` é posterior ao momento de início do backup; confirmar que o replay começa no primeiro binlog após o backup |

## 6. Modelo de registro do exercício

```text
Data: 2026-08-16
Destino da restauração: banco vazio (cenário A) / ponto no tempo (cenário B)
Arquivo de backup: backups/backup_20260816_020000.sql.gz
Contagem de linha de base: erik_admin_user=1, erik_owner=42, erik_fee_bill=128
Tempo de restauração: XX minutos    Tempo de validação: XX minutos    Total: XX minutos (meta ≤ 30)
Resultado: aprovado / reprovado (anexar motivo da falha e tratamento)
```
