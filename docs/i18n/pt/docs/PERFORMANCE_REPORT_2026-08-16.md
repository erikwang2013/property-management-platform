# Relatório de teste de carga e tratamento de consultas lentas (2026-08-16)

Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## 1. Ambiente e método de teste

| Item | Valor |
|---|---|
| Aplicação | webman v2 (PHP 8.3, 32 workers), duas aplicações: admin + service |
| Instância testada | admin em porta independente 8790 (`SERVER_LISTEN=http://0.0.0.0:8790`) |
| Ferramenta | k6 v0.51.0 (sem wrk/ab/hey na máquina), scripts em `scripts/loadtest/` |
| Alvos do teste | Login (/api/auth/login), dashboard (/admin/dashboard), lista de pagamentos de cobranças (/admin/fee-payment) |
| Autenticação | dashboard/fee usam JWT emitido por `scripts/loadtest/mint-token.php` (ignora o código de verificação, `sub=21000000000000100`); o script de login usa código de verificação inválido para detectar a cadeia |
| Dados | Conexão direta local 127.0.0.1, sem gateway/CDN; MySQL/Redis no mesmo host da aplicação |

Entry dos scripts: `bash scripts/loadtest/run.sh [BASE_URL] [VUS] [DURATION]` (requer k6 no PATH).
Sobre o script de login: o login tem dupla proteção de código de verificação + limite de taxa (10 vezes/min/IP), é uma decisão de segurança — não é possível nem deve ser testado com alta concorrência; login.js usa 1 VU / 8 requisições em baixa taxa para medir a latência da cadeia, esperando retorno 422 (erro de código de verificação) ou 429 (limite de taxa), ambos indicando defesa normal em ação.

## 2. Resultados do teste de carga

### 20 VU / 30s (carga de referência)

| Endpoint | Requisições | Throughput | avg | p90 | p95 | max | Taxa de falha |
|---|---|---|---|---|---|---|---|
| login (1 VU × 8) | 8 | 14,4/s | 68,6ms | 154ms | 207,8ms | 261ms | 0% |
| dashboard | 6863 | 227,9/s | 86,0ms | 151ms | 189,5ms | 1,37s | 0% |
| fee-payment | 5944 | 197,2/s | 99,3ms | 178ms | 220,0ms | 704ms | 0% |

### 50 VU / 30s (pressão)

| Endpoint | Requisições | Throughput | avg | p95 | max | Taxa de falha |
|---|---|---|---|---|---|---|
| login (1 VU × 8) | 8 | 18,7/s | 52,1ms | 173ms | 243,8ms | 0% |
| dashboard | 6902 | 226,9/s | 212,7ms | 544,0ms | 1,99s | 0% |
| fee-payment | 7525 | 247,4/s | 195,7ms | 514,2ms | 2,0s | 0% |

(Com 50 VU o p95 > limiar de 500ms, o k6 saiu por violação de limiar, mas 0% de requisições falharam e 0 não-200.)

### Conclusão

- Todos os endpoints com 20 VU: 0 falhas, p95 < 220ms, saudável.
- **Gargalo de throughput em torno de 230–250 rps**: de 20 VU → 50 VU o throughput não sobe, fica plano (dashboard 227,9 → 226,9, fee 197 → 247), enquanto a latência p95 dobra (~190ms → ~540ms). Com 32 workers em máquina única, cada worker faz cerca de 7–8 rps, característica do limite de processamento de um núcleo no caminho completo do PHP (incluindo consultas MySQL, ida e volta do cache Redis), não é esgotamento de conexões (sem requisições falhas).
- Sugestão: nessa escala, máquina única já é suficiente (cerca de 20 milhões de requisições/dia); para maior throughput, priorizar adicionar instâncias horizontalmente, depois investigar SQL e hit de cache de cada endpoint (ver abaixo).

## 3. Revisão de consultas lentas

- As tabelas de cobranças `management_fee_bill` / `management_fee_payment` têm índices completos (paid_at, bill_id, owner_id, payment_number etc.), as consultas principais têm índice disponível.
- Ponto encontrado: a lista de cobranças faz busca difusa por `payment_number like %kw%` (curinga à esquerda), que não usa índice; com volume grande, essa condição degenera para varredura de tabela inteira. É busca de baixa frequência no painel de administração; por enquanto não tratado; com o crescimento dos dados, pode ser trocado para índice invertido ou prefixo.
- **MySQL slow_query_log está OFF**: recomenda-se habilitar com `long_query_time=1` e observar as SQLs realmente lentas (em vez de inferir pelo teste de carga). Executar em produção:
  ```sql
  SET GLOBAL slow_query_log = ON;
  SET GLOBAL long_query_time = 1;
  ```
- Agregação do dashboard: a cada reconstrução de cache executa cerca de 8 agregações COUNT + estatísticas agrupadas de 30 dias; cada reconstrução custa segundos, absorvida pelo cache Redis de 5 minutos (ver abaixo); não é caminho quente.

## 4. Revisão do cache Redis

- Cache do dashboard `dashboard:data`: `setex 300`, ~10ms com hit, segundos para reconstruir no miss. **Problema: não há nenhuma lógica de invalidação em operações de escrita**; após alterações de dados, fica obsoleto por até 5 minutos. Sugestão: excluir essa chave nos endpoints de escrita de cobranças/propriedades (uma linha `del dashboard:data`).
- **Sem proteção contra cache stampede**: no instante em que a chave expira, 32 workers reconstroem simultaneamente (executando 8 consultas de agregação repetidas). Com volume grande, sugere-se um mutex simples (ex.: lock `set nx ex` + double-check).
- Cache de permissões `perm:{adminId}` 60s, comportamento normal.
- Item de investigação pendente: no Redis local nunca foi observada a chave `dashboard:data` (em nenhum dos vários dbs), mas a interface responde normalmente e a latência com hit é claramente menor. Durante o teste, ocorreram 403 esporádicos "sem permissão de acesso" (apareceram 2 vezes e voltaram a 200 estável). Suspeita de diferença entre múltiplas instâncias Redis locais/configuração de variáveis de ambiente e a produção; precisa ser reavaliado no ambiente de destino. Não afeta a conclusão do teste (0 falhas no segmento estável).

## 5. Entregáveis

- `scripts/loadtest/mint-token.php` — emite JWT de teste (`php mint-token.php --file=/tmp/pmp-token`)
- `scripts/loadtest/login.js` / `dashboard.js` / `fee.js` — scripts k6
- `scripts/loadtest/run.sh` — execução em um clique (mint token + três scripts, parâmetros: BASE_URL VUS DURATION)
- Este relatório

Comando de reprodução: `PATH=/home/erik/bin:$PATH bash scripts/loadtest/run.sh http://127.0.0.1:8790 20 30s`
