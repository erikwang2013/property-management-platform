# Manual de operações (OPS Runbook)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
> Aplicável a: property-management-platform (admin + service, PHP 8.3 webman)

## 1. Backup e restauração do banco de dados

admin e service compartilham a mesma instância MySQL e o mesmo banco `property_management`; um único backup é suficiente. Entry unificado:

| Banco | Script de backup | Descrição |
|---|---|---|
| `property_management` | `scripts/backup.sh` | Lê a conexão de `admin/.env` (é possível sobrescrever o nome do contêiner com `--container=`), mysqldump dentro do contêiner por padrão |

Saída `backups/backup_YYYYMMDD_HHMMSS.sql.gz`, retenção padrão dos últimos 7 dias (`--keep-days=` ajustável).

### 1.1 Backup completo

```bash
cd /path/to/property-management-platform
bash scripts/backup.sh
```

### 1.2 Agendamento (crontab)

```cron
# Backup completo todos os dias às 02:00
0 2 * * * cd /path/to/property-management-platform && bash scripts/backup.sh >> /var/log/pmp-backup.log 2>&1
```

Recomendação de produção: montar o diretório de backups em disco independente/armazenamento remoto e verificar periodicamente a integridade dos arquivos de backup (`gzip -t`).

### 1.3 Processo do exercício de restauração (pelo menos trimestral)

1. Escolher o backup mais recente: `ls -t backups/backup_*.sql.gz`
2. Executar a restauração em **ambiente independente** (ou banco temporário): ver [RECOVERY_RUNBOOK.md](RECOVERY_RUNBOOK.md), cenário A (restauração em banco vazio) e cenário B (restauração em ponto no tempo).
3. Verificar:
   - Comparação de contagem de linhas: `SELECT COUNT(*) FROM erik_user;` consistente com o registro anterior ao backup
   - Campos criptografados decriptografam normalmente: consultar um registro com campo encryptable, valor correto, sem erros de decrypt nos logs
   - Smoke de negócio: login e listagem de interfaces funcionando normalmente
4. Registrar o tempo e o resultado do exercício (para avaliação de RTO).

> Manual completo do exercício (restauração em banco vazio / ponto no tempo / validação de consistência / cronograma de 30 minutos) ver [RECOVERY_RUNBOOK.md](RECOVERY_RUNBOOK.md).

### 1.4 Explicação de RPO / RTO

- **RPO (perda de dados aceitável)**: definido pela frequência de backup. Backup completo diário → RPO ≤ 24 horas, ou seja, no máximo se perde o último dia de dados. Para RPO menor, aumentar a frequência de backup (ex.: 2 vezes por dia) ou habilitar backup incremental com binlog.
- **RTO (tempo necessário para restaurar)**: depende do tamanho do banco e da velocidade de restauração, meta ≤ 1 hora (restauração + validação + reinício dos serviços). Atualizar o valor medido real após cada exercício.
- Contingência em falha de restauração: primeiro reverter o código da aplicação, depois tentar novamente com o backup utilizável mais recente; se o backup estiver corrompido, usar um backup mais antigo e aceitar RPO maior.

## 2. Gestão de chaves

O projeto depende de 5 chaves, todas em `.env` (admin e service são independentes, não compartilhar o mesmo conjunto):

| Variável | Tamanho | Uso |
|---|---|---|
| `ENCRYPTION_KEY` | 32 bytes | Criptografia de transmissão da API (config/encryption.php) |
| `ENCRYPTABLE_KEY` | 32 bytes | Criptografia de campos sensíveis do banco (plugin encryptable, **não compartilhar com ENCRYPTION_KEY**) |
| `JWT_SECRET_KEY` | 64+ bits | Assinatura JWT |
| `HASHIDS_SALT` | — | Criptografia/descriptografia de IDs |
| `HASHIDS_ALT_SALT` | — | Reserva de criptografia/descriptografia de IDs |

### 2.1 Gerar chaves

```bash
# Exibe 5 CHAVE=VALOR no stdout, pode ser adicionado diretamente ao .env
php scripts/gen_env_keys.php

# Escreve direto no .env: não sobrescreve chaves existentes, apenas adiciona as que faltam
php scripts/gen_env_keys.php --file=.env
```

> Se alguma chave do .env ainda for o placeholder `change-me`, exclua a linha antes de executar (o placeholder é considerado "já existente" e não será sobrescrito).

