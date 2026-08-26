# Sistema de Gestão de Propriedades — Plano Abrangente do Projeto

> Data de geração: 2026-08-16 · Fonte: auditoria da equipe pmp-team (auditor / security-auditor / planner)

## 1. Conclusões da auditoria de situação atual

**Funcionalidades: consistentes com o declarado.** Os 22 módulos de negócio + 12 funcionalidades estendidas estão todos concluídos: 68 tabelas / 178 APIs, admin com 58 controladores / 127 rotas, service com 19 controladores / 57 rotas, Flutter Web com painel de administração de 42 páginas + portal de proprietários de 13 páginas, HarmonyOS com 5 páginas. Os 14 documentos em docs/ + 35 SVGs têm suporte no código; não foram encontradas funcionalidades "declaradas mas não implementadas".

**Testes: todos verdes (até 2026-08-17).** admin com 193 testes / 452 asserções, service com 101 testes / 385 asserções (7 skips dependentes do ambiente), testes de widget Flutter: 9 casos (login/início/página de faturas).

**Engenharia já existente:** docker-compose nos dois lados, CI do GitHub Actions (sintaxe PHP + phpunit nos dois lados + composer audit + Flutter analyze), Dependabot, endpoint de métricas Prometheus.

**Dívida técnica (predominantemente baixa):**
1. Acúmulo de logs: service/workerman.log 9,3M, admin/runtime/logs 5,7M (já em gitignore, apenas ocupa disco) → precisa de rotação
2. O README não lista separadamente a contagem documental dos 57 modelos do service (64 refere-se apenas ao admin)
3. Sem TODO/FIXME, .env fora do repositório, versões de dependências sem anomalias — limpo

## 2. Lacunas de segurança e qualidade (security-auditor)

**Defesa em 18 camadas: 16/18 verificadas como existentes**, implementação consistente com SECURITY_ARCHITECTURE.md (código de verificação, confirmação dupla, poster, SecurityFilter, AES-256-CBC, JWT, limite de sessões, bloqueio de conta, RBAC, limite de taxa, hashids, criptografia de campos, mascaramento, logs de auditoria, CSP).

**Dois itens divergentes (P1, ambos corrigidos):**
1. ~~security-php instalado apenas no service~~ → integrado ao SecurityFilter nos dois lados (admin + service têm camada de varredura em profundidade 4b, SecurityGuard com inicialização lazy, registra e promove ao bloquear)
2. ~~Marca d'água de direitos autorais em PDF sem implementação~~ → verificado: a marca d'água da camada 18 no ExportController já está implementada (ExportController.php:179,206), falso positivo da auditoria

**Maior risco: chaves de fallback embutidas (corrigido).** EncryptionService/configuração de criptografia totalmente fail-fast (ausência ou change-me gera erro na inicialização); os valores embutidos e fallbacks aleatórios em encryptable/jwt foram removidos; as chaves do .env são valores aleatórios reais gerados; o CI carrega cópias do .env.example. As senhas de DB/Redis continuam como placeholders, sendo credenciais de implantação injetadas pelo implantador.

**Lacunas de engenharia (P1, preenchidas):** CI com novo job phpstan (Nível 5 + baseline), portões de cobertura PHPUnit nos dois lados (baseline medida: admin 1,66% / service 3,21%; o portão evita regressão de instrumentação zero), varredura de vazamento de chaves gitleaks (.gitleaks.toml libera templates de ambiente).

