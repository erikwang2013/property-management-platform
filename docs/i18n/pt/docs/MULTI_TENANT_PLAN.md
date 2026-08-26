# Revisão da solução SaaS multi-tenant (Plano Multi-Tenant)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
> Status: documento de revisão (P3-① tarefa prévia) | Data: 2026-08-16

## 1. Inventário da situação atual

### 1.1 Classificação da estrutura de tabelas (65 tabelas, verificadas em docs/install.sql)

| Categoria | Tabelas | Descrição |
|------|-----|------|
| Tabelas globais/plataforma | erik_admin_user / admin_role / admin_permission / admin_user_role / admin_role_permission、erik_system_config、erik_operation_log | Autenticação, configuração, auditoria — naturalmente nível de plataforma, sem vínculo de tenant |
| Tabelas de dimensão de condomínio | erik_community e 40+ tabelas de negócio pertencentes via community_id (building/unit/room/owner/fee_*/repair_order/parking_*/announcement etc.) | Pertencem indiretamente ao tenant via community_id |
| Tabelas de grupo | erik_group (grupo)、erik_group_community (grupo↔condomínio) | Atualmente **associação opcional**, sem semântica de tenant, consolidação entre regiões via join |
| Tabelas de extensão da plataforma | erik_notification_template、erik_knowledge_base、erik_mall_*、erik_face_info etc. | Parte é nível de plataforma, parte é nível de condomínio, precisa de confirmação caso a caso |
| Tabela confusa | **erik_tenant (tabela de inquilinos)** | ⚠️ Conflito semântico: é "inquilino do imóvel" (dimensão room_id/owner_id), **não** é tenant SaaS |

### 1.2 Cadeia de autenticação (admin, verificada no código)

```
Middleware global: Cors → SecurityFilter → RateLimit
Middleware do grupo de rotas: AdminAuth(JWT → $request->adminId) → AdminPermission(RBAC method.path) → OperationLog → Controller
```

- `AdminAuth` já estabelece o padrão de injeção de request (`$request->adminId`), o contexto de tenant pode replicar completamente
- `AdminPermission` é RBAC de nível de plataforma, **ortogonal** ao isolamento de tenant, pode ser sobreposto
- Portal de proprietários do service: JWT carrega owner_id, os dados são naturalmente restritos via room_owner → room.community_id, risco baixo de acesso entre tenants

### 1.3 Conclusões-chave

- Não existe nenhum modelo de tenant SaaS pronto; o nome `erik_tenant` já está ocupado pelo inquilino de imóvel, o novo conceito deve evitar o nome
- Todos os controladores consultam diretamente com Eloquent, sem camada repository, sem escopos globais — a reforma de isolamento precisa ser feita na camada de modelos
- config/database.php tem conexão única, mas illuminate/database suporta nativamente múltiplas connections (reserva para evolução para bancos separados)

## 2. Comparação de soluções e recomendação

| Solução | Mecanismo | Volume de reforma | Custo operacional | Aplicável |
|------|------|--------|----------|------|
| **A. Banco compartilhado + isolamento por linha tenant_id (recomendada)** | Tabela de tenants + coluna tenant_id nas tabelas de negócio + filtro por escopo global do Eloquent | Médio (colunas em 2 tabelas + middleware + escopo global + backfill de dados existentes) | Baixo (backup/migração de banco único inalterados) | Pequenas e médias propriedades, tenant único <5 milhões de linhas |
| B. Banco separado (um banco por tenant) | Roteamento de conexão + agregação entre bancos | Alto (gestão de conexões/relatórios entre bancos/migração×N/backup×N) | Alto | Grandes grupos, requisitos de isolamento por conformidade |
| C. Híbrido (banco sensível separado + compartilhado) | Combinação A+B | Alto | Alto | Cenários de isolamento forte como pagamento/reconhecimento facial |

**Recomendação A, com B como direção evolutiva.** Motivos:

1. As 65 tabelas atuais estão unificadas em banco único; o modelo de dados com tenant_id de A não impede futura separação de bancos (a granularidade do filtro muda de linha para banco; no esquema A o ID do tenant já está modelado globalmente)
2. Os dados de negócio pertencem todos via community_id; o tenant_id só precisa ser adicionado nas **tabelas de topo**, as 40 tabelas de negócio intermediárias são garantidas pelo caminho de acesso, evitando adicionar colunas em cada tabela
3. Os dois lados (admin/service) compartilham o mesmo modelo de dados, a reforma de A se concentra na camada de execução do admin
4. Na implantação de máquina única atual, a complexidade de backup/migração de B é insuportável

## 3. Design dos pontos de isolamento

### 3.1 Modelo de dados (conjunto mínimo)

- Criar `erik_platform_tenant` (evitar conflito com a tabela de inquilinos erik_tenant): id/name/status/created_at etc.
- `erik_community` ganha `tenant_id BIGINT NOT NULL DEFAULT 0`, índice `(tenant_id, community_id)`
- `erik_admin_user` ganha `tenant_id BIGINT NOT NULL DEFAULT 0` (0 = superadministrador da plataforma)
- As tabelas intermediárias de negócio (building/room/fee_bill etc., 40 tabelas) **não ganham coluna**, pertencem via community_id

### 3.2 Conjunto de três peças na camada de execução