### 2.2 Rotação de chaves (encryptable)

```bash
bash scripts/rotate_keys.sh            # opera o .env do diretório atual por padrão
bash scripts/rotate_keys.sh /path/to/service/.env
```

O script faz automaticamente: backup do .env → gerar nova `ENCRYPTABLE_KEY` → adicionar a chave antiga em `ENCRYPTION_PREVIOUS_KEYS` (separada por vírgula, a mais recente na frente) → gravar a nova chave. Depois, manualmente conforme instruído: reiniciar o serviço → validar a descriptografia → após confirmação, excluir o backup.

**Explicação de `ENCRYPTION_PREVIOUS_KEYS`**: na descriptografia, o encryptable usa primeiro a `ENCRYPTABLE_KEY` atual; em caso de falha, tenta as chaves históricas em ordem. Portanto, **na rotação a chave antiga deve ser adicionada à lista antes da nova chave entrar em vigor**, caso contrário os dados antigos não podem ser descriptografados após o reinício (os dados não se perdem; basta reverter o .env). A lista só cresce; antes de remover chaves históricas, confirme que todos os dados antigos já foram re-criptografados.

**Sem migração automática de dados**: após a rotação, os dados antigos continuam criptografados com a chave antiga e funcionam normalmente para leitura/escrita. Para reescrever os dados existentes com a nova chave, executar separadamente uma tarefa de migração de dados (ler tabela por tabela → gravar para acionar a re-criptografia).

### 2.3 Validação fail-fast na inicialização

As configurações abaixo são validadas na inicialização do serviço; se a chave **estiver ausente ou ainda for o placeholder `change-me`**, será lançada uma `RuntimeException` recusando a inicialização (evita subir com chave placeholder):

| Configuração | Chave validada |
|---|---|
| `service/config/encryption.php` | `ENCRYPTION_KEY` |
| `service/config/encryptable.php`、`service/config/plugin/erikwang2013/encryptable/app.php` | `ENCRYPTABLE_KEY` |
| `service/config/jwt.php`、`service/config/plugin/erikwang2013/jwt/jwt.php` | `JWT_SECRET_KEY` |

Exemplo de erro na inicialização: `ENCRYPTABLE_KEY não configurada ou ainda placeholder; configure uma chave aleatória de 32 bytes no .env`.

**Checklist de operação diária**:

1. Implantar novo ambiente: `cp .env.example .env` → excluir as linhas com placeholder `change-me` → `php scripts/gen_env_keys.php --file=.env` → iniciar o serviço e confirmar que não há erro de chave.
2. Rotação de rotina: executar conforme 2.2, uma vez por trimestre é suficiente (sem período obrigatório; em caso de vazamento, rotacionar imediatamente).
3. Os arquivos `.env.bak.*` do backup contêm chaves em texto claro; tratar com o mesmo rigor do backup do banco (permissão 600, armazenamento remoto).

## 3. Monitoramento com alertas (Prometheus + Grafana)

Orquestrado em `admin/docker-compose.yml` (três novos serviços: prometheus / grafana / redis-exporter), configurações em `admin/deploy/monitoring/`:

```bash
cd admin
docker compose up -d prometheus grafana redis-exporter
# Prometheus: http://host:9090   Grafana: http://host:3000
# Primeiro login no Grafana: admin / ${GRAFANA_ADMIN_PASSWORD} (padrão change-me-grafana-password)
```

- **Fonte de dados**: o Grafana configura automaticamente a fonte Prometheus na inicialização (provisioning); os painéis são criados na UI.
- **Regras de alerta**: `deploy/monitoring/alerts.yml`, cobrindo:
  - `AppDown` (aplicação inacessível, equivale a 5xx em todo o site) — critical
  - `MysqlDown` / `RedisDown` (falha de detecção no lado da aplicação) — critical
  - `ElasticsearchDown` (falha de coleta do `/prometheus/metrics` nativo do ES) + `ElasticsearchHealthYellow` (cluster não está verde) — critical/warning
  - `QueueBacklog` (fila de busca scout `queues:scout_*` acumulando >100 itens por 10 minutos) — warning
