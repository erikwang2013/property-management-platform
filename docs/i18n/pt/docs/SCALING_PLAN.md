# Plano de expansão (Scaling Plan)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

A implantação atual é docker-compose de máquina única (MySQL/Redis/Elasticsearch no mesmo host da aplicação, ver `admin/docker-compose.yml`), sem HA. Este documento explica os riscos e as mitigações existentes, e apresenta o caminho de expansão horizontal, os pontos de disparo por volume de dados e sugestões de exercícios. A linha de base de operações (backup/restauração, monitoramento com alertas, rotação de logs) está em [OPS_RUNBOOK.md](OPS_RUNBOOK.md).

---

## 1. Implantação atual e riscos

### 1.1 Situação atual

| Componente | Versão | Descrição |
|------|------|------|
| MySQL | 8.0.36 | Instância única, dados persistidos em volume do host |
| Redis | 7.2-alpine | Instância única, cache/queue/lock |
| Elasticsearch | 8.12.0 | Nó único, busca full-text via scout |
| nginx + webman | — | admin (8787) e service (8788) multiprocesso no mesmo host |
| Prometheus + Grafana | — | Monitoramento com alertas, mesmo host |

### 1.2 Lista de riscos

| Risco | Impacto | Probabilidade | Consequência |
|------|------|------|------|
| Ponto único de falha (qualquer middleware fora do ar) | Todo o site indisponível | Baixa | Alta |
| Disputa de disco/memória/CPU do host | Consultas lentas, ES travado, OOM | Média (aumenta com o crescimento dos dados) | Média |
| Corrupção irrecuperável da instância única do MySQL | Perda de dados | Muito baixa | Muito alta |
| Sem data center de contingência | Perda total em falha no nível do data center | Muito baixa | Muito alta |
| Backup/restauração sem exercício | Restauração com timeout ou falha | Média | Alta |

## 2. Mitigações existentes (já implementadas)

- **Backup**: script de backup de entry único `scripts/backup.sh` (lê a conexão de `admin/.env`, mysqldump dentro do contêiner por padrão), backup completo diário via crontab, retenção padrão de 7 dias (`--keep-days=30` configurável); o processo de exercício de restauração e a explicação de RPO/RTO estão em OPS_RUNBOOK §1 e RECOVERY_RUNBOOK.
- **Monitoramento com alertas**: Prometheus + Grafana + `deploy/monitoring/alerts.yml`, cobrindo AppDown / MysqlDown / RedisDown / ElasticsearchDown / QueueBacklog, ver OPS_RUNBOOK §3.
- **Rotação de logs**: logs dos contêineres `max-size 10m`, logs do host rotacionados diariamente pelo logrotate com retenção de 30 dias, ver OPS_RUNBOOK §4.
- **Camada de aplicação**: webman multiprocesso residente, tarefas de fila desacoplando operações demoradas, health check `/health`.

Conclusão: as mitigações acima cobrem "falha recuperável", **não cobrem "falha sem interrupção"**. Se o negócio não puder aceitar interrupção, é necessário entrar na expansão horizontal da §3.

## 3. Caminho de expansão horizontal (por prioridade)

Princípio geral da expansão: primeiro vertical (adicionar CPU/memória/disco) depois horizontal (separar componentes), primeiro middleware depois aplicação, cada etapa pode ser revertida de forma independente.

### 3.1 MySQL mestre-escravo + semissíncrono (primeira prioridade)

- Arquitetura: mestre (instância existente) → escravo (nova máquina), habilitar replicação semissíncrona (`rpl_semi_sync_master_enabled=1`).
- Expansão de leitura: configurar separação leitura/escrita na aplicação (habilitar quando `config/database.php` suportar; caso contrário, fazer apenas HA mestre-escravo primeiro).
- Migração de backup: o script de backup passa a apontar para o escravo, evitando pressionar o mestre.
- Versão: o escravo precisa ter a mesma versão principal do mestre (atualmente 8.0.36).
- Condição de upgrade: CPU do mestre continuamente >70%, número de conexões próximo de max_connections, aumento abrupto de linhas varridas no log de consultas lentas.

### 3.2 Redis sentinel ou cluster (segunda prioridade)