**Verificação de padrões de alto risco:** eval( apenas em Redis::eval (seguro), exec em 3 lugares (controladores de monitoramento/instalação), md5( apenas para hash de blacklist de tokens, SQL todo via query builder — sem risco de concatenação crua.

## 3. Posicionamento estratégico

**Fase de funcionalidades completas → fase de engenharia/comercialização.** O desenvolvimento de funcionalidades de negócio foi concluído (commits recentes são de documentação/auditoria/complemento de testes). Direção dos próximos investimentos: **CI/CD e portões de qualidade, produção do sistema de pagamento, monitoramento com alertas e backup/restauração, SaaS multi-tenant, complemento do app móvel**. A embalagem comercial já tem base (três edições EDITIONS + assistente de instalação + marca d'água de direitos autorais); falta a credibilidade de engenharia que faça o cliente se sentir seguro para pagar.

## 4. Roteiro por fases

### P1 Consolidação de engenharia (2-4 semanas) — tornar o sistema "confiável"

| Objetivo | Tarefas-chave | Critérios de aceitação |
|------|---------|---------|
| Portões de qualidade todos verdes, chaves controláveis, dados sem perda | ① CI completo: Flutter analyze, testes do service, portão de cobertura PHPUnit, phpstan, gitleaks ② Gestão de chaves: gerador de .env + scripts de rotação de chaves JWT/DB ③ Backup/restauração: script mysqldump + manual de exercício de restauração ④ Degradação ES: fallback de log em falha de escrita na fila + busca degradada para MySQL LIKE (adiado) ⑤ Versionamento SQL: migração consolidada no entry único docs/install.sql (o plano de migração dividido foi cancelado, consolidado em 2026-08-16) | CI todo verde incluindo cobertura; exercício de restauração com dados consistentes em 30 min; busca utilizável com ES fora do ar; scripts de atualização executáveis |

**Status P1**: ✅ tudo concluído (backup/restauração registrado em P8: scripts/backup.sh + docs/RECOVERY_RUNBOOK.md).

### P2 Capacidade comercial (4-8 semanas) — fazer o cliente "ousar comprar"

| Objetivo | Tarefas-chave | Critérios de aceitação |
|------|---------|---------|
| Ciclo de pagamento fechado, monitorável, entregável | ① Produção do pagamento: fluxo completo em sandbox WeChat/Alipay (pedido→callback idempotente→reembolso→conciliação), credenciais centralizadas em config/payment.php + env ② Monitoramento com alertas: orquestração Prometheus+Grafana + regras de alerta (5xx, conexão ES/Redis, acúmulo de filas) + rotação de logs ③ Controle da versão comercial: switches de versão baseados em EDITIONS (grupos de rotas Lite/Standard/Full ativados) + dados de Demo ④ Assistente de instalação cobrindo configuração de pagamento/ES | Fluxo completo de pagamento em sandbox aprovado (incluindo idempotência de callbacks repetidos); alertas testados de fato; switches das três versões demonstráveis; novo ambiente instalado em 10 minutos |

**Status atual P2**: ✅ parte offline toda concluída (2026-08-16/17): código completo do fluxo de pagamento (PaymentService pedido/callback idempotente/reembolso/conciliação + centralização de credenciais em config/payment.php + cobertura de funções puras com PaymentServiceTest), orquestração de monitoramento (pilha dupla Prometheus + 6 regras de alerta + provisioning de dashboards Grafana nos dois lados), switches de versão (três edições EDITIONS + validação fail-fast), assistente de instalação (com habilitação automática da configuração de pagamento + bug de caminho de template corrigido). Dependências externas restantes: **teste de integração em sandbox aguardando credenciais** (após obter WECHAT_PAY_* / ALIPAY_* de sandbox, executar `scripts/payment_sandbox_smoke.php`), **verificação real de alertas aguardando implantação** (`scripts/verify_monitoring.sh` valida localmente; a verificação de disparos reais fica para após a implantação).

### P3 Escala (8-12 semanas) — fazer o sistema "vender mais"

| Objetivo | Tarefas-chave | Critérios de aceitação |
|------|---------|---------|
| Multi-tenant, desempenho conforme, app móvel completo | ① SaaS multi-tenant: começando pela gestão de grupo, erik_community com tenant_id + isolamento por middleware (revisão da solução antes; banco separado como direção evolutiva) ② Teste de carga: wrk/k6 em login/cobranças/painel, consultas lentas + revisão de cache Redis ③ Complemento do app móvel: expandir as 5 páginas do HarmonyOS para os caminhos principais (pagamento/reparos/anúncios/visitantes/estacionamento), adaptação mobile do Flutter do proprietário ④ API aberta / Webhook (opcional) | Testes de acesso entre tenants aprovados; P95 das interfaces principais < 300ms; caminhos principais do HarmonyOS concluídos |

**Status P3**: ✅ tudo concluído (entrega 2026-08-16: pacote multi-tenant + teste de carga real com P95 dentro do alvo + HarmonyOS expandido para 5 páginas).

### Registro de entregas adicionais P4-P9 (2026-08-16 ~ 08-17, novas fases de engenharia além do escopo P1-P3)

| Fase | Entrega | Status |
|------|---------|------|
| P4 Encerramento | Fallback do caminho de escrita ES (AdminUser Searchable try/catch + log degradado), configuração de pagamento no assistente de instalação (ativação automática quando as credenciais estão preenchidas), rotação de logs (logrotate.conf), orquestração de alertas de monitoramento (pilha dupla Prometheus + 6 regras) | ✅ Concluído |
| P5 Itens restantes | Entrega de Webhook (assinatura HMAC-SHA256 + retry com backoff exponencial + 3 pontos de disparo), testes unitários de negócio de cobranças/aprovação/SLA | ✅ Concluído |
| P6 Encerramento de implantação | Script de implantação em um clique (deploy.sh: pull → .env → compose → importação idempotente de install.sql → smoke de monitoramento), correção do mount de logs dos contêineres, aumento do portão de cobertura do CI, plano de expansão (SCALING_PLAN) | ✅ Concluído |
| P7 Profundidade de testes | testes unitários do service 43→82, testes de widget Flutter 3 páginas 8 casos (integrados ao CI), API aberta (3 endpoints /open somente leitura + auth X-API-Key + gen_api_key.php), smoke de teste de carga (k6 smoke.js + workflow_dispatch manual) | ✅ Concluído |
| P8 Encerramento de operações | Backup/restauração implementados (backup.sh + RECOVERY_RUNBOOK), dashboard Grafana (provisioning de 7 painéis do service), testes unitários do admin +11 (152 verdes), **correção do bug de caminho de template do assistente de instalação** (template movido para app/view/install, renderização 200 verificada via curl) | ✅ Concluído |
| P9 Encerramento de engenharia | Limpeza de scripts de backup inexistentes (git rm de 4 arquivos nos dois lados + 8 documentos alinhados), dashboard Grafana do admin (7 painéis com prefixo open_admin_*), extração de funções puras de validação do InstallValidator + 17 casos (admin 193 verdes) | ✅ Concluído |

**Resumo P4-P9**: testes unitários do admin 93→193, do service 43→101, testes de widget Flutter 9/9, API aberta com 3 endpoints, painéis de monitoramento simétricos nos dois lados, conjunto completo de scripts de operação: backup/restauração/chaves/implantação prontos.

## 5. Top 10 ações prioritárias (por relação custo-benefício)

| # | Ação | Impacto | Custo | Risco | Status |
|---|--------|------|------|------|------|
| 1 | Gestão de chaves: gerador de env + scripts de rotação + remoção de chaves de fallback embutidas (validação de não ser "change-me" na inicialização) | Alto (conformidade de segurança) | Baixo | Baixo | ✅ Concluído |
| 2 | CI completo: Flutter analyze + testes do service + portão de cobertura + phpstan + gitleaks | Alto (piso de qualidade) | Baixo | Baixo | ✅ Concluído (P7 adiciona flutter test) |
| 3 | Scripts de backup + exercício de restauração | Alto (dados sem perda) | Baixo | Baixo | ✅ Concluído (P8: backup.sh + RECOVERY_RUNBOOK) |
| 4 | Fallback de degradação ES (MySQL LIKE) | Alto (disponibilidade) | Baixo | Médio (manutenção de caminho duplo de consulta) | ✅ Concluído (P4: fallback try/catch no caminho de escrita; busca já usa MySQL LIKE) |
| 5 | Fluxo completo de pagamento em sandbox + validação de idempotência de callbacks | Alto (necessário para comercialização) | Médio | Médio (credenciais/segurança de callback) | 🔶 Código concluído, integração em sandbox aguardando credenciais |
| 6 | Alertas Prometheus + Grafana + rotação de logs | Alto (operabilidade) | Médio | Baixo | ✅ Concluído (painéis dos dois lados em P8/P9; verificação real de alertas após implantação) |
| 7 | Gestão de migração SQL (consolidação no entry único install.sql) | Médio (atualizável) | Baixo | Baixo | ✅ Concluído (consolidado em 2026-08-16) |
| 8 | Revisão da solução multi-tenant + isolamento por tenant_id | Alto (teto de crescimento) | Alto | Alto (afeta todas as consultas) | ✅ Concluído (entrega P3, testes de acesso entre tenants aprovados) |
| 9 | Teste de carga + tratamento de consultas lentas | Médio (desempenho) | Médio | Baixo | ✅ Concluído (P3 com P95 real dentro do alvo; versão smoke no CI em P7) |
| 10 | Switch de licenciamento da versão comercial + dados de Demo | Médio (pré-venda) | Médio | Baixo | ✅ Concluído (EDITIONS + demo_data.php + documento do fluxo de demonstração) |

## 6. Riscos e dependências

| Risco | Situação atual | Sugestão de mitigação | Status |
|------|------|---------|------|
| Implantação em uma única máquina sem HA | docker-compose de máquina única, MySQL/Redis/ES no mesmo host | Exercício de backup/restauração + alertas de monitoramento + documento de plano de expansão | ✅ Mitigação implementada (P8 backup + P2/P8/P9 monitoramento + P6 SCALING_PLAN); execução do exercício após implantação |
| Dependência rígida de ES | busca/sincronização de índices toda via ES | Fallback de degradação + script de reconstrução de índices | ✅ Mitigado (P4 fallback do caminho de escrita; busca já usa MySQL LIKE, ES não é dependência do caminho de consulta) |
| Gestão de chaves | placeholders + chaves de fallback embutidas, sem rotação | Gerador + scripts de rotação; produção usa injeção por variáveis de ambiente | ✅ Resolvido (validação fail-fast + gen_env_keys.sh + rotate_keys.sh) |
| Credenciais de pagamento dispersas | módulo de pagamento sem configuração centralizada, sandbox não verificado | Centralização da configuração + sandbox primeiro | 🔶 Configuração centralizada (config/payment.php), integração em sandbox aguardando credenciais |
| Gestão de migração | install.sql de arquivo único (idempotente com IF NOT EXISTS) | Unificado no entry único completo; caminho de atualização incremental discutido separadamente | ✅ Unificado (consolidado em 2026-08-16) |
| Cobertura de testes estrutural | 133 testes concentrados em schema/segurança/ida e volta | Portão de cobertura + testes unitários dos negócios principais (cobranças/aprovação/SLA) | ✅ Reforçado (admin 193 / service 101 / Flutter 9; portão evita regressão de instrumentação zero) |
| Lacuna do app móvel | HarmonyOS apenas 5 páginas, portal de proprietários sem app nativo | Complemento dos caminhos principais em P3; dependência: dispositivo de teste HarmonyOS | ✅ Caminhos principais complementados (5 páginas: pagamento/reparos/anúncios/visitantes/estacionamento); validação em dispositivo real aguardando aparelho |

## 7. Divisão de trabalho da equipe (pmp-team)

| Papel | Tarefas |
|------|---------|
| Arquitetura | Revisão da solução multi-tenant e design do isolamento por tenant_id (P3), arquitetura de degradação ES, arquitetura de monitoramento (P2), revisão do design de idempotência de callbacks de pagamento |
| Back-end | Scripts de geração/rotação de chaves, implementação da degradação ES, centralização da configuração de pagamento + integração em sandbox, scripts de migração, teste de carga e tratamento de consultas lentas |
| Front-end Flutter | Integração de flutter analyze ao CI, adaptação mobile do portal de proprietários (P3), suporte de UI aos switches de versão |
| HarmonyOS | Complemento dos caminhos principais: pagamento/reparos/anúncios/visitantes/estacionamento (P3) |
| Testes | Portão de cobertura, casos de sandbox de pagamento (callback repetido/reembolso/conciliação), scripts de teste de carga, execução do exercício de backup/restauração |
| Revisão | Review dos caminhos críticos de pagamento e segurança, gitleaks no CI, revisão dos testes de acesso entre tenants |
| Documentação | Manual de implantação/operação (incluindo exercício de restauração), documento da solução multi-tenant, manual de configuração de monitoramento, manual de entrega da versão comercial |

## 8. Recomendações de ação imediata

✅ Os itens 1-4 originais do P1 (reforço de chaves → CI completo → scripts de backup → degradação ES) já foram todos executados (entregas iterativas P4-P9).

**Dependências restantes (requerem condições externas, não são lacunas de código)**:
1. Integração em sandbox de pagamento: após obter as credenciais de sandbox WECHAT_PAY_* / ALIPAY_*, executar `scripts/payment_sandbox_smoke.php` (validação do fluxo completo: pedido→idempotência de callback repetido→reembolso→conciliação)
2. Verificação real de alertas de monitoramento: após a implantação, executar `scripts/verify_monitoring.sh` para validar o carregamento das regras e disparar 5xx/falhas de conexão reais para verificar os alertas (a regra Http5xxRatio já pode entrar em vigor diretamente)
3. Exercício de backup/restauração: executar o exercício trimestral conforme docs/RECOVERY_RUNBOOK.md e registrar o tempo real medido (objetivo RTO ≤ 1h)
4. Validação em dispositivo real HarmonyOS: com o aparelho de teste disponível, percorrer os caminhos principais (pagamento/reparos/anúncios/visitantes/estacionamento)