- **Injeção da senha do ES**: o prometheus lê `ELASTIC_PASSWORD` via `secrets` do compose (requer Docker Compose ≥ 2.24); o arquivo de configuração não grava a senha fixa; quando não definida, usa o placeholder change-me e a coleta do ES com 401 dispara o ElasticsearchDown.
- **Recarregar regras**: após alterar o alerts.yml, `curl -X POST localhost:9090/-/reload` (o prometheus precisa de `--web.enable-lifecycle`; se não estiver habilitado por padrão, reiniciar o contêiner).
- **Validação local**: `bash scripts/verify_monitoring.sh` — valida a sintaxe YAML das regras de alerta dos dois lados (admin/service), faz curl nos `/metrics` dos dois lados (admin:8787 / service:8788) verificando a saída de métricas, e a carga das regras do Prometheus (9090/9091); quando a aplicação/Prometheus não está em execução, o item correspondente indica SKIP e sai com exit 0.

**Status**: admin e service já têm endpoint `/metrics` (MetricsController, sem autenticação). O middleware MetricsCollector acumula contadores reais por `code="all"|"5xx"` (admin emite `open_admin_http_requests_total`, service emite `property_service_http_requests_total`), e a regra `Http5xxRatio` dos alerts.yml dos dois lados (proporção de 5xx >5% por 10 minutos) pode entrar em vigor diretamente. **Disparo real de alertas aguardando implantação**: as regras estão prontas mas ainda não foram validadas por disparo em ambiente de produção real (depende do `verify_monitoring.sh` e do Prometheus em produção).

## 4. Rotação de logs

- **Logs dos contêineres**: todos os serviços do compose já estão configurados com `json-file` + `max-size 10m / max-file 3`, sem tratamento adicional.
- **Logs da aplicação no host** (`runtime/*.log`、`service/workerman.log`): usar `admin/deploy/logrotate/pmp-app`:

```bash
sudo cp admin/deploy/logrotate/pmp-app /etc/logrotate.d/pmp-app
# Ajustar os caminhos no arquivo conforme o caminho real de implantação; copytruncate permite rotacionar sem reiniciar o webman
sudo logrotate -d /etc/logrotate.d/pmp-app   # execução de teste
```

Padrão: rotação diária, retenção de 30 dias, compressão gzip.

## 5. Smoke de carga após a implantação

Após a implantação, usar k6 para validar a cadeia de login e a acessibilidade dos endpoints de negócio principais (baixa taxa, não é teste de performance). Script: `scripts/loadtest/smoke.js` (padrão 2 VU, 30s, login + dashboard, ambos suportam sobrescrita por variáveis de ambiente `BASE_URL`/`VUS`/`DURATION`/`TOKEN`).

### 5.1 Smoke local

```bash
cd /path/to/property-management-platform/scripts/loadtest

# Apenas detecta a cadeia de login (sem token; 422 erro de código de verificação / 429 limite de taxa são defesas em ação, considerados alcançáveis)
k6 run -e BASE_URL=http://127.0.0.1:8790 smoke.js

# Com endpoints autenticados: emitir JWT de teste no servidor de implantação (depende de admin/.env e vendor) e passar
TOKEN=$(php mint-token.php)
k6 run -e BASE_URL=https://admin.example.com -e TOKEN="$TOKEN" smoke.js

# Concorrência/duração personalizadas
k6 run -e BASE_URL=https://admin.example.com -e TOKEN="$TOKEN" -e VUS=5 -e DURATION=60s smoke.js
```

O teste de carga completo (três scripts: login + dashboard + fee) continua usando `bash scripts/loadtest/run.sh [BASE_URL] [VUS] [DURATION]`.

### 5.2 Smoke no CI (GitHub Actions, disparo manual)

Página Actions do repositório → **Loadtest Smoke** → **Run workflow**:

| Entrada | Obrigatória | Descrição |
|---|---|---|
| `target_url` | Sim | Endereço do ambiente testado, ex.: `https://admin.example.com` |
| `duration` | Não | Duração do smoke, padrão `30s` |
| `token` | Não | JWT de teste; vazio = apenas detecta a cadeia de login |

Obtenção do token (executar na raiz do repositório no servidor de implantação, requer `admin/.env` e `admin/vendor/`):

```bash
php scripts/loadtest/mint-token.php
```

> Atenção: o token é um JWT exclusivo para teste de carga (conta de administrador erik por padrão) e aparecerá em texto claro nos logs do workflow; emitir com uma conta dedicada a teste; se a produção não puder expor, usar o smoke local do 5.1.