1. **Middleware TenantContext**: o payload do JWT ganha a declaração `tenant_id` → `$request->tenantId` (replicando o padrão de injeção do AdminAuth); lista de liberação para login/instalação/rotas de nível de plataforma (user/role/permission/config)
2. **Escopo global TenantScope**: aplicar escopo global do Eloquent em Community e nos modelos de negócio de nível de plataforma, filtrando automaticamente por `$request->tenantId`; `find()` também é restrito pelo escopo, prevenindo naturalmente consulta direta de registro único entre tenants
3. **Contexto explícito Tenant::for()**: tarefas agendadas/queues/importações não têm request HTTP, usar closure para especificar o tenant explicitamente; na ausência de contexto, **fail-closed** (recusar a consulta), não permitir liberação silenciosa sem filtro

### 3.3 Pontos-chave dos testes de proteção contra acesso indevido (matriz de aceitação)

| Caso de uso | Esperado |
|------|------|
| Administrador do tenant A lista community/building/fee_bill do tenant B | Retorna vazio ou apenas dados de A |
| Administrador do tenant A faz find/update/delete de registro único do tenant B (consulta direta por id) | 403 / dados vazios / recusa |
| Administrador da plataforma (tenant_id=0) opera entre tenants | Liberado (capacidade de nível de plataforma) |
| Proprietário do service opera entre condomínios (pagamento/reparo) | Recusado (validação de pertencimento do community) |
| Tarefa agendada/queue sem contexto de tenant especificado | Erro fail-closed em vez de consulta sem filtro |

## 4. Caminho evolutivo (migração em etapas)

| Etapa | Conteúdo | Aceitação |
|------|------|------|
| 1. Camada de dados | Criar tabela platform_tenant + adicionar colunas em community/admin_user + migração idempotente + inicializar tenant padrão e fazer backfill dos dados existentes | Todo community deve ter tenant vinculado, relatório de dados órfãos zerado |
| 2. Camada de execução | Middleware TenantContext + TenantScope + utilitário Tenant::for() + lista de liberação de rotas | Regressão de tenant único: os 133 testes completos passam |
| 3. Módulos piloto | Ativar isolamento primeiro nos quatro módulos: gestão de grupo → condomínio → proprietário → cobranças (faturas) | Matriz de teste de acesso indevido aprovada |
| 4. Expansão completa | Ativar por lotes (lote 1 núcleo → lote 2 auxiliar → módulos estendidos), módulo a módulo | Matriz de acesso indevido de todos os módulos aprovada |
| 5. Evolução | Avaliar separação de banco (solução B) quando dados de tenant único >5 milhões de linhas ou por requisito de conformidade; o modelo de dados de A não bloqueia | Revisão da solução de separação de banco |

Estratégia de migração de dados: todos os dados existentes são alocados no "tenant padrão" (criado pelo script de migração), sem excluir ou alterar dados de negócio; o script de migração é idempotente e pode ser reexecutado.

## 5. Lista de riscos

| Risco | Área afetada | Mitigação / rollback |
|------|--------|-------------|
| Grande volume de reforma nos caminhos de consulta de 58+17 controladores | Todos os endpoints de negócio | Escopo global cobre ~80% de listas/detalhes; raw query e importação em lote usam Tenant::for(); rollout em lotes |
| Escopo global prejudica consultas de nível de plataforma (consolidação entre regiões no dashboard) | Dashboard/relatórios | Endpoints de plataforma usam explicitamente Tenant::without() ou bypass com tenant_id=0 |
| Tarefas agendadas/queues sem contexto de request | Tarefas em segundo plano como cobrança de inadimplência/SLA/notificações | Tenant::for() explícito + fail-closed |
| Erro de backfill dos dados existentes | Todos os dados existentes | Script idempotente + validação de backfill + modo dry-run |
| Impacto de índice/desempenho | Tabelas de alta frequência (fee_bill/room/owner) | Índice conjunto (tenant_id, community_id); reexame do log de consultas lentas |
| Regressão dos 133 testes | Completo | Após a injeção do escopo, rodar regressão completa antes de ativar o piloto |
| Confusão de nomenclatura (erik_tenant inquilino vs. tenant SaaS) | Cognição de desenvolvimento | Nova tabela chamada platform_tenant, declaração explícita na documentação |
| **Plano de rollback** | — | O escopo global pode ser desligado com um interruptor de configuração (restaurando a semântica de tenant único); as colunas de dados são mantidas sem exclusão, sem alteração destrutiva |

## 6. Conclusão da revisão

**Recomendado fazer imediatamente**:
- Banco compartilhado + isolamento por linha tenant_id (solução A), criar tabela `erik_platform_tenant`, adicionar colunas em community/admin_user
- Middleware TenantContext + escopo global TenantScope + utilitário Tenant::for()
- Ordem do piloto: grupo → condomínio → proprietário → cobranças
- Dependência prévia: concluída — tabelas/colunas/backfill do multi-tenant já incorporados ao docs/install.sql (consolidado em 2026-08-16, entry único de criação de banco)

**Recomendado adiar**:
- Isolamento por banco separado (B): iniciar apenas quando tenant único >5 milhões de linhas ou por requisito de conformidade; o modelo de dados já reserva isso
- Solução híbrida (C): reavaliar apenas se o cliente exigir explicitamente isolamento forte em cenários como pagamento/reconhecimento facial

**Não recomendado**:
- Isolamento por schema (MySQL não tem semântica de schema independente, custo equivalente ao banco separado)
- Roteamento dinâmico de múltiplos bancos (sem benefício em implantação de máquina única)
- Schema/campos personalizados por tenant (YAGNI)
- Reutilizar/reformar a tabela de inquilinos erik_tenant como tenant SaaS (conflito semântico, quebra o negócio de inquilinos)