- Sentinel (3 nós): escolher sentinel quando a demanda de capacidade não é alta; failover em segundos, o cliente precisa suportar o modo `sentinel`.
- Cluster (≥3 mestres 3 escravos): escolher Cluster quando o volume de cache > memória de uma máquina, ou a concorrência de escrita aumenta.
- Atenção: queues e locks distribuídos dependem do Redis; ao trocar a topologia, é necessário ajustar `config/redis.php` em sincronia e validar o comportamento de locks/queues sob failover.

### 3.3 Nó independente do Elasticsearch

- ES de nó único não tem réplica; índice corrompido significa busca indisponível. Migrar pelo menos para máquina independente + 1 réplica.
- Após o crescimento dos dados, dividir por índice (por domínio de negócio), desligar réplicas de índices desnecessários para controlar recursos.
- Condição de upgrade: uso de heap >70% contínuo, rejeição de escrita (`es_rejected_executions` em alta), P95 de consulta acima de 1s.

### 3.4 Múltiplas réplicas da aplicação + balanceamento de carga (por último)

- admin/service cada um com 2+ réplicas, com nginx na frente para balanceamento de carga (round-robin ou least_conn).
- Pré-condição: sem estado (session no Redis, sem dependência de escrita em arquivo local; este sistema é JWT + session Redis, basicamente satisfeita).
- Depois, dobrar a capacidade de processamento pelo número de réplicas e voltar aos gargalos de middleware das §3.1-3.3.

## 4. Pontos de disparo por crescimento de dados e sugestões

| Ponto de disparo | Limiar sugerido | Ação obrigatória |
|--------|----------|----------|
| Volume total do banco | > 50GB ou tabela única > 50 milhões de linhas | Separação mestre-escravo + arquivamento de faturas/tabelas de log históricas |
| Consultas lentas | Média diária > 10 consultas lentas ou consulta única > 2s | Adicionar índices, particionar tabelas, verificar N+1 |
| Conexões MySQL | Continuamente > 80% do max_connections | Pool de conexões + mestre-escravo |
| Memória Redis | > 70% e crescendo continuamente | Limpar chaves expiradas → sentinel → Cluster |
| Heap ES | > 70% ou rejeição de escrita | Nó independente + réplica + divisão de índices |
| CPU | Núcleo único continuamente > 80% e fila acumulando | Múltiplas réplicas da aplicação → separação de middleware |
| Disco | > 80% | Limpar backups/logs, arquivar dados frios |

Sugestão: conferir a tabela acima mensalmente (os dados podem vir dos painéis do Grafana); se qualquer item ultrapassar o limiar por duas semanas consecutivas, iniciar a expansão correspondente.

## 5. Sugestões de exercícios de expansão

- **Trimestralmente**: exercício de restauração (ver OPS_RUNBOOK §1.3), validando o cumprimento de RPO/RTO.
- **Anualmente**: exercício de failover mestre-escravo (exercitar em máquina nova, não mexer no mestre de produção): criar escravo → alcançar o mestre → fazer switch → validar leitura/escrita nos dois lados → voltar.
- **Após a primeira expansão**: usar `scripts/loadtest` para testar os três caminhos (login/lista/busca) confirmando o P95 dentro do alvo (referência: `docs/PERFORMANCE_REPORT_2026-08-16.md`).
- **Registro do exercício**: registrar cada exercício no changelog (CHANGELOG.md), incluindo: data, item exercitado, resultado, problemas pendentes.

## 6. Referência rápida do caminho de upgrade

```
Máquina única (situação atual)
  ├─ MySQL mestre-escravo semissíncrono      ← primeira prioridade
  ├─ Redis sentinel/Cluster    ← segunda prioridade
  ├─ ES nó independente+réplica       ← terceira prioridade
  └─ Múltiplas réplicas da aplicação+LB          ← por último
        ↓
Implantação multi-máquina (sem ponto único, aceitável interrupção por falha → aceitável interrupção em minutos → failover em segundos)
```

> No volume de negócio atual não é necessária expansão; este documento serve para "seguir direto" quando o volume de dados/requisitos de falha mudarem, evitando decisões de última hora.
